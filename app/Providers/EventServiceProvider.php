<?php

namespace Luxodactyl\Providers;

use Luxodactyl\Models\User;
use Luxodactyl\Models\Subuser;
use Luxodactyl\Models\EggVariable;
use Luxodactyl\Observers\UserObserver;
use Luxodactyl\Observers\SubuserObserver;
use Luxodactyl\Observers\EggVariableObserver;
use Luxodactyl\Listeners\Auth\AuthenticationListener;
use Luxodactyl\Events\Server\Installed as ServerInstalledEvent;
use Luxodactyl\Notifications\ServerInstalled as ServerInstalledNotification;
use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;

class EventServiceProvider extends ServiceProvider
{
    /**
     * The event to listener mappings for the application.
     */
    protected $listen = [
        ServerInstalledEvent::class => [ServerInstalledNotification::class],
    ];

    protected $subscribe = [
        AuthenticationListener::class,
    ];

    /**
     * Register any events for your application.
     */
    public function boot(): void
    {
        parent::boot();

        User::observe(UserObserver::class);
        Subuser::observe(SubuserObserver::class);
        EggVariable::observe(EggVariableObserver::class);
    }
}
