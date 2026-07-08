<?php

namespace Luxodactyl\Exceptions\Service\Database;

use Luxodactyl\Exceptions\LuxodactylException;

class DatabaseClientFeatureNotEnabledException extends LuxodactylException
{
    public function __construct()
    {
        parent::__construct('Client database creation is not enabled in this Panel.');
    }
}
