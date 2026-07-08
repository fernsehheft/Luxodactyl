<?php

namespace Luxodactyl\Providers;

use Illuminate\Support\ServiceProvider;
use Luxodactyl\Services\Captcha\CaptchaManager;
use Luxodactyl\Contracts\Repository\SettingsRepositoryInterface;

class CaptchaServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     */
    public function register(): void
    {
        $this->app->singleton(CaptchaManager::class, function ($app) {
            return new CaptchaManager($app, $app->make(SettingsRepositoryInterface::class));
        });

        $this->app->alias(CaptchaManager::class, 'captcha');
    }

    /**
     * Bootstrap services.
     */
    public function boot(): void
    {
        //
    }
}