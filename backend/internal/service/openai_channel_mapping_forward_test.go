package service

import (
	"bytes"
	"context"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/Wei-Shaw/sub2api/internal/config"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/require"
	"github.com/tidwall/gjson"
)

type openAIChannelMappingTestChannelRepo struct {
	ChannelRepository
	groupID int64
	mapping map[string]string
}

func (r *openAIChannelMappingTestChannelRepo) ListAll(ctx context.Context) ([]Channel, error) {
	return []Channel{{
		ID:           1,
		Name:         "openai-test-channel",
		Status:       StatusActive,
		GroupIDs:     []int64{r.groupID},
		ModelMapping: map[string]map[string]string{PlatformOpenAI: r.mapping},
	}}, nil
}

func (r *openAIChannelMappingTestChannelRepo) GetGroupPlatforms(ctx context.Context, groupIDs []int64) (map[int64]string, error) {
	return map[int64]string{r.groupID: PlatformOpenAI}, nil
}

func newOpenAIChannelMappingTestService(groupID int64, mapping map[string]string, upstream *httpUpstreamRecorder) *OpenAIGatewayService {
	channelSvc := NewChannelService(&openAIChannelMappingTestChannelRepo{
		groupID: groupID,
		mapping: mapping,
	}, nil, nil, nil)

	return &OpenAIGatewayService{
		cfg:            &config.Config{},
		httpUpstream:   upstream,
		channelService: channelSvc,
	}
}

func bindOpenAIChannelMappingTestAPIKey(c *gin.Context, groupID int64) {
	c.Set("api_key", &APIKey{
		ID:      1,
		GroupID: &groupID,
		Group:   &Group{ID: groupID},
		User:    &User{ID: 1, Status: StatusActive},
	})
}

func TestOpenAIGatewayService_Forward_PassthroughAppliesChannelMappingBeforeAccountMapping(t *testing.T) {
	gin.SetMode(gin.TestMode)

	rec := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(rec)
	body := []byte(`{"model":"alias-model","stream":false,"instructions":"local-test-instructions","input":[{"type":"text","text":"hi"}]}`)
	c.Request = httptest.NewRequest(http.MethodPost, "/v1/responses", bytes.NewReader(body))
	c.Request.Header.Set("Content-Type", "application/json")
	c.Request.Header.Set("User-Agent", "codex_cli_rs/0.1.0")

	groupID := int64(101)
	bindOpenAIChannelMappingTestAPIKey(c, groupID)

	upstream := &httpUpstreamRecorder{resp: &http.Response{
		StatusCode: http.StatusBadRequest,
		Header:     http.Header{"Content-Type": []string{"application/json"}, "x-request-id": []string{"rid_channel_passthrough"}},
		Body:       io.NopCloser(strings.NewReader(`{"error":{"type":"invalid_request_error","message":"stop after rewrite"}}`)),
	}}
	svc := newOpenAIChannelMappingTestService(groupID, map[string]string{"alias-model": "gpt-5.4"}, upstream)
	account := &Account{
		ID:          11,
		Name:        "openai-oauth-pass",
		Platform:    PlatformOpenAI,
		Type:        AccountTypeOAuth,
		Concurrency: 1,
		Credentials: map[string]any{
			"access_token":       "oauth-token",
			"chatgpt_account_id": "chatgpt-acc",
			"model_mapping":      map[string]any{"gpt-5.4": "gpt-5.4-mini"},
		},
		Extra:       map[string]any{"openai_passthrough": true},
		Status:      StatusActive,
		Schedulable: true,
	}

	result, err := svc.Forward(context.Background(), c, account, body)
	require.Error(t, err)
	require.Nil(t, result)
	require.Equal(t, "gpt-5.4-mini", gjson.GetBytes(upstream.lastBody, "model").String())
}

func TestOpenAIGatewayService_ForwardAsChatCompletions_RawPathAppliesChannelMappingBeforeAccountMapping(t *testing.T) {
	gin.SetMode(gin.TestMode)

	rec := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(rec)
	body := []byte(`{"model":"alias-chat-model","messages":[{"role":"user","content":"hello"}],"stream":false}`)
	c.Request = httptest.NewRequest(http.MethodPost, "/v1/chat/completions", bytes.NewReader(body))
	c.Request.Header.Set("Content-Type", "application/json")

	groupID := int64(102)
	bindOpenAIChannelMappingTestAPIKey(c, groupID)

	upstream := &httpUpstreamRecorder{resp: &http.Response{
		StatusCode: http.StatusBadRequest,
		Header:     http.Header{"Content-Type": []string{"application/json"}, "x-request-id": []string{"rid_channel_chat_raw"}},
		Body:       io.NopCloser(strings.NewReader(`{"error":{"type":"invalid_request_error","message":"stop after rewrite"}}`)),
	}}
	svc := newOpenAIChannelMappingTestService(groupID, map[string]string{"alias-chat-model": "gpt-5.4"}, upstream)
	account := &Account{
		ID:          12,
		Name:        "openai-apikey-raw",
		Platform:    PlatformOpenAI,
		Type:        AccountTypeAPIKey,
		Concurrency: 1,
		Credentials: map[string]any{
			"api_key":       "sk-test",
			"base_url":      "https://api.openai.example",
			"model_mapping": map[string]any{"gpt-5.4": "gpt-5.4-mini"},
		},
		Status:      StatusActive,
		Schedulable: true,
	}

	result, err := svc.ForwardAsChatCompletions(context.Background(), c, account, body, "", "")
	require.Error(t, err)
	require.Nil(t, result)
	require.Equal(t, "gpt-5.4-mini", gjson.GetBytes(upstream.lastBody, "model").String())
}

func TestOpenAIGatewayService_ForwardAsAnthropic_AppliesChannelMappingBeforeAccountMapping(t *testing.T) {
	gin.SetMode(gin.TestMode)

	rec := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(rec)
	body := []byte(`{"model":"alias-messages-model","max_tokens":32,"messages":[{"role":"user","content":"hello"}],"stream":false}`)
	c.Request = httptest.NewRequest(http.MethodPost, "/v1/messages", bytes.NewReader(body))
	c.Request.Header.Set("Content-Type", "application/json")

	groupID := int64(103)
	bindOpenAIChannelMappingTestAPIKey(c, groupID)

	upstream := &httpUpstreamRecorder{resp: &http.Response{
		StatusCode: http.StatusBadRequest,
		Header:     http.Header{"Content-Type": []string{"application/json"}, "x-request-id": []string{"rid_channel_messages"}},
		Body:       io.NopCloser(strings.NewReader(`{"error":{"type":"invalid_request_error","message":"stop after rewrite"}}`)),
	}}
	svc := newOpenAIChannelMappingTestService(groupID, map[string]string{"alias-messages-model": "gpt-5.4"}, upstream)
	account := &Account{
		ID:          13,
		Name:        "openai-oauth-messages",
		Platform:    PlatformOpenAI,
		Type:        AccountTypeOAuth,
		Concurrency: 1,
		Credentials: map[string]any{
			"access_token":       "oauth-token",
			"chatgpt_account_id": "chatgpt-acc",
			"model_mapping":      map[string]any{"gpt-5.4": "gpt-5.4-mini"},
		},
		Status:      StatusActive,
		Schedulable: true,
	}

	result, err := svc.ForwardAsAnthropic(context.Background(), c, account, body, "", "")
	require.Error(t, err)
	require.Nil(t, result)
	require.Equal(t, "gpt-5.4-mini", gjson.GetBytes(upstream.lastBody, "model").String())
}
