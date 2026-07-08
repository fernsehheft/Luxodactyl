<?php

namespace Luxodactyl\Repositories\Eloquent;

use Luxodactyl\Models\User;
use Luxodactyl\Contracts\Repository\UserRepositoryInterface;

class UserRepository extends EloquentRepository implements UserRepositoryInterface
{
    /**
     * Return the model backing this repository.
     */
    public function model(): string
    {
        return User::class;
    }
}
