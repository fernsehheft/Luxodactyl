<?php

namespace Luxodactyl\Http\Controllers\Api\Application\Servers;

use Luxodactyl\Models\Server;
use Luxodactyl\Services\Servers\BuildModificationService;
use Luxodactyl\Services\Servers\DetailsModificationService;
use Luxodactyl\Transformers\Api\Application\ServerTransformer;
use Luxodactyl\Http\Controllers\Api\Application\ApplicationApiController;
use Luxodactyl\Http\Requests\Api\Application\Servers\UpdateServerDetailsRequest;
use Luxodactyl\Http\Requests\Api\Application\Servers\UpdateServerBuildConfigurationRequest;

class ServerDetailsController extends ApplicationApiController
{
    /**
     * ServerDetailsController constructor.
     */
    public function __construct(
        private BuildModificationService $buildModificationService,
        private DetailsModificationService $detailsModificationService,
    ) {
        parent::__construct();
    }

    /**
     * Update the details for a specific server.
     *
     * @throws \Luxodactyl\Exceptions\DisplayException
     * @throws \Luxodactyl\Exceptions\Model\DataValidationException
     * @throws \Luxodactyl\Exceptions\Repository\RecordNotFoundException
     */
    public function details(UpdateServerDetailsRequest $request, Server $server): array
    {
        $updated = $this->detailsModificationService->returnUpdatedModel()->handle(
            $server,
            $request->validated()
        );

        return $this->fractal->item($updated)
            ->transformWith($this->getTransformer(ServerTransformer::class))
            ->toArray();
    }

    /**
     * Update the build details for a specific server.
     *
     * @throws \Luxodactyl\Exceptions\DisplayException
     * @throws \Luxodactyl\Exceptions\Model\DataValidationException
     * @throws \Luxodactyl\Exceptions\Repository\RecordNotFoundException
     */
    public function build(UpdateServerBuildConfigurationRequest $request, Server $server): array
    {
        $server = $this->buildModificationService->handle($server, $request->validated());

        return $this->fractal->item($server)
            ->transformWith($this->getTransformer(ServerTransformer::class))
            ->toArray();
    }
}
