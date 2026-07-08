<?php

namespace Luxodactyl\Http\Requests\Api\Application\Users;

use Luxodactyl\Services\Acl\Api\AdminAcl as Acl;
use Luxodactyl\Http\Requests\Api\Application\ApplicationApiRequest;

class GetUsersRequest extends ApplicationApiRequest
{
    protected ?string $resource = Acl::RESOURCE_USERS;

    protected int $permission = Acl::READ;
}
