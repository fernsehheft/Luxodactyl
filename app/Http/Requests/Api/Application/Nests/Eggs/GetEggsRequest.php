<?php

namespace Luxodactyl\Http\Requests\Api\Application\Nests\Eggs;

use Luxodactyl\Services\Acl\Api\AdminAcl;
use Luxodactyl\Http\Requests\Api\Application\ApplicationApiRequest;

class GetEggsRequest extends ApplicationApiRequest
{
    protected ?string $resource = AdminAcl::RESOURCE_EGGS;

    protected int $permission = AdminAcl::READ;
}
