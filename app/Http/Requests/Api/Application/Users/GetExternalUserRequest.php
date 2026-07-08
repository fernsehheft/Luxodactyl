<?php

namespace Luxodactyl\Http\Requests\Api\Application\Users;

use Luxodactyl\Services\Acl\Api\AdminAcl;
use Luxodactyl\Http\Requests\Api\Application\ApplicationApiRequest;

class GetExternalUserRequest extends ApplicationApiRequest
{
    protected ?string $resource = AdminAcl::RESOURCE_USERS;

    protected int $permission = AdminAcl::READ;
}
