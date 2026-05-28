package routes

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

type fakeReadinessChecker struct {
	result ReadinessCheckResult
}

func (f fakeReadinessChecker) Check(context.Context) ReadinessCheckResult {
	return f.result
}

func TestRegisterCommonRoutes_Livez(t *testing.T) {
	gin.SetMode(gin.TestMode)

	router := gin.New()
	RegisterCommonRoutes(router, nil)

	w := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/livez", nil)
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("status=%d, want %d", w.Code, http.StatusOK)
	}
}

func TestRegisterCommonRoutes_ReadinessHealthy(t *testing.T) {
	gin.SetMode(gin.TestMode)

	router := gin.New()
	RegisterCommonRoutes(router, fakeReadinessChecker{
		result: ReadinessCheckResult{
			Status: ReadinessStatusOK,
			Checks: map[string]string{
				"database": DependencyStatusOK,
				"redis":    DependencyStatusOK,
			},
		},
	})

	for _, path := range []string{"/health", "/readyz"} {
		w := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodGet, path, nil)
		router.ServeHTTP(w, req)
		if w.Code != http.StatusOK {
			t.Fatalf("%s status=%d, want %d", path, w.Code, http.StatusOK)
		}
	}
}

func TestRegisterCommonRoutes_ReadinessUnhealthy(t *testing.T) {
	gin.SetMode(gin.TestMode)

	router := gin.New()
	RegisterCommonRoutes(router, fakeReadinessChecker{
		result: ReadinessCheckResult{
			Status: ReadinessStatusError,
			Checks: map[string]string{
				"database": DependencyStatusOK,
				"redis":    DependencyStatusError,
			},
			Error: "dependency check failed",
		},
	})

	w := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/readyz", nil)
	router.ServeHTTP(w, req)

	if w.Code != http.StatusServiceUnavailable {
		t.Fatalf("status=%d, want %d", w.Code, http.StatusServiceUnavailable)
	}
}
