<?php

namespace Luxodactyl\Contracts\Elytra;

use Luxodactyl\Models\Server;
use Luxodactyl\Models\ElytraJob;
use Luxodactyl\Repositories\Elytra\ElytraRepository;

interface Job
{
    public static function getSupportedJobTypes(): array;

    public function getRequiredPermissions(string $operation): array;

    public function validateJobData(array $jobData): array;

    public function submitToElytra(Server $server, ElytraJob $job, ElytraRepository $elytraRepository): string;

    public function cancelOnElytra(Server $server, ElytraJob $job, ElytraRepository $elytraRepository): void;

    public function processStatusUpdate(ElytraJob $job, array $statusData): void;

    public function formatJobResponse(ElytraJob $job): array;
}