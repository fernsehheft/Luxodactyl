<?php

namespace Luxodactyl\Http\Requests\Api\Client\Servers\Network;

use Luxodactyl\Models\Permission;
use Luxodactyl\Http\Requests\Api\Client\ClientApiRequest;

class NewAllocationRequest extends ClientApiRequest
{
    public function permission(): string
    {
        return Permission::ACTION_ALLOCATION_CREATE;
    }
}
