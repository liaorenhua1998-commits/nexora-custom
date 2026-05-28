package service

import (
	"fmt"
	"strings"

	"github.com/Wei-Shaw/sub2api/internal/util/urlvalidator"
)

// validateAccountCredentialShape performs backend-side shape validation for the
// credential fields that are required to route an account. Runtime connectivity
// checks still belong to AccountTestService.
func validateAccountCredentialShape(account *Account) error {
	if account == nil {
		return ErrAccountNilInput
	}

	switch account.Platform {
	case PlatformOpenAI:
		return validateOpenAICredentialShape(account)
	case PlatformAnthropic:
		return validateAnthropicCredentialShape(account)
	case PlatformGemini:
		return validateGeminiCredentialShape(account)
	case PlatformAntigravity:
		return validateAntigravityCredentialShape(account)
	default:
		return nil
	}
}

func validateOpenAICredentialShape(account *Account) error {
	switch account.Type {
	case AccountTypeAPIKey:
		if err := requireCredential(account, "api_key"); err != nil {
			return err
		}
		return validateOptionalBaseURL(account.GetOpenAIBaseURL())
	case AccountTypeOAuth, AccountTypeSetupToken:
		return requireCredential(account, "access_token")
	default:
		return nil
	}
}

func validateAnthropicCredentialShape(account *Account) error {
	switch account.Type {
	case AccountTypeAPIKey:
		if err := requireCredential(account, "api_key"); err != nil {
			return err
		}
		return validateOptionalBaseURL(account.GetBaseURL())
	case AccountTypeOAuth, AccountTypeSetupToken:
		return requireCredential(account, "access_token")
	case AccountTypeBedrock:
		if account.IsBedrockAPIKey() {
			return requireCredential(account, "api_key")
		}
		return nil
	default:
		return nil
	}
}

func validateGeminiCredentialShape(account *Account) error {
	switch account.Type {
	case AccountTypeAPIKey:
		if err := requireCredential(account, "api_key"); err != nil {
			return err
		}
		return validateOptionalBaseURL(account.GetCredential("base_url"))
	case AccountTypeOAuth:
		return requireCredential(account, "access_token")
	default:
		return nil
	}
}

func validateAntigravityCredentialShape(account *Account) error {
	switch account.Type {
	case AccountTypeAPIKey:
		if err := requireCredential(account, "api_key"); err != nil {
			return err
		}
		return validateOptionalBaseURL(account.GetCredential("base_url"))
	case AccountTypeOAuth, AccountTypeSetupToken:
		return requireCredential(account, "access_token")
	default:
		return nil
	}
}

func requireCredential(account *Account, key string) error {
	if strings.TrimSpace(account.GetCredential(key)) == "" {
		return fmt.Errorf("%s credential %q is required for %s account", account.Platform, key, account.Type)
	}
	return nil
}

func validateOptionalBaseURL(raw string) error {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return nil
	}
	if _, err := urlvalidator.ValidateURLFormat(trimmed, true); err != nil {
		return fmt.Errorf("invalid base_url: %w", err)
	}
	return nil
}
