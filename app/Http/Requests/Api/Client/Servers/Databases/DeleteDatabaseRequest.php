<?php

namespace Luxodactyl\Http\Requests\Api\Client\Servers\Databases;

use Luxodactyl\Models\Permission;
use Luxodactyl\Contracts\Http\ClientPermissionsRequest;
use Luxodactyl\Http\Requests\Api\Client\ClientApiRequest;

class DeleteDatabaseRequest extends ClientApiRequest implements ClientPermissionsRequest
{
    public function permission(): string
    {
        return Permission::ACTION_DATABASE_DELETE;
    }
}
