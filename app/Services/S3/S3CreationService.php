<?php

namespace Luxodactyl\Services\S3;

use Luxodactyl\Models\S3;
use Luxodactyl\Contracts\Repository\S3RepositoryInterface;

class S3CreationService
{
    public function __construct(
        private S3RepositoryInterface $repository
    ) {}

    public function handle(array $data): S3
    {
        return $this->repository->create($data);
    }
}
