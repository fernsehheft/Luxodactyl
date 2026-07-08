<?php

namespace Luxodactyl\Http\Controllers\Api\Application\Servers;

use Luxodactyl\Models\User;
use Luxodactyl\Models\Server;
use Luxodactyl\Services\Servers\StartupModificationService;
use Luxodactyl\Transformers\Api\Application\ServerTransformer;
use Luxodactyl\Http\Controllers\Api\Application\ApplicationApiController;
use Luxodactyl\Http\Requests\Api\Application\Servers\UpdateServerStartupRequest;

class StartupController extends ApplicationApiController
{
    /**
     * StartupController constructor.
     */
    public function __construct(private StartupModificationService $modificationService)
    {
        parent::__construct();
    }

    /**
     * Update the startup and environment settings for a specific server.
     *
     * @throws \Illuminate\Validation\ValidationException
     * @throws \Luxodactyl\Exceptions\Http\Connection\DaemonConnectionException
     * @throws \Luxodactyl\Exceptions\Model\DataValidationException
     * @throws \Luxodactyl\Exceptions\Repository\RecordNotFoundException
     */
    public function index(UpdateServerStartupRequest $request, Server $server): array
    {
        $server = $this->modificationService
            ->setUserLevel(User::USER_LEVEL_ADMIN)
            ->handle($server, $request->validated());

        return $this->fractal->item($server)
            ->transformWith($this->getTransformer(ServerTransformer::class))
            ->toArray();
    }
}
