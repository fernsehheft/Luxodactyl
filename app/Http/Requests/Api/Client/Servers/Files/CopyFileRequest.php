<?php

namespace Luxodactyl\Http\Requests\Api\Client\Servers\Files;

use Luxodactyl\Models\Permission;
use Luxodactyl\Contracts\Http\ClientPermissionsRequest;
use Luxodactyl\Http\Requests\Api\Client\ClientApiRequest;

class CopyFileRequest extends ClientApiRequest implements ClientPermissionsRequest
{
    public function permission(): string
    {
        return Permission::ACTION_FILE_CREATE;
    }

    public function rules(): array
    {
        return [
            'location' => 'required|string',
        ];
    }
}
