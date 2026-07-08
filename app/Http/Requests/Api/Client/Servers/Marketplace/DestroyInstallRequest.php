<?php

namespace Luxodactyl\Http\Requests\Api\Client\Servers\Marketplace;

use Luxodactyl\Contracts\Http\ClientPermissionsRequest;
use Luxodactyl\Http\Requests\Api\Client\ClientApiRequest;
use Luxodactyl\Models\Permission;

class DestroyInstallRequest extends ClientApiRequest implements ClientPermissionsRequest
{
    public function permission(): string
    {
        return Permission::ACTION_MOD_DOWNLOAD;
    }

    public function rules(): array
    {
        return [
            'type' => ['required', 'string', 'in:mod,plugin'],
            'source' => ['required', 'string', 'max:32'],
            'project_id' => ['required', 'string', 'max:128'],
        ];
    }
}
