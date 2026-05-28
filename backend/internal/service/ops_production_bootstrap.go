package service

import (
	"context"
	"fmt"
	"strconv"
	"strings"
)

func (s *OpsService) ApplyProductionBootstrapFromEnv(ctx context.Context) error {
	if s == nil {
		return nil
	}
	enabled, err := envBoolWithDefault("BOOTSTRAP_OPS_SETTINGS_ENABLED", false)
	if err != nil {
		return fmt.Errorf("parse BOOTSTRAP_OPS_SETTINGS_ENABLED: %w", err)
	}
	if !enabled {
		return nil
	}
	if err := s.applyProductionOpsEmailConfig(ctx); err != nil {
		return err
	}
	if err := s.applyProductionMetricThresholds(ctx); err != nil {
		return err
	}
	if err := s.applyProductionAlertRules(ctx); err != nil {
		return err
	}
	return nil
}

func (s *OpsService) applyProductionOpsEmailConfig(ctx context.Context) error {
	cfg, err := s.GetEmailNotificationConfig(ctx)
	if err != nil {
		return fmt.Errorf("load ops email notification config: %w", err)
	}

	if raw, ok := envLookupTrimmed("BOOTSTRAP_OPS_ALERT_EMAIL_ENABLED"); ok {
		value, err := parseEnvBool(raw)
		if err != nil {
			return fmt.Errorf("parse BOOTSTRAP_OPS_ALERT_EMAIL_ENABLED: %w", err)
		}
		cfg.Alert.Enabled = value
	}
	if raw, ok := envLookupTrimmed("BOOTSTRAP_OPS_ALERT_EMAIL_RECIPIENTS"); ok {
		cfg.Alert.Recipients = splitCommaSeparated(raw)
	}
	if raw, ok := envLookupTrimmed("BOOTSTRAP_OPS_ALERT_EMAIL_RATE_LIMIT_PER_HOUR"); ok {
		value, err := strconv.Atoi(raw)
		if err != nil || value < 0 {
			return fmt.Errorf("invalid BOOTSTRAP_OPS_ALERT_EMAIL_RATE_LIMIT_PER_HOUR %q", raw)
		}
		cfg.Alert.RateLimitPerHour = value
	}
	if raw, ok := envLookupTrimmed("BOOTSTRAP_OPS_ALERT_EMAIL_BATCHING_WINDOW_SECONDS"); ok {
		value, err := strconv.Atoi(raw)
		if err != nil || value < 0 {
			return fmt.Errorf("invalid BOOTSTRAP_OPS_ALERT_EMAIL_BATCHING_WINDOW_SECONDS %q", raw)
		}
		cfg.Alert.BatchingWindowSeconds = value
	}
	if raw, ok := envLookupTrimmed("BOOTSTRAP_OPS_ALERT_INCLUDE_RESOLVED"); ok {
		value, err := parseEnvBool(raw)
		if err != nil {
			return fmt.Errorf("parse BOOTSTRAP_OPS_ALERT_INCLUDE_RESOLVED: %w", err)
		}
		cfg.Alert.IncludeResolvedAlerts = value
	}
	if cfg.Alert.Enabled && len(cfg.Alert.Recipients) == 0 {
		return fmt.Errorf("ops alert email enabled but BOOTSTRAP_OPS_ALERT_EMAIL_RECIPIENTS is empty")
	}
	if cfg.Alert.Enabled {
		smtpHost, err := s.settingRepo.GetValue(ctx, SettingKeySMTPHost)
		if err != nil && err != ErrSettingNotFound {
			return fmt.Errorf("load smtp host for alert email bootstrap: %w", err)
		}
		if strings.TrimSpace(smtpHost) == "" {
			return fmt.Errorf("ops alert email enabled but SMTP is not configured")
		}
	}

	_, err = s.UpdateEmailNotificationConfig(ctx, &OpsEmailNotificationConfigUpdateRequest{
		Alert: &cfg.Alert,
	})
	if err != nil {
		return fmt.Errorf("persist ops email notification config: %w", err)
	}
	return nil
}

func (s *OpsService) applyProductionMetricThresholds(ctx context.Context) error {
	cfg, err := s.GetMetricThresholds(ctx)
	if err != nil {
		return fmt.Errorf("load metric thresholds: %w", err)
	}

	floatMappings := []struct {
		envKey string
		target **float64
	}{
		{"BOOTSTRAP_OPS_SLA_PERCENT_MIN", &cfg.SLAPercentMin},
		{"BOOTSTRAP_OPS_TTFT_P99_MS_MAX", &cfg.TTFTp99MsMax},
		{"BOOTSTRAP_OPS_ERROR_RATE_THRESHOLD", &cfg.RequestErrorRatePercentMax},
		{"BOOTSTRAP_OPS_UPSTREAM_ERROR_RATE_THRESHOLD", &cfg.UpstreamErrorRatePercentMax},
	}
	for _, mapping := range floatMappings {
		raw, ok := envLookupTrimmed(mapping.envKey)
		if !ok {
			continue
		}
		value, err := strconv.ParseFloat(raw, 64)
		if err != nil {
			return fmt.Errorf("invalid %s %q", mapping.envKey, raw)
		}
		v := value
		*mapping.target = &v
	}

	if _, err := s.UpdateMetricThresholds(ctx, cfg); err != nil {
		return fmt.Errorf("persist metric thresholds: %w", err)
	}
	return nil
}

func (s *OpsService) applyProductionAlertRules(ctx context.Context) error {
	enabled, err := envBoolWithDefault("BOOTSTRAP_OPS_ALERT_RULES_ENABLED", false)
	if err != nil {
		return fmt.Errorf("parse BOOTSTRAP_OPS_ALERT_RULES_ENABLED: %w", err)
	}
	if !enabled {
		return nil
	}
	enforce, err := envBoolWithDefault("BOOTSTRAP_OPS_ALERT_RULES_ENFORCE", false)
	if err != nil {
		return fmt.Errorf("parse BOOTSTRAP_OPS_ALERT_RULES_ENFORCE: %w", err)
	}

	notifyEmail := false
	if raw, ok := envLookupTrimmed("BOOTSTRAP_OPS_ALERT_EMAIL_ENABLED"); ok {
		value, err := parseEnvBool(raw)
		if err != nil {
			return fmt.Errorf("parse BOOTSTRAP_OPS_ALERT_EMAIL_ENABLED: %w", err)
		}
		notifyEmail = value
	}

	errorRateThreshold := 5.0
	if raw, ok := envLookupTrimmed("BOOTSTRAP_OPS_ERROR_RATE_THRESHOLD"); ok && raw != "" {
		value, err := strconv.ParseFloat(raw, 64)
		if err != nil {
			return fmt.Errorf("invalid BOOTSTRAP_OPS_ERROR_RATE_THRESHOLD %q", raw)
		}
		errorRateThreshold = value
	}
	upstreamErrorRateThreshold := 5.0
	if raw, ok := envLookupTrimmed("BOOTSTRAP_OPS_UPSTREAM_ERROR_RATE_THRESHOLD"); ok && raw != "" {
		value, err := strconv.ParseFloat(raw, 64)
		if err != nil {
			return fmt.Errorf("invalid BOOTSTRAP_OPS_UPSTREAM_ERROR_RATE_THRESHOLD %q", raw)
		}
		upstreamErrorRateThreshold = value
	}
	successRateThreshold := 99.0
	if raw, ok := envLookupTrimmed("BOOTSTRAP_OPS_SUCCESS_RATE_THRESHOLD"); ok && raw != "" {
		value, err := strconv.ParseFloat(raw, 64)
		if err != nil {
			return fmt.Errorf("invalid BOOTSTRAP_OPS_SUCCESS_RATE_THRESHOLD %q", raw)
		}
		successRateThreshold = value
	}

	desired := []*OpsAlertRule{
		{
			Name:             "managed:error-rate",
			Description:      "Managed production bootstrap rule for elevated request error rate.",
			Enabled:          true,
			Severity:         "P1",
			MetricType:       "error_rate",
			Operator:         ">=",
			Threshold:        errorRateThreshold,
			WindowMinutes:    5,
			SustainedMinutes: 5,
			CooldownMinutes:  15,
			NotifyEmail:      notifyEmail,
		},
		{
			Name:             "managed:upstream-error-rate",
			Description:      "Managed production bootstrap rule for elevated upstream error rate.",
			Enabled:          true,
			Severity:         "P1",
			MetricType:       "upstream_error_rate",
			Operator:         ">=",
			Threshold:        upstreamErrorRateThreshold,
			WindowMinutes:    5,
			SustainedMinutes: 5,
			CooldownMinutes:  15,
			NotifyEmail:      notifyEmail,
		},
		{
			Name:             "managed:success-rate",
			Description:      "Managed production bootstrap rule for low success rate.",
			Enabled:          true,
			Severity:         "P2",
			MetricType:       "success_rate",
			Operator:         "<",
			Threshold:        successRateThreshold,
			WindowMinutes:    10,
			SustainedMinutes: 5,
			CooldownMinutes:  30,
			NotifyEmail:      notifyEmail,
		},
	}

	existingRules, err := s.ListAlertRules(ctx)
	if err != nil {
		return fmt.Errorf("list existing alert rules: %w", err)
	}
	existingByName := make(map[string]*OpsAlertRule, len(existingRules))
	for _, rule := range existingRules {
		if rule == nil {
			continue
		}
		existingByName[rule.Name] = rule
	}

	for _, rule := range desired {
		existing := existingByName[rule.Name]
		if existing == nil {
			if _, err := s.CreateAlertRule(ctx, rule); err != nil {
				return fmt.Errorf("create alert rule %s: %w", rule.Name, err)
			}
			continue
		}
		if !enforce {
			continue
		}
		updated := *rule
		updated.ID = existing.ID
		updated.CreatedAt = existing.CreatedAt
		updated.LastTriggeredAt = existing.LastTriggeredAt
		if _, err := s.UpdateAlertRule(ctx, &updated); err != nil {
			return fmt.Errorf("update alert rule %s: %w", rule.Name, err)
		}
	}
	return nil
}

func splitCommaSeparated(raw string) []string {
	if strings.TrimSpace(raw) == "" {
		return []string{}
	}
	parts := strings.Split(raw, ",")
	out := make([]string, 0, len(parts))
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}
		out = append(out, part)
	}
	return out
}
