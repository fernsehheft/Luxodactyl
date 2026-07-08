<?php

namespace Luxodactyl\Providers;

use Illuminate\Support\ServiceProvider;
use Luxodactyl\Services\Activity\ActivityLogBatchService;
use Luxodactyl\Services\Activity\ActivityLogTargetableService;

class ActivityLogServiceProvider extends ServiceProvider
{
    /**
     * Registers the necessary activity logger singletons scoped to the individual
     * request instances.
     */
    public function register()
    {
        $this->app->scoped(ActivityLogBatchService::class);
        $this->app->scoped(ActivityLogTargetableService::class);
    }
}
