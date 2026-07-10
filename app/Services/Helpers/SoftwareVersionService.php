<?php

namespace Luxodactyl\Services\Helpers;

use GuzzleHttp\Client;
use Carbon\CarbonImmutable;
use Illuminate\Support\Arr;
use Illuminate\Contracts\Cache\Repository as CacheRepository;
use Luxodactyl\Exceptions\Service\Helper\CdnVersionFetchingException;

class SoftwareVersionService
{
    public const VERSION_CACHE_KEY = 'pterodactyl:versioning_data';
    public const PANEL_RELEASE_CACHE_KEY = 'luxodactyl:panel_release';

    private static array $result;
    private static string $latestPanelVersion;

    /**
     * SoftwareVersionService constructor.
     */
    public function __construct(
        protected CacheRepository $cache,
        protected Client $client,
    ) {
        // These feed an informational "update available?" banner -- if the cache
        // store or GitHub is having a bad day, the panel should still load.
        try {
            self::$result = $this->cacheVersionData();
        } catch (\Throwable) {
            self::$result = [];
        }

        try {
            self::$latestPanelVersion = $this->cacheLatestPanelVersion();
        } catch (\Throwable) {
            self::$latestPanelVersion = '';
        }
    }

    /**
     * Get the latest version of the panel from the Luxodactyl GitHub releases.
     */
    public function getPanel(): string
    {
        return self::$latestPanelVersion ?: 'error';
    }

    /**
     * Get the latest version of the daemon from the CDN servers.
     */
    public function getDaemon(): string
    {
        return Arr::get(self::$result, 'wings') ?? 'error';
    }

    /**
     * Get the URL to the discord server.
     */
    public function getDiscord(): string
    {
        return Arr::get(self::$result, 'discord') ?? 'https://discord.gg/mnTJVSSaKp';
    }

    /**
     * Get the URL for donations.
     */
    public function getDonations(): string
    {
        return Arr::get(self::$result, 'donations') ?? 'https://ko-fi.com/naterfute';
    }

    /**
     * Determine if the current version of the panel is the latest.
     */
    public function isLatestPanel(): bool
    {
        $current = (string) config('app.version', 'canary');

        if (
            $current === ''
            || $current === 'canary'
            || config('luxodactyl.updates.channel') === 'commit'
            || self::$latestPanelVersion === ''
        ) {
            // A development install, a pinned commit/branch/tag (nothing "latest"
            // to compare that against), or we couldn't reach GitHub -- don't nag
            // the admin with a false "update available".
            return true;
        }

        return version_compare(ltrim($current, 'v'), ltrim(self::$latestPanelVersion, 'v')) >= 0;
    }

    /**
     * Determine if a passed daemon version string is the latest.
     */
    public function isLatestDaemon(string $version): bool
    {
        if ($version === 'develop') {
            return true;
        }

        return version_compare($version, $this->getDaemon()) >= 0;
    }

    /**
     * Keeps the versioning cache up-to-date with the latest results from the CDN.
     */
    protected function cacheVersionData(): array
    {
        $data = $this->cache->remember(self::VERSION_CACHE_KEY, CarbonImmutable::now()->addMinutes(config('pterodactyl.cdn.cache_time', 60)), function () {
            try {
                $response = $this->client->request('GET', config('pterodactyl.cdn.url'));

                if ($response->getStatusCode() === 200) {
                    $decoded = json_decode($response->getBody(), true);

                    return is_array($decoded) ? $decoded : [];
                }

                throw new CdnVersionFetchingException();
            } catch (\Throwable) {
                return [];
            }
        });

        return is_array($data) ? $data : [];
    }

    /**
     * Fetches the latest published release tag for this fork from GitHub, for
     * whichever channel this install is configured to track. Returns an empty
     * string (rather than null) on failure so the result still gets cached --
     * otherwise a GitHub outage would cause a fresh API call on every request.
     */
    protected function cacheLatestPanelVersion(): string
    {
        $channel = config('luxodactyl.updates.channel', 'release');

        if ($channel === 'commit') {
            // Pinned to a specific commit/branch/tag rather than tracking a
            // release -- there's no "latest" to look up.
            return '';
        }

        $tag = $this->cache->remember(self::PANEL_RELEASE_CACHE_KEY . ":{$channel}", CarbonImmutable::now()->addMinutes(config('luxodactyl.updates.cache_time', 60)), function () use ($channel) {
            $repo = config('luxodactyl.updates.repo');

            try {
                if ($channel === 'beta') {
                    $response = $this->client->request('GET', "https://api.github.com/repos/{$repo}/releases", [
                        'headers' => ['Accept' => 'application/vnd.github+json'],
                    ]);

                    if ($response->getStatusCode() === 200) {
                        $releases = json_decode($response->getBody(), true);
                        foreach ((is_array($releases) ? $releases : []) as $release) {
                            if (is_array($release) && ($release['draft'] ?? false) === false && ($release['prerelease'] ?? false) === true) {
                                return $release['tag_name'] ?? '';
                            }
                        }
                    }

                    return '';
                }

                $response = $this->client->request('GET', "https://api.github.com/repos/{$repo}/releases/latest", [
                    'headers' => ['Accept' => 'application/vnd.github+json'],
                ]);

                if ($response->getStatusCode() === 200) {
                    $data = json_decode($response->getBody(), true);

                    return is_array($data) ? ($data['tag_name'] ?? '') : '';
                }
            } catch (\Throwable) {
                // Swallowed -- treated as "unknown" by isLatestPanel()/getPanel().
            }

            return '';
        });

        // Guard against a stale/corrupt cache entry from a previous version of
        // this method holding something other than a plain string.
        return is_string($tag) ? $tag : '';
    }
}
