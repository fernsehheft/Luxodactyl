<?php

namespace Luxodactyl\Http\Requests\Admin;

use Luxodactyl\Models\User;
use Illuminate\Support\Collection;

class NewUserFormRequest extends AdminFormRequest
{
    /**
     * Rules to apply to requests for updating or creating a user
     * in the Admin CP.
     */
    public function rules(): array
    {
        return Collection::make(
            User::getRules()
        )->only([
            'email',
            'username',
            'name_first',
            'password',
            'language',
            'root_admin',
        ])->toArray();
    }
}
