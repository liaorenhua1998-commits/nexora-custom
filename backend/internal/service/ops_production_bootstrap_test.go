package service

import (
	"context"
	"testing"
)

type opsBootstrapRepoStub struct {
	opsRepoMock
	rules   []*OpsAlertRule
	created []*OpsAlertRule
	updated []*OpsAlertRule
}

func (s *opsBootstrapRepoStub) ListAlertRules(ctx context.Context) ([]*OpsAlertRule, error) {
	if s.rules == nil {
		return []*OpsAlertRule{}, nil
	}
	return s.rules, nil
}

func (s *opsBootstrapRepoStub) CreateAlertRule(ctx context.Context, input *OpsAlertRule) (*OpsAlertRule, error) {
	cloned := *input
	cloned.ID = int64(len(s.created) + 1)
	s.created = append(s.created, &cloned)
	return &cloned, nil
}

func (s *opsBootstrapRepoStub) UpdateAlertRule(ctx context.Context, input *OpsAlertRule) (*OpsAlertRule, error) {
	cloned := *input
	s.updated = append(s.updated, &cloned)
	return &cloned, nil
}

func TestOpsServiceApplyProductionBootstrapFromEnv(t *testing.T) {
	t.Setenv("BOOTSTRAP_OPS_SETTINGS_ENABLED", "true")
	t.Setenv("BOOTSTRAP_OPS_ALERT_EMAIL_ENABLED", "true")
	t.Setenv("BOOTSTRAP_OPS_ALERT_EMAIL_RECIPIENTS", "ops1@example.com, ops2@example.com")
	t.Setenv("BOOTSTRAP_OPS_ALERT_EMAIL_RATE_LIMIT_PER_HOUR", "24")
	t.Setenv("BOOTSTRAP_OPS_ALERT_EMAIL_BATCHING_WINDOW_SECONDS", "120")
	t.Setenv("BOOTSTRAP_OPS_ALERT_INCLUDE_RESOLVED", "true")
	t.Setenv("BOOTSTRAP_OPS_ALERT_RULES_ENABLED", "true")
	t.Setenv("BOOTSTRAP_OPS_ALERT_RULES_ENFORCE", "true")
	t.Setenv("BOOTSTRAP_OPS_ERROR_RATE_THRESHOLD", "7")
	t.Setenv("BOOTSTRAP_OPS_UPSTREAM_ERROR_RATE_THRESHOLD", "9")
	t.Setenv("BOOTSTRAP_OPS_SUCCESS_RATE_THRESHOLD", "98.5")
	t.Setenv("BOOTSTRAP_OPS_SLA_PERCENT_MIN", "99.9")
	t.Setenv("BOOTSTRAP_OPS_TTFT_P99_MS_MAX", "650")

	settings := &productionSettingRepoStub{values: map[string]string{
		SettingKeySMTPHost: "smtp.example.com",
	}}
	opsRepo := &opsBootstrapRepoStub{}
	svc := &OpsService{
		opsRepo:     opsRepo,
		settingRepo: settings,
	}

	if err := svc.ApplyProductionBootstrapFromEnv(context.Background()); err != nil {
		t.Fatalf("ApplyProductionBootstrapFromEnv() error = %v", err)
	}

	if len(opsRepo.created) != 3 {
		t.Fatalf("created rules = %d, want 3", len(opsRepo.created))
	}
	emailCfg, err := svc.GetEmailNotificationConfig(context.Background())
	if err != nil {
		t.Fatalf("GetEmailNotificationConfig() error = %v", err)
	}
	if !emailCfg.Alert.Enabled {
		t.Fatal("expected alert email enabled")
	}
	if got := len(emailCfg.Alert.Recipients); got != 2 {
		t.Fatalf("recipient count = %d, want 2", got)
	}
	thresholds, err := svc.GetMetricThresholds(context.Background())
	if err != nil {
		t.Fatalf("GetMetricThresholds() error = %v", err)
	}
	if thresholds.SLAPercentMin == nil || *thresholds.SLAPercentMin != 99.9 {
		t.Fatalf("sla threshold = %v, want 99.9", thresholds.SLAPercentMin)
	}
	if thresholds.TTFTp99MsMax == nil || *thresholds.TTFTp99MsMax != 650 {
		t.Fatalf("ttft threshold = %v, want 650", thresholds.TTFTp99MsMax)
	}
}
