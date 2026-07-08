<?php

namespace Luxodactyl\Contracts\Core;

use Luxodactyl\Events\Event;

interface ReceivesEvents
{
    /**
     * Handles receiving an event from the application.
     */
    public function handle(Event $notification): void;
}
