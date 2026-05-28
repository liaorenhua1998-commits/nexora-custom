package setup

import (
	"os"
	"strings"
	"testing"
)

func TestDecideAdminBootstrap(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name       string
		totalUsers int64
		adminUsers int64
		should     bool
		reason     string
	}{
		{
			name:       "empty database should create admin",
			totalUsers: 0,
			adminUsers: 0,
			should:     true,
			reason:     adminBootstrapReasonEmptyDatabase,
		},
		{
			name:       "admin exists should skip",
			totalUsers: 10,
			adminUsers: 1,
			should:     false,
			reason:     adminBootstrapReasonAdminExists,
		},
		{
			name:       "users exist without admin should skip",
			totalUsers: 5,
			adminUsers: 0,
			should:     false,
			reason:     adminBootstrapReasonUsersExistWithoutAdmin,
		},
	}

	for _, tc := range tests {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			got := decideAdminBootstrap(tc.totalUsers, tc.adminUsers)
			if got.shouldCreate != tc.should {
				t.Fatalf("shouldCreate=%v, want %v", got.shouldCreate, tc.should)
			}
			if got.reason != tc.reason {
				t.Fatalf("reason=%q, want %q", got.reason, tc.reason)
			}
		})
	}
}

func TestSetupDefaultAdminConcurrency(t *testing.T) {
	t.Run("simple mode admin uses higher concurrency", func(t *testing.T) {
		t.Setenv("RUN_MODE", "simple")
		if got := setupDefaultAdminConcurrency(); got != simpleModeAdminConcurrency {
			t.Fatalf("setupDefaultAdminConcurrency()=%d, want %d", got, simpleModeAdminConcurrency)
		}
	})

	t.Run("standard mode keeps existing default", func(t *testing.T) {
		t.Setenv("RUN_MODE", "standard")
		if got := setupDefaultAdminConcurrency(); got != defaultUserConcurrency {
			t.Fatalf("setupDefaultAdminConcurrency()=%d, want %d", got, defaultUserConcurrency)
		}
	})
}

func TestWriteConfigFileKeepsDefaultUserConcurrency(t *testing.T) {
	t.Setenv("RUN_MODE", "simple")
	t.Setenv("DATA_DIR", t.TempDir())

	if err := writeConfigFile(&SetupConfig{}); err != nil {
		t.Fatalf("writeConfigFile() error = %v", err)
	}

	data, err := os.ReadFile(GetConfigFilePath())
	if err != nil {
		t.Fatalf("ReadFile() error = %v", err)
	}

	if !strings.Contains(string(data), "user_concurrency: 5") {
		t.Fatalf("config missing default user concurrency, got:\n%s", string(data))
	}
}

func TestValidateAutoSetupAdminConfig(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name      string
		mode      string
		password  string
		wantError string
		wantPass  string
	}{
		{
			name:      "release mode requires password",
			mode:      "release",
			password:  "",
			wantError: "ADMIN_PASSWORD is required",
		},
		{
			name:     "debug mode may auto generate password",
			mode:     "debug",
			password: "",
		},
		{
			name:      "password must satisfy strength check",
			mode:      "release",
			password:  "short",
			wantError: "invalid ADMIN_PASSWORD",
		},
		{
			name:     "password is trimmed",
			mode:     "release",
			password: "  long-enough-password  ",
			wantPass: "long-enough-password",
		},
	}

	for _, tc := range tests {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			cfg := &SetupConfig{
				Server: ServerConfig{Mode: tc.mode},
				Admin:  AdminConfig{Password: tc.password},
			}

			err := validateAutoSetupAdminConfig(cfg)
			if tc.wantError != "" {
				if err == nil || !strings.Contains(err.Error(), tc.wantError) {
					t.Fatalf("error=%v, want substring %q", err, tc.wantError)
				}
				return
			}
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if cfg.Admin.Password != tc.wantPass {
				t.Fatalf("password=%q, want %q", cfg.Admin.Password, tc.wantPass)
			}
		})
	}
}
