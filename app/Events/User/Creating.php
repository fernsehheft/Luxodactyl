<?php

namespace Luxodactyl\Events\User;

use Luxodactyl\Models\User;
use Luxodactyl\Events\Event;
use Illuminate\Queue\SerializesModels;

class Creating extends Event
{
    use SerializesModels;

    /**
     * Create a new event instance.
     */
    public function __construct(public User $user)
    {
    }
}
