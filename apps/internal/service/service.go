package service

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"strings"
	"time"
)

type dependencyResult struct { Name string `json:"name"`; Status int `json:"status"`; DurationMS int64 `json:"duration_ms"` }
type app struct { name string; client *http.Client; base map[string]string; logger *slog.Logger }

func Run(name string) {
	a := &app{name: name, client: &http.Client{Timeout: 2 * time.Second}, base: map[string]string{
		"inventory": env("INVENTORY_URL", "http://inventory-service.btm-lab.svc.cluster.local:8080"),
		"payment": env("PAYMENT_URL", "http://payment-service.btm-lab.svc.cluster.local:8080"),
		"notification": env("NOTIFICATION_URL", "http://notification-service.btm-lab.svc.cluster.local:8080"),
	}, logger: slog.New(slog.NewJSONHandler(os.Stdout, nil))}
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) { write(w, http.StatusOK, map[string]string{"status":"ok"}) })
	mux.HandleFunc("GET /readyz", func(w http.ResponseWriter, r *http.Request) { write(w, http.StatusOK, map[string]string{"status":"ready"}) })
	if name == "order" { mux.HandleFunc("POST /orders", a.order) } else { mux.HandleFunc("POST /work", a.work) }
	a.logger.Info("service started", "service", name, "port", 8080)
	if err := http.ListenAndServe(":8080", logging(a.logger, name, mux)); err != nil { a.logger.Error("server stopped", "error", err); os.Exit(1) }
}

func (a *app) work(w http.ResponseWriter, r *http.Request) {
	cid := correlation(r)
	if a.name == "payment" {
		if delay, ok := boundedDelay(r.Header.Get("X-BTM-Payment-Delay-MS")); ok { time.Sleep(delay) }
	}
	if r.Header.Get("X-BTM-Force-Fail") == a.name { write(w, http.StatusServiceUnavailable, map[string]string{"error":"controlled dependency failure","service":a.name,"correlation_id":cid}); return }
	write(w, http.StatusOK, map[string]string{"status":"accepted", "service":a.name, "correlation_id":cid})
}

func (a *app) order(w http.ResponseWriter, r *http.Request) {
	cid := correlation(r); forced := r.URL.Query().Get("fail")
	deps := make([]dependencyResult, 0, 3)
	for _, name := range []string{"inventory", "payment", "notification"} {
		result, err := a.call(r.Context(), name, cid, forced, r.URL.Query().Get("payment_delay_ms"))
		deps = append(deps, result)
		if err != nil { write(w, http.StatusBadGateway, map[string]any{"status":"rejected", "correlation_id":cid, "failed_dependency":name, "dependencies":deps}); return }
	}
	write(w, http.StatusCreated, map[string]any{"status":"accepted", "order_id":"demo-order-001", "correlation_id":cid, "dependencies":deps})
}

func (a *app) call(ctx context.Context, name, cid, forced, paymentDelay string) (dependencyResult, error) {
	start := time.Now(); req, err := http.NewRequestWithContext(ctx, http.MethodPost, a.base[name]+"/work", nil)
	if err != nil { return dependencyResult{Name:name}, err }
	req.Header.Set("X-Correlation-ID", cid); req.Header.Set("X-BTM-Force-Fail", forced)
	if name == "payment" { req.Header.Set("X-BTM-Payment-Delay-MS", paymentDelay) }
	resp, err := a.client.Do(req); duration := time.Since(start).Milliseconds()
	if err != nil { return dependencyResult{Name:name, DurationMS:duration}, err }
	defer resp.Body.Close()
	r := dependencyResult{Name:name, Status:resp.StatusCode, DurationMS:duration}
	if resp.StatusCode < 200 || resp.StatusCode > 299 { return r, fmt.Errorf("%s returned %d", name, resp.StatusCode) }
	return r, nil
}

type statusWriter struct { http.ResponseWriter; status int }
func (w *statusWriter) WriteHeader(status int) { w.status = status; w.ResponseWriter.WriteHeader(status) }
func (w *statusWriter) Write(b []byte) (int, error) { if w.status == 0 { w.status = http.StatusOK }; return w.ResponseWriter.Write(b) }
func logging(logger *slog.Logger, service string, next http.Handler) http.Handler { return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { start:=time.Now(); sw:=&statusWriter{ResponseWriter:w}; next.ServeHTTP(sw,r); if sw.status==0 { sw.status=http.StatusOK }; logger.Info("request", "service",service,"method",r.Method,"path",r.URL.Path,"correlation_id",correlation(r),"http_status",sw.status,"duration_ms",time.Since(start).Milliseconds()) }) }
func correlation(r *http.Request) string { if id:=strings.TrimSpace(r.Header.Get("X-Correlation-ID")); id!="" { return id }; return "btm-local-0001" }
func env(k,d string) string { if v:=os.Getenv(k);v!="" { return v }; return d }
func boundedDelay(raw string) (time.Duration, bool) { if raw=="" { return 0, false }; var ms int; if _,err:=fmt.Sscanf(raw,"%d",&ms); err!=nil || ms<0 || ms>5000 { return 0,false }; return time.Duration(ms)*time.Millisecond,true }
func write(w http.ResponseWriter, status int, payload any) { w.Header().Set("Content-Type","application/json"); w.WriteHeader(status); _=json.NewEncoder(w).Encode(payload) }
