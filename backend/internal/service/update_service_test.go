package service

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
)

type updateCacheStub struct {
	data string
	err  error
}

func (s *updateCacheStub) GetUpdateInfo(context.Context) (string, error) {
	if s.err != nil {
		return "", s.err
	}
	if s.data == "" {
		return "", errors.New("missing")
	}
	return s.data, nil
}

func (s *updateCacheStub) SetUpdateInfo(_ context.Context, data string, _ time.Duration) error {
	s.data = data
	return nil
}

type githubReleaseClientStub struct {
	requestedRepo string
	release       *GitHubRelease
	err           error
}

func (s *githubReleaseClientStub) FetchLatestRelease(_ context.Context, repo string) (*GitHubRelease, error) {
	s.requestedRepo = repo
	if s.err != nil {
		return nil, s.err
	}
	return s.release, nil
}

func (s *githubReleaseClientStub) DownloadFile(context.Context, string, string, int64) error {
	return nil
}

func (s *githubReleaseClientStub) FetchChecksumFile(context.Context, string) ([]byte, error) {
	return nil, nil
}

func TestUpdateServiceUsesConfiguredRepository(t *testing.T) {
	client := &githubReleaseClientStub{
		release: &GitHubRelease{
			TagName: "v1.2.3",
			Name:    "Branded release",
			HTMLURL: "https://github.com/acme/branded-gateway/releases/tag/v1.2.3",
		},
	}
	svc := NewUpdateService(&updateCacheStub{}, client, "1.0.0", "release", "acme/branded-gateway")

	info, err := svc.CheckUpdate(context.Background(), true)

	require.NoError(t, err)
	require.Equal(t, "acme/branded-gateway", client.requestedRepo)
	require.Equal(t, "acme/branded-gateway", info.UpdateRepo)
	require.True(t, info.HasUpdate)
	require.Equal(t, "1.2.3", info.LatestVersion)
}

func TestUpdateServiceDefaultsToOfficialRepository(t *testing.T) {
	client := &githubReleaseClientStub{
		release: &GitHubRelease{
			TagName: "v1.0.0",
			Name:    "Official release",
			HTMLURL: "https://github.com/Wei-Shaw/sub2api/releases/tag/v1.0.0",
		},
	}
	svc := NewUpdateService(&updateCacheStub{}, client, "1.0.0", "release", "")

	info, err := svc.CheckUpdate(context.Background(), true)

	require.NoError(t, err)
	require.Equal(t, defaultGitHubRepo, client.requestedRepo)
	require.Equal(t, defaultGitHubRepo, info.UpdateRepo)
	require.False(t, info.HasUpdate)
}

func TestUpdateServiceIgnoresCacheFromDifferentRepository(t *testing.T) {
	cache := &updateCacheStub{
		data: `{"latest":"9.9.9","repo":"other/repo","timestamp":4102444800}`,
	}
	client := &githubReleaseClientStub{
		release: &GitHubRelease{
			TagName: "v1.2.0",
			Name:    "Branded release",
			HTMLURL: "https://github.com/acme/branded-gateway/releases/tag/v1.2.0",
		},
	}
	svc := NewUpdateService(cache, client, "1.0.0", "release", "acme/branded-gateway")

	info, err := svc.CheckUpdate(context.Background(), false)

	require.NoError(t, err)
	require.Equal(t, "acme/branded-gateway", client.requestedRepo)
	require.Equal(t, "1.2.0", info.LatestVersion)
	require.False(t, info.Cached)
}
