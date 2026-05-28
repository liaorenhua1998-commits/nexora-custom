package service

import (
	"context"
	"fmt"
	"os"
	"strconv"
	"strings"
)

const (
	bootstrapRegistrationClosed     = "closed"
	bootstrapRegistrationInviteOnly = "invite_only"
	bootstrapRegistrationOpen       = "open"
)

func envLookupTrimmed(key string) (string, bool) {
	value, ok := os.LookupEnv(key)
	if !ok {
		return "", false
	}
	return strings.TrimSpace(value), true
}

func envBoolWithDefault(key string, fallback bool) (bool, error) {
	value, ok := envLookupTrimmed(key)
	if !ok {
		return fallback, nil
	}
	return parseEnvBool(value)
}

func parseEnvBool(raw string) (bool, error) {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "1", "true", "yes", "on":
		return true, nil
	case "0", "false", "no", "off":
		return false, nil
	default:
		return false, fmt.Errorf("invalid boolean value %q", raw)
	}
}

func (s *SettingService) ApplyProductionBootstrapFromEnv(ctx context.Context) error {
	if s == nil || s.settingRepo == nil {
		return nil
	}
	enabled, err := envBoolWithDefault("BOOTSTRAP_SETTINGS_ENABLED", false)
	if err != nil {
		return fmt.Errorf("parse BOOTSTRAP_SETTINGS_ENABLED: %w", err)
	}
	if !enabled {
		return nil
	}
	enforce, err := envBoolWithDefault("BOOTSTRAP_SETTINGS_ENFORCE", false)
	if err != nil {
		return fmt.Errorf("parse BOOTSTRAP_SETTINGS_ENFORCE: %w", err)
	}

	desired := map[string]string{}

	if rawMode, ok := envLookupTrimmed("BOOTSTRAP_REGISTRATION_MODE"); ok {
		switch strings.ToLower(rawMode) {
		case bootstrapRegistrationClosed:
			desired[SettingKeyRegistrationEnabled] = "false"
			desired[SettingKeyInvitationCodeEnabled] = "false"
		case bootstrapRegistrationInviteOnly:
			desired[SettingKeyRegistrationEnabled] = "true"
			desired[SettingKeyInvitationCodeEnabled] = "true"
		case bootstrapRegistrationOpen:
			desired[SettingKeyRegistrationEnabled] = "true"
			desired[SettingKeyInvitationCodeEnabled] = "false"
		default:
			return fmt.Errorf("invalid BOOTSTRAP_REGISTRATION_MODE %q", rawMode)
		}
	}

	boolMappings := []struct {
		envKey     string
		settingKey string
	}{
		{"BOOTSTRAP_EMAIL_VERIFY_ENABLED", SettingKeyEmailVerifyEnabled},
		{"BOOTSTRAP_PASSWORD_RESET_ENABLED", SettingKeyPasswordResetEnabled},
		{"BOOTSTRAP_PROMO_CODE_ENABLED", SettingKeyPromoCodeEnabled},
		{"BOOTSTRAP_INVITATION_CODE_ENABLED", SettingKeyInvitationCodeEnabled},
		{"BOOTSTRAP_RISK_CONTROL_ENABLED", SettingKeyRiskControlEnabled},
		{"BOOTSTRAP_TOTP_ENABLED", SettingKeyTotpEnabled},
	}
	for _, mapping := range boolMappings {
		raw, ok := envLookupTrimmed(mapping.envKey)
		if !ok {
			continue
		}
		value, err := parseEnvBool(raw)
		if err != nil {
			return fmt.Errorf("parse %s: %w", mapping.envKey, err)
		}
		desired[mapping.settingKey] = strconv.FormatBool(value)
	}

	stringMappings := []struct {
		envKey     string
		settingKey string
	}{
		{"BOOTSTRAP_FRONTEND_URL", SettingKeyFrontendURL},
		{"BOOTSTRAP_API_BASE_URL", SettingKeyAPIBaseURL},
		{"BOOTSTRAP_CONTACT_INFO", SettingKeyContactInfo},
		{"BOOTSTRAP_DOC_URL", SettingKeyDocURL},
		{"BOOTSTRAP_SMTP_HOST", SettingKeySMTPHost},
		{"BOOTSTRAP_SMTP_USERNAME", SettingKeySMTPUsername},
		{"BOOTSTRAP_SMTP_FROM_EMAIL", SettingKeySMTPFrom},
		{"BOOTSTRAP_SMTP_FROM_NAME", SettingKeySMTPFromName},
	}
	for _, mapping := range stringMappings {
		if raw, ok := envLookupTrimmed(mapping.envKey); ok {
			desired[mapping.settingKey] = raw
		}
	}

	if rawPort, ok := envLookupTrimmed("BOOTSTRAP_SMTP_PORT"); ok {
		port, err := strconv.Atoi(rawPort)
		if err != nil || port <= 0 {
			return fmt.Errorf("invalid BOOTSTRAP_SMTP_PORT %q", rawPort)
		}
		desired[SettingKeySMTPPort] = strconv.Itoa(port)
	}
	if rawUseTLS, ok := envLookupTrimmed("BOOTSTRAP_SMTP_USE_TLS"); ok {
		value, err := parseEnvBool(rawUseTLS)
		if err != nil {
			return fmt.Errorf("parse BOOTSTRAP_SMTP_USE_TLS: %w", err)
		}
		desired[SettingKeySMTPUseTLS] = strconv.FormatBool(value)
	}
	if rawPassword, ok := envLookupTrimmed("BOOTSTRAP_SMTP_PASSWORD"); ok {
		desired[SettingKeySMTPPassword] = rawPassword
	}

	if rawEnabled, ok := envLookupTrimmed("BOOTSTRAP_TURNSTILE_ENABLED"); ok {
		turnstileEnabled, err := parseEnvBool(rawEnabled)
		if err != nil {
			return fmt.Errorf("parse BOOTSTRAP_TURNSTILE_ENABLED: %w", err)
		}
		desired[SettingKeyTurnstileEnabled] = strconv.FormatBool(turnstileEnabled)

		siteKey, hasSiteKey := envLookupTrimmed("BOOTSTRAP_TURNSTILE_SITE_KEY")
		secretKey, hasSecretKey := envLookupTrimmed("BOOTSTRAP_TURNSTILE_SECRET_KEY")
		if turnstileEnabled && (!hasSiteKey || siteKey == "" || !hasSecretKey || secretKey == "") {
			return fmt.Errorf("turnstile enabled but BOOTSTRAP_TURNSTILE_SITE_KEY / BOOTSTRAP_TURNSTILE_SECRET_KEY not fully configured")
		}
		if hasSiteKey {
			desired[SettingKeyTurnstileSiteKey] = siteKey
		}
		if hasSecretKey {
			desired[SettingKeyTurnstileSecretKey] = secretKey
		}
	}

	if len(desired) == 0 {
		return nil
	}
	if !enforce {
		existing, err := s.settingRepo.GetAll(ctx)
		if err != nil {
			return fmt.Errorf("load settings before bootstrap merge: %w", err)
		}
		for key := range desired {
			if _, ok := existing[key]; ok {
				delete(desired, key)
			}
		}
		if len(desired) == 0 {
			return nil
		}
	}

	if err := s.settingRepo.SetMultiple(ctx, desired); err != nil {
		return fmt.Errorf("apply production bootstrap settings: %w", err)
	}
	if s.onUpdate != nil {
		s.onUpdate()
	}
	return nil
}
