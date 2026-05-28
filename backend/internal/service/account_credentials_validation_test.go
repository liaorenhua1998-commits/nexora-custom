//go:build unit

package service

import (
	"context"
	"testing"

	"github.com/stretchr/testify/require"
)

type adminValidationAccountRepo struct {
	mockAccountRepoForGemini
	existing *Account
	created  *Account
	updated  *Account
}

func (r *adminValidationAccountRepo) Create(_ context.Context, account *Account) error {
	r.created = account
	return nil
}

func (r *adminValidationAccountRepo) Update(_ context.Context, account *Account) error {
	r.updated = account
	return nil
}

func (r *adminValidationAccountRepo) GetByID(_ context.Context, _ int64) (*Account, error) {
	if r.existing != nil {
		return r.existing, nil
	}
	return nil, nil
}

func TestValidateAccountCredentialShape_OpenAIAPIKeyRequiresAPIKey(t *testing.T) {
	err := validateAccountCredentialShape(&Account{
		Platform:    PlatformOpenAI,
		Type:        AccountTypeAPIKey,
		Credentials: map[string]any{"base_url": "https://example.com"},
	})
	require.ErrorContains(t, err, `credential "api_key" is required`)
}

func TestValidateAccountCredentialShape_OpenAIAPIKeyRejectsInvalidBaseURL(t *testing.T) {
	err := validateAccountCredentialShape(&Account{
		Platform:    PlatformOpenAI,
		Type:        AccountTypeAPIKey,
		Credentials: map[string]any{"api_key": "sk-test", "base_url": "://bad"},
	})
	require.ErrorContains(t, err, "invalid base_url")
}

func TestAdminService_CreateAccountRejectsInvalidCredentials(t *testing.T) {
	repo := &adminValidationAccountRepo{}
	svc := &adminServiceImpl{
		accountRepo: repo,
		groupRepo:   &mockGroupRepoForGemini{},
	}

	account, err := svc.CreateAccount(context.Background(), &CreateAccountInput{
		Name:                 "broken-openai",
		Platform:             PlatformOpenAI,
		Type:                 AccountTypeAPIKey,
		Credentials:          map[string]any{"base_url": "https://example.com"},
		SkipDefaultGroupBind: true,
	})

	require.Nil(t, account)
	require.ErrorContains(t, err, `credential "api_key" is required`)
	require.Nil(t, repo.created)
}

func TestAdminService_UpdateAccountRejectsInvalidCredentialsWhenTouched(t *testing.T) {
	repo := &adminValidationAccountRepo{
		existing: &Account{
			ID:       7,
			Platform: PlatformOpenAI,
			Type:     AccountTypeAPIKey,
			Credentials: map[string]any{
				"api_key":  "sk-live",
				"base_url": "https://example.com",
			},
		},
	}
	svc := &adminServiceImpl{
		accountRepo: repo,
		groupRepo:   &mockGroupRepoForGemini{},
	}

	account, err := svc.UpdateAccount(context.Background(), 7, &UpdateAccountInput{
		Credentials: map[string]any{
			"api_key":  "sk-live",
			"base_url": "://bad",
		},
	})

	require.Nil(t, account)
	require.ErrorContains(t, err, "invalid base_url")
	require.Nil(t, repo.updated)
}
