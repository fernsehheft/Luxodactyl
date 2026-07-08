<?php

namespace Luxodactyl\Facades;

use Illuminate\Support\Facades\Facade;
use Luxodactyl\Services\Activity\ActivityLogService;

class Activity extends Facade
{
    protected static function getFacadeAccessor(): string
    {
        return ActivityLogService::class;
    }
}
