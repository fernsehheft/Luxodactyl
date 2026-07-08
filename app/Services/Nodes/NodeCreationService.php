<?php

namespace Luxodactyl\Services\Nodes;

use Ramsey\Uuid\Uuid;
use Illuminate\Support\Str;
use Luxodactyl\Models\Node;
use Illuminate\Contracts\Encryption\Encrypter;
use Luxodactyl\Contracts\Repository\NodeRepositoryInterface;

class NodeCreationService
{
    /**
     * NodeCreationService constructor.
     */
    public function __construct(protected NodeRepositoryInterface $repository)
    {
    }

    /**
     * Create a new node on the panel.
     *
     * @throws \Luxodactyl\Exceptions\Model\DataValidationException
     */
    public function handle(array $data): Node
    {
        $data['uuid'] = Uuid::uuid4()->toString();
        $data['daemon_token'] = app(Encrypter::class)->encrypt(Str::random(Node::DAEMON_TOKEN_LENGTH));
        $data['daemon_token_id'] = Str::random(Node::DAEMON_TOKEN_ID_LENGTH);

        // Automatically set use_separate_fqdns based on whether internal_fqdn is provided
        if (isset($data['internal_fqdn'])) {
            $data['use_separate_fqdns'] = !empty($data['internal_fqdn']);
        }

        return $this->repository->create($data, true, true);
    }
}
