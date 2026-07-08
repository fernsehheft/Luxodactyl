<?php

namespace Luxodactyl\Facades;

use Illuminate\Support\Facades\Facade;
use Luxodactyl\Services\Activity\ActivityLogBatchService;

class LogBatch extends Facade
{
    protected static function getFacadeAccessor(): string
    {
        return ActivityLogBatchService::class;
    }
}
