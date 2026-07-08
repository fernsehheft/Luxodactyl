<?php

namespace Luxodactyl\Http\Requests\Api\Client\Servers\Marketplace;

use Luxodactyl\Contracts\Http\ClientPermissionsRequest;
use Luxodactyl\Http\Requests\Api\Client\ClientApiRequest;
use Luxodactyl\Models\Permission;

class ListInstallsRequest extends ClientApiRequest implements ClientPermissionsRequest
{
    public function permission(): string
    {
        return Permission::ACTION_MOD_DOWNLOAD;
    }

    public function rules(): array
    {
        return [];
    }
}
