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
        self::$result = $this->cacheVersionData();
        self::$latestPanelVersion = $this->cacheLatestPanelVersion();
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
        if (config('app.version') === 'canary' || self::$latestPanelVersion === '') {
            // Either a development install (no pinned release) or we couldn't
            // reach GitHub -- don't nag the admin with a false "update available".
            return true;
        }

        return version_compare(ltrim(config('app.version'), 'v'), ltrim(self::$latestPanelVersion, 'v')) >= 0;
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
        return $this->cache->remember(self::VERSION_CACHE_KEY, CarbonImmutable::now()->addMinutes(config('pterodactyl.cdn.cache_time', 60)), function () {
            try {
                $response = $this->client->request('GET', config('pterodactyl.cdn.url'));

                if ($response->getStatusCode() === 200) {
                    return json_decode($response->getBody(), true);
                }

                throw new CdnVersionFetchingException();
            } catch (\Exception) {
                return [];
            }
        });
    }

    /**
     * Fetches the latest published release tag for this fork from GitHub. Returns
     * an empty string (rather than null) on failure so the result still gets
     * cached -- otherwise a GitHub outage would cause a fresh API call on every
     * single request.
     */
    protected function cacheLatestPanelVersion(): string
    {
        return $this->cache->remember(self::PANEL_RELEASE_CACHE_KEY, CarbonImmutable::now()->addMinutes(config('luxodactyl.updates.cache_time', 60)), function () {
            try {
                $response = $this->client->request('GET', 'https://api.github.com/repos/' . config('luxodactyl.updates.repo') . '/releases/latest', [
                    'headers' => ['Accept' => 'application/vnd.github+json'],
                ]);

                if ($response->getStatusCode() === 200) {
                    return json_decode($response->getBody(), true)['tag_name'] ?? '';
                }
            } catch (\Exception) {
                // Swallowed -- treated as "unknown" by isLatestPanel()/getPanel().
            }

            return '';
        });
    }
}
