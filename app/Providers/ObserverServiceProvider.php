<?php

namespace Luxodactyl\Providers;

use Luxodactyl\Models\Egg;
use Luxodactyl\Models\User;
use Luxodactyl\Models\Server;
use Luxodactyl\Models\Subuser;
use Luxodactyl\Models\Allocation;
use Luxodactyl\Models\EggVariable;
use Luxodactyl\Models\SessionActivity;
use Luxodactyl\Observers\EggObserver;
use Luxodactyl\Observers\UserObserver;
use Luxodactyl\Observers\ServerObserver;
use Luxodactyl\Observers\SubuserObserver;
use Luxodactyl\Observers\AllocationObserver;
use Luxodactyl\Observers\EggVariableObserver;
use Luxodactyl\Observers\SessionActivityObserver;
use Illuminate\Support\ServiceProvider;

class ObserverServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        User::observe(UserObserver::class);
        Server::observe(ServerObserver::class);
        Subuser::observe(SubuserObserver::class);
        Allocation::observe(AllocationObserver::class);
        Egg::observe(EggObserver::class);
        EggVariable::observe(EggVariableObserver::class);
        SessionActivity::observe(SessionActivityObserver::class);
    }
}