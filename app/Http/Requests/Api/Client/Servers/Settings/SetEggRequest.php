<?php

namespace Luxodactyl\Http\Requests\Api\Client\Servers\Settings;

use Webmozart\Assert\Assert;
use Luxodactyl\Models\Server;
use Illuminate\Validation\Rule;
use Luxodactyl\Models\Permission;
use Luxodactyl\Contracts\Http\ClientPermissionsRequest;
use Luxodactyl\Http\Requests\Api\Client\ClientApiRequest;

class SetEggRequest extends ClientApiRequest implements ClientPermissionsRequest
{
    public function permission(): string
    {
        return Permission::ACTION_STARTUP_SOFTWARE;
    }

    public function rules(): array
    {
        /** @var \Luxodactyl\Models\Server $server */
        $server = $this->route()->parameter('server');

        Assert::isInstanceOf($server, Server::class);

        return [
            'egg_id' => ['required', 'numeric'],
            'nest_id' => ['required', 'numeric'],
        ];
    }
}
