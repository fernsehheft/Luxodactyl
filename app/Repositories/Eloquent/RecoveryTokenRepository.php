<?php

namespace Luxodactyl\Repositories\Eloquent;

use Luxodactyl\Models\RecoveryToken;

class RecoveryTokenRepository extends EloquentRepository
{
    public function model(): string
    {
        return RecoveryToken::class;
    }
}
