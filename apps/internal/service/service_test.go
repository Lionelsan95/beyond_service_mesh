package service

import (
 "net/http"; "net/http/httptest"; "strings"; "testing"
)
func TestWorkerControlledFailure(t *testing.T) { a:=&app{name:"payment"}; r:=httptest.NewRequest(http.MethodPost,"/work",nil); r.Header.Set("X-BTM-Force-Fail","payment"); w:=httptest.NewRecorder(); a.work(w,r); if w.Code != http.StatusServiceUnavailable { t.Fatalf("got %d",w.Code) } }
func TestWorkerKeepsCorrelationID(t *testing.T) { a:=&app{name:"inventory"}; r:=httptest.NewRequest(http.MethodPost,"/work",nil); r.Header.Set("X-Correlation-ID","case-42"); w:=httptest.NewRecorder(); a.work(w,r); if w.Code != http.StatusOK || !strings.Contains(w.Body.String(),"case-42") { t.Fatalf("unexpected response: %s",w.Body.String()) } }
func TestBoundedDelay(t *testing.T) { if d, ok := boundedDelay("300"); !ok || d.Milliseconds()!=300 { t.Fatalf("unexpected valid delay: %v %v",d,ok) }; if _, ok := boundedDelay("5001"); ok { t.Fatal("out-of-range delay accepted") }; if _, ok := boundedDelay("invalid"); ok { t.Fatal("invalid delay accepted") } }
