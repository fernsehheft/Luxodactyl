<?php

namespace Luxodactyl\Http\Controllers\Api\Client;

use Illuminate\Support\Facades\Log;
use Luxodactyl\Models\Server;
use Luxodactyl\Transformers\Api\Client\ServerTransformer;
use Luxodactyl\Services\Servers\GetUserPermissionsService;
use Luxodactyl\Http\Controllers\Api\Client\ClientApiController;
use Luxodactyl\Http\Requests\Api\Client\Servers\GetServerRequest;
use Luxodactyl\Enums\Daemon\DaemonType;

class ServerController extends ClientApiController
{
    /**
     * ServerController constructor.
     */
    public function __construct(private GetUserPermissionsService $permissionsService)
    {
        parent::__construct();
    }

    /**
     * Transform an individual server into a response that can be consumed by a
     * client using the API.
     */
    public function index(GetServerRequest $request, Server $server): array
    {
        $server->loadMissing('node');

        $daemonType = $server->node?->daemonType;
        return $this->fractal->item($server)
            ->transformWith($this->getTransformer(ServerTransformer::class))
            ->addMeta([
                'daemonType' => $daemonType,
                'is_server_owner' => $request->user()->id === $server->owner_id,
                'user_permissions' => $this->permissionsService->handle($server, $request->user()),
            ])
            ->toArray();
    }

    public function resources(GetServerRequest $request, Server $server): array
    {
        $server->loadMissing('node');

        $daemonType = $server->node?->daemonType ?? 'elytra';
        $controllers = DaemonType::allResources();
        $controllerClass = $controllers[$daemonType];

        $controller = app($controllerClass);
        return $controller->__invoke($request, $server);
    }
}
