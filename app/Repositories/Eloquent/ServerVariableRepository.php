<?php

namespace Luxodactyl\Repositories\Eloquent;

use Luxodactyl\Models\ServerVariable;
use Luxodactyl\Contracts\Repository\ServerVariableRepositoryInterface;

class ServerVariableRepository extends EloquentRepository implements ServerVariableRepositoryInterface
{
    /**
     * Return the model backing this repository.
     */
    public function model(): string
    {
        return ServerVariable::class;
    }
}
