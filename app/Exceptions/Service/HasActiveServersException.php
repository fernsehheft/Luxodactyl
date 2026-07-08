<?php

namespace Luxodactyl\Exceptions\Service;

use Illuminate\Http\Response;
use Luxodactyl\Exceptions\DisplayException;

class HasActiveServersException extends DisplayException
{
    public function getStatusCode(): int
    {
        return Response::HTTP_BAD_REQUEST;
    }
}
