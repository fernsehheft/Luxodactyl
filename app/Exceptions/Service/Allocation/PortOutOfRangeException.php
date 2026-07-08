<?php

namespace Luxodactyl\Exceptions\Service\Allocation;

use Luxodactyl\Exceptions\DisplayException;

class PortOutOfRangeException extends DisplayException
{
    /**
     * PortOutOfRangeException constructor.
     */
    public function __construct()
    {
        parent::__construct(trans('exceptions.allocations.port_out_of_range'));
    }
}
