package server

import (
	"context"
	"database/sql"
	"time"

	"github.com/Wei-Shaw/sub2api/internal/server/routes"
	"github.com/redis/go-redis/v9"
)

const readinessProbeTimeout = 2 * time.Second

type readinessChecker struct {
	db      *sql.DB
	redis   *redis.Client
	timeout time.Duration
}

// NewReadinessChecker builds a dependency-based readiness probe for production use.
func NewReadinessChecker(db *sql.DB, redisClient *redis.Client) routes.ReadinessChecker {
	return &readinessChecker{
		db:      db,
		redis:   redisClient,
		timeout: readinessProbeTimeout,
	}
}

func (c *readinessChecker) Check(ctx context.Context) routes.ReadinessCheckResult {
	result := routes.ReadinessCheckResult{
		Status: routes.ReadinessStatusOK,
		Checks: map[string]string{
			"database": routes.DependencyStatusOK,
			"redis":    routes.DependencyStatusOK,
		},
	}

	if c.db == nil {
		result.Status = routes.ReadinessStatusError
		result.Checks["database"] = routes.DependencyStatusUnavailable
	}
	if c.redis == nil {
		result.Status = routes.ReadinessStatusError
		result.Checks["redis"] = routes.DependencyStatusUnavailable
	}

	if c.db != nil {
		if err := c.pingDB(ctx); err != nil {
			result.Status = routes.ReadinessStatusError
			result.Checks["database"] = routes.DependencyStatusError
		}
	}
	if c.redis != nil {
		if err := c.pingRedis(ctx); err != nil {
			result.Status = routes.ReadinessStatusError
			result.Checks["redis"] = routes.DependencyStatusError
		}
	}

	if result.Status != routes.ReadinessStatusOK {
		result.Error = "dependency check failed"
	}

	return result
}

func (c *readinessChecker) pingDB(ctx context.Context) error {
	timeoutCtx, cancel := context.WithTimeout(ctx, c.timeout)
	defer cancel()
	return c.db.PingContext(timeoutCtx)
}

func (c *readinessChecker) pingRedis(ctx context.Context) error {
	timeoutCtx, cancel := context.WithTimeout(ctx, c.timeout)
	defer cancel()
	return c.redis.Ping(timeoutCtx).Err()
}
