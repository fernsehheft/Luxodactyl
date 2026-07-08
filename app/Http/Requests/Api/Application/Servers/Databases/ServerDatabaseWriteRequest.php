<?php

namespace Luxodactyl\Http\Requests\Api\Application\Servers\Databases;

use Luxodactyl\Services\Acl\Api\AdminAcl;

class ServerDatabaseWriteRequest extends GetServerDatabasesRequest
{
    protected int $permission = AdminAcl::WRITE;
}
