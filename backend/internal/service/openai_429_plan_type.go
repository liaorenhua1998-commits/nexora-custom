package service

import (
	"context"
	"encoding/json"
	"strings"
)

func persistOpenAI429PlanType(ctx context.Context, repo AccountRepository, account *Account, body []byte) {
	if repo == nil || account == nil || len(body) == 0 {
		return
	}

	var payload map[string]any
	if err := json.Unmarshal(body, &payload); err != nil {
		return
	}

	planType := extractOpenAI429PlanType(payload)
	if planType == "" || account.GetCredential("plan_type") == planType {
		return
	}

	if account.Credentials == nil {
		account.Credentials = map[string]any{}
	}
	account.Credentials["plan_type"] = planType
	_ = repo.Update(ctx, account)
}

func extractOpenAI429PlanType(payload map[string]any) string {
	if payload == nil {
		return ""
	}

	if accountMap, ok := payload["account"].(map[string]any); ok {
		if planType := extractPlanType(accountMap); planType != "" {
			return planType
		}
	}

	for _, key := range []string{"plan_type", "subscription_plan"} {
		if planType, ok := payload[key].(string); ok {
			if trimmed := strings.TrimSpace(planType); trimmed != "" {
				return trimmed
			}
		}
	}

	if subMap, ok := payload["subscription"].(map[string]any); ok {
		if planType, ok := subMap["plan_type"].(string); ok {
			return strings.TrimSpace(planType)
		}
	}

	if errorMap, ok := payload["error"].(map[string]any); ok {
		if planType, ok := errorMap["plan_type"].(string); ok {
			return strings.TrimSpace(planType)
		}
	}

	return ""
}
