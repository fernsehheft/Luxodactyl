<?php

namespace Luxodactyl\Transformers\Api\Client;

use Luxodactyl\Models\Egg;

class EggTransformer extends BaseClientTransformer
{
    /**
     * Return the resource name for the JSONAPI output.
     */
    public function getResourceName(): string
    {
        return Egg::RESOURCE_NAME;
    }

    public function transform(Egg $egg): array
    {
        return [
            'id' => $egg->id,
            'uuid' => $egg->uuid,
            'name' => $egg->name,
            'description' => $egg->description,
        ];
    }
}
