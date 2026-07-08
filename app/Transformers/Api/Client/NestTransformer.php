<?php

namespace Luxodactyl\Transformers\Api\Client;

use Luxodactyl\Models\Egg;
use Luxodactyl\Models\Nest;
use League\Fractal\Resource\Collection;
use League\Fractal\Resource\NullResource;

class NestTransformer extends BaseClientTransformer
{
    /**
     * Relationships that can be loaded onto this transformation.
     */
    protected array $availableIncludes = ['eggs'];

    protected array $defaultIncludes = ['eggs'];

    /**
     * Return the resource name for the JSONAPI output.
     */
    public function getResourceName(): string
    {
        return Nest::RESOURCE_NAME;
    }

    /**
     * Transform a Nest model into a representation that can be consumed by the
     * client API.
     */
    public function transform(Nest $model): array
    {
        return [
            'id' => $model->id,
            'uuid' => $model->uuid,
            'author' => $model->author,
            'name' => $model->name,
            'description' => $model->description,
            'created_at' => $this->formatTimestamp($model->created_at),
            'updated_at' => $this->formatTimestamp($model->updated_at),
        ];
    }

    /**
     * Include the Eggs relationship on the given Nest model transformation.
     *
     * @throws \Luxodactyl\Exceptions\Transformer\InvalidTransformerLevelException
     */
    public function includeEggs(Nest $model): Collection|NullResource
    {
        $model->loadMissing('eggs');

        return $this->collection($model->getRelation('eggs'), $this->makeTransformer(EggTransformer::class), Egg::RESOURCE_NAME);
    }
}