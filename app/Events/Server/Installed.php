<?php

namespace Luxodactyl\Events\Server;

use Luxodactyl\Events\Event;
use Luxodactyl\Models\Server;
use Illuminate\Queue\SerializesModels;

class Installed extends Event
{
    use SerializesModels;

    /**
     * Create a new event instance.
     */
    public function __construct(public Server $server)
    {
    }
}
