package service

import (
	"context"
	"testing"
)

type productionSettingRepoStub struct {
	values map[string]string
}

func (s *productionSettingRepoStub) Get(ctx context.Context, key string) (*Setting, error) {
	value, ok := s.values[key]
	if !ok {
		return nil, ErrSettingNotFound
	}
	return &Setting{Key: key, Value: value}, nil
}

func (s *productionSettingRepoStub) GetValue(ctx context.Context, key string) (string, error) {
	value, ok := s.values[key]
	if !ok {
		return "", ErrSettingNotFound
	}
	return value, nil
}

func (s *productionSettingRepoStub) Set(ctx context.Context, key, value string) error {
	if s.values == nil {
		s.values = map[string]string{}
	}
	s.values[key] = value
	return nil
}

func (s *productionSettingRepoStub) GetMultiple(ctx context.Context, keys []string) (map[string]string, error) {
	out := make(map[string]string, len(keys))
	for _, key := range keys {
		if value, ok := s.values[key]; ok {
			out[key] = value
		}
	}
	return out, nil
}

func (s *productionSettingRepoStub) SetMultiple(ctx context.Context, settings map[string]string) error {
	if s.values == nil {
		s.values = map[string]string{}
	}
	for key, value := range settings {
		s.values[key] = value
	}
	return nil
}

func (s *productionSettingRepoStub) GetAll(ctx context.Context) (map[string]string, error) {
	out := make(map[string]string, len(s.values))
	for key, value := range s.values {
		out[key] = value
	}
	return out, nil
}

func (s *productionSettingRepoStub) Delete(ctx context.Context, key string) error {
	delete(s.values, key)
	return nil
}

func TestSettingServiceApplyProductionBootstrapFromEnv(t *testing.T) {
	t.Setenv("BOOTSTRAP_SETTINGS_ENABLED", "true")
	t.Setenv("BOOTSTRAP_SETTINGS_ENFORCE", "true")
	t.Setenv("BOOTSTRAP_REGISTRATION_MODE", "invite_only")
	t.Setenv("BOOTSTRAP_RISK_CONTROL_ENABLED", "true")
	t.Setenv("BOOTSTRAP_TOTP_ENABLED", "true")
	t.Setenv("BOOTSTRAP_FRONTEND_URL", "https://api.example.com")
	t.Setenv("BOOTSTRAP_API_BASE_URL", "https://api.example.com")
	t.Setenv("BOOTSTRAP_SMTP_HOST", "smtp.example.com")
	t.Setenv("BOOTSTRAP_SMTP_PORT", "587")
	t.Setenv("BOOTSTRAP_SMTP_USERNAME", "alerts")
	t.Setenv("BOOTSTRAP_SMTP_PASSWORD", "smtp-secret")
	t.Setenv("BOOTSTRAP_SMTP_FROM_EMAIL", "alerts@example.com")
	t.Setenv("BOOTSTRAP_SMTP_FROM_NAME", "Nexora Alerts")
	t.Setenv("BOOTSTRAP_SMTP_USE_TLS", "true")
	t.Setenv("BOOTSTRAP_TURNSTILE_ENABLED", "true")
	t.Setenv("BOOTSTRAP_TURNSTILE_SITE_KEY", "site-key")
	t.Setenv("BOOTSTRAP_TURNSTILE_SECRET_KEY", "secret-key")

	repo := &productionSettingRepoStub{values: map[string]string{}}
	svc := NewSettingService(repo, nil)

	if err := svc.ApplyProductionBootstrapFromEnv(context.Background()); err != nil {
		t.Fatalf("ApplyProductionBootstrapFromEnv() error = %v", err)
	}

	checks := map[string]string{
		SettingKeyRegistrationEnabled:   "true",
		SettingKeyInvitationCodeEnabled: "true",
		SettingKeyRiskControlEnabled:    "true",
		SettingKeyTotpEnabled:           "true",
		SettingKeyFrontendURL:           "https://api.example.com",
		SettingKeyAPIBaseURL:            "https://api.example.com",
		SettingKeySMTPHost:              "smtp.example.com",
		SettingKeySMTPPort:              "587",
		SettingKeySMTPUsername:          "alerts",
		SettingKeySMTPPassword:          "smtp-secret",
		SettingKeySMTPFrom:              "alerts@example.com",
		SettingKeySMTPFromName:          "Nexora Alerts",
		SettingKeySMTPUseTLS:            "true",
		SettingKeyTurnstileEnabled:      "true",
		SettingKeyTurnstileSiteKey:      "site-key",
		SettingKeyTurnstileSecretKey:    "secret-key",
	}
	for key, want := range checks {
		if got := repo.values[key]; got != want {
			t.Fatalf("%s = %q, want %q", key, got, want)
		}
	}
}

func TestSettingServiceApplyProductionBootstrapFromEnvRejectsMissingTurnstileSecret(t *testing.T) {
	t.Setenv("BOOTSTRAP_SETTINGS_ENABLED", "true")
	t.Setenv("BOOTSTRAP_TURNSTILE_ENABLED", "true")
	t.Setenv("BOOTSTRAP_TURNSTILE_SITE_KEY", "site-key")

	svc := NewSettingService(&productionSettingRepoStub{values: map[string]string{}}, nil)
	if err := svc.ApplyProductionBootstrapFromEnv(context.Background()); err == nil {
		t.Fatal("expected turnstile bootstrap error")
	}
}
