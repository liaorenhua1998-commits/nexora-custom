package routes

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
)

const (
	ReadinessStatusOK           = "ok"
	ReadinessStatusError        = "error"
	DependencyStatusOK          = "ok"
	DependencyStatusError       = "error"
	DependencyStatusUnavailable = "unavailable"
)

// ReadinessCheckResult describes dependency readiness without exposing internals.
type ReadinessCheckResult struct {
	Status string            `json:"status"`
	Checks map[string]string `json:"checks,omitempty"`
	Error  string            `json:"error,omitempty"`
}

// ReadinessChecker verifies whether the service can accept traffic.
type ReadinessChecker interface {
	Check(ctx context.Context) ReadinessCheckResult
}

// RegisterCommonRoutes 注册通用路由（健康检查、状态等）
func RegisterCommonRoutes(r *gin.Engine, readinessChecker ReadinessChecker) {
	// Liveness probe only checks that the process can answer HTTP.
	r.GET("/livez", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": ReadinessStatusOK})
	})

	readinessHandler := func(c *gin.Context) {
		if readinessChecker == nil {
			c.JSON(http.StatusServiceUnavailable, ReadinessCheckResult{
				Status: ReadinessStatusError,
				Error:  "readiness checker is not configured",
			})
			return
		}

		result := readinessChecker.Check(c.Request.Context())
		statusCode := http.StatusOK
		if result.Status != ReadinessStatusOK {
			statusCode = http.StatusServiceUnavailable
		}
		c.JSON(statusCode, result)
	}

	// Keep /health as a readiness alias because existing deploy targets already probe it.
	r.GET("/health", readinessHandler)
	r.GET("/readyz", readinessHandler)

	// Claude Code 遥测日志（忽略，直接返回200）
	r.POST("/api/event_logging/batch", func(c *gin.Context) {
		c.Status(http.StatusOK)
	})

	// Setup status endpoint (always returns needs_setup: false in normal mode)
	// This is used by the frontend to detect when the service has restarted after setup
	r.GET("/setup/status", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"code": 0,
			"data": gin.H{
				"needs_setup": false,
				"step":        "completed",
			},
		})
	})
}
