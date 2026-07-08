<?php

namespace Luxodactyl\Repositories\Eloquent;

use Luxodactyl\Models\S3;
use Luxodactyl\Contracts\Repository\S3RepositoryInterface;

class S3Repository extends EloquentRepository implements S3RepositoryInterface
{
    /**
     * Return the model backing this repository.
     */
    public function model(): string
    {
        return S3::class;
    }
}
