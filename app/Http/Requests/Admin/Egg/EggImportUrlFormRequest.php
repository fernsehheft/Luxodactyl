<?php

namespace Luxodactyl\Http\Requests\Admin\Egg;

use Luxodactyl\Http\Requests\Admin\AdminFormRequest;

class EggImportUrlFormRequest extends AdminFormRequest
{
    public function rules(): array
    {
        $rules = [
            'import_file_url' => 'bail|required|string|max:300',
        ];

        if ($this->method() !== 'PUT') {
            $rules['import_to_nest'] = 'bail|required|integer|exists:nests,id';
        }

        return $rules;
    }
}
