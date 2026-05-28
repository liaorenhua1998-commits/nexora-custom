package provider

import (
	"context"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"

	"github.com/Wei-Shaw/sub2api/internal/payment"
)

func TestEasyPayCreateAPIPaymentUsesChannelIDAndURLScheme(t *testing.T) {
	t.Parallel()

	var gotPath string
	var gotForm url.Values
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotPath = r.URL.Path
		if err := r.ParseForm(); err != nil {
			t.Errorf("ParseForm: %v", err)
		}
		gotForm = r.PostForm
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"code":1,"msg":"ok","trade_no":"trade-001","urlscheme":"weixin://dl/business/?ticket=abc123"}`))
	}))
	defer server.Close()

	provider, err := NewEasyPay("test-instance", map[string]string{
		"pid":            "pid-1",
		"pkey":           "pkey-1",
		"apiBase":        server.URL,
		"notifyUrl":      "https://merchant.example.com/notify",
		"returnUrl":      "https://merchant.example.com/return",
		"channelIdWxpay": "88",
	})
	if err != nil {
		t.Fatalf("NewEasyPay: %v", err)
	}

	resp, err := provider.CreatePayment(context.Background(), payment.CreatePaymentRequest{
		OrderID:     "out-123",
		Amount:      "10.00",
		PaymentType: payment.TypeWxpay,
		Subject:     "Test Product",
		ClientIP:    "127.0.0.1",
		IsMobile:    true,
	})
	if err != nil {
		t.Fatalf("CreatePayment returned error: %v", err)
	}
	if resp == nil {
		t.Fatal("CreatePayment response is nil")
	}
	if gotPath != "/mapi.php" {
		t.Fatalf("create payment path = %q, want /mapi.php", gotPath)
	}
	if got := gotForm.Get("channel_id"); got != "88" {
		t.Fatalf("form[channel_id] = %q, want %q (form=%v)", got, "88", gotForm)
	}
	if got := gotForm.Get("cid"); got != "" {
		t.Fatalf("form[cid] = %q, want empty (form=%v)", got, gotForm)
	}
	if got := resp.PayURL; got != "weixin://dl/business/?ticket=abc123" {
		t.Fatalf("PayURL = %q, want urlscheme fallback", got)
	}
	if got := resp.TradeNo; got != "trade-001" {
		t.Fatalf("TradeNo = %q, want %q", got, "trade-001")
	}
}

func TestEasyPayCreateRedirectPaymentUsesChannelID(t *testing.T) {
	t.Parallel()

	provider, err := NewEasyPay("test-instance", map[string]string{
		"pid":         "pid-1",
		"pkey":        "pkey-1",
		"apiBase":     "https://pay.example.com/xpay/epay/mapi.php",
		"notifyUrl":   "https://merchant.example.com/notify",
		"returnUrl":   "https://merchant.example.com/return",
		"cidAlipay":   "9",
		"paymentMode": paymentModePopup,
	})
	if err != nil {
		t.Fatalf("NewEasyPay: %v", err)
	}

	resp, err := provider.CreatePayment(context.Background(), payment.CreatePaymentRequest{
		OrderID:     "out-redirect-1",
		Amount:      "20.00",
		PaymentType: payment.TypeAlipay,
		Subject:     "Test Product",
	})
	if err != nil {
		t.Fatalf("CreatePayment returned error: %v", err)
	}
	if resp == nil {
		t.Fatal("CreatePayment response is nil")
	}

	u, err := url.Parse(resp.PayURL)
	if err != nil {
		t.Fatalf("Parse redirect url: %v", err)
	}
	if got := u.Path; got != "/xpay/epay/submit.php" {
		t.Fatalf("redirect path = %q, want /xpay/epay/submit.php", got)
	}
	if got := u.Query().Get("channel_id"); got != "9" {
		t.Fatalf("query[channel_id] = %q, want %q", got, "9")
	}
	if got := u.Query().Get("cid"); got != "" {
		t.Fatalf("query[cid] = %q, want empty", got)
	}
}

func TestEasyPayQueryOrderReturnsErrorWhenCodeIsNotSuccess(t *testing.T) {
	t.Parallel()

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"code":0,"msg":"order not found"}`))
	}))
	defer server.Close()

	provider := newTestEasyPay(t, server.URL)
	_, err := provider.QueryOrder(context.Background(), "out-missing")
	if err == nil {
		t.Fatal("QueryOrder returned nil error")
	}
	if got, want := err.Error(), "easypay query error: order not found"; got != want {
		t.Fatalf("QueryOrder error = %q, want %q", got, want)
	}
}
