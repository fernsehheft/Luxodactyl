<?php

namespace Luxodactyl\Events\Auth;

use Luxodactyl\Models\User;
use Luxodactyl\Events\Event;

class DirectLogin extends Event
{
    public function __construct(public User $user, public bool $remember)
    {
    }
}
