<?php

namespace Luxodactyl\Facades;

use Illuminate\Support\Facades\Facade;
use Luxodactyl\Services\Activity\ActivityLogTargetableService;

class LogTarget extends Facade
{
    protected static function getFacadeAccessor(): string
    {
        return ActivityLogTargetableService::class;
    }
}
