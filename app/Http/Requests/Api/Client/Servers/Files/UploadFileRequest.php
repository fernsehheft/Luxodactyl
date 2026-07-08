<?php

namespace Luxodactyl\Http\Requests\Api\Client\Servers\Files;

use Luxodactyl\Models\Permission;
use Luxodactyl\Http\Requests\Api\Client\ClientApiRequest;

class UploadFileRequest extends ClientApiRequest
{
    public function permission(): string
    {
        return Permission::ACTION_FILE_CREATE;
    }
}
