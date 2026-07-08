<?php

namespace Luxodactyl\Http\Requests\Api\Client\Servers\Startup;

use Luxodactyl\Models\Permission;
use Luxodactyl\Http\Requests\Api\Client\ClientApiRequest;

class GetStartupRequest extends ClientApiRequest
{
    public function permission(): string
    {
        return Permission::ACTION_STARTUP_READ;
    }
}
