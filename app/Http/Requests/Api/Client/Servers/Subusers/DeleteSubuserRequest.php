<?php

namespace Luxodactyl\Http\Requests\Api\Client\Servers\Subusers;

use Luxodactyl\Models\Permission;

class DeleteSubuserRequest extends SubuserRequest
{
    public function permission(): string
    {
        return Permission::ACTION_USER_DELETE;
    }
}
