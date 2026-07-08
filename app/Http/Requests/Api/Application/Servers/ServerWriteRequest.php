<?php

namespace Luxodactyl\Http\Requests\Api\Application\Servers;

use Luxodactyl\Services\Acl\Api\AdminAcl;
use Luxodactyl\Http\Requests\Api\Application\ApplicationApiRequest;

class ServerWriteRequest extends ApplicationApiRequest
{
    protected ?string $resource = AdminAcl::RESOURCE_SERVERS;

    protected int $permission = AdminAcl::WRITE;
}
