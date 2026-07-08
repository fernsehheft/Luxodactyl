<?php

namespace Luxodactyl\Http\Requests\Api\Application\Nodes;

use Luxodactyl\Services\Acl\Api\AdminAcl;
use Luxodactyl\Http\Requests\Api\Application\ApplicationApiRequest;

class GetNodesRequest extends ApplicationApiRequest
{
    protected ?string $resource = AdminAcl::RESOURCE_NODES;

    protected int $permission = AdminAcl::READ;
}
