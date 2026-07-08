<?php

namespace Luxodactyl\Events\Subuser;

use Luxodactyl\Events\Event;
use Luxodactyl\Models\Subuser;
use Illuminate\Queue\SerializesModels;

class Created extends Event
{
    use SerializesModels;

    /**
     * Create a new event instance.
     */
    public function __construct(public Subuser $subuser)
    {
    }
}
