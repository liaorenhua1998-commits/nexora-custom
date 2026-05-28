//go:build unit

package service

import (
	"net/smtp"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestSMTPAuthForConfig(t *testing.T) {
	t.Run("returns nil when smtp credentials are empty", func(t *testing.T) {
		require.Nil(t, smtpAuthForConfig(&SMTPConfig{Host: "127.0.0.1", Port: 1025}))
	})

	t.Run("returns auth when smtp credentials are provided", func(t *testing.T) {
		auth := smtpAuthForConfig(&SMTPConfig{
			Host:     "127.0.0.1",
			Port:     1025,
			Username: "noreply",
			Password: "secret",
		})
		require.NotNil(t, auth)
		_, ok := auth.(smtp.Auth)
		require.True(t, ok)
	})
}
