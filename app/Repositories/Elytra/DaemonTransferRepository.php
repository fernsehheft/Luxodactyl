<?php

namespace Luxodactyl\Repositories\Elytra;

use Luxodactyl\Models\Node;
use Lcobucci\JWT\Token\Plain;
use GuzzleHttp\Exception\GuzzleException;
use Luxodactyl\Exceptions\Http\Connection\DaemonConnectionException;

/**
 * @method \Luxodactyl\Repositories\Elytra\DaemonTransferRepository setNode(\Luxodactyl\Models\Node $node)
 * @method \Luxodactyl\Repositories\Elytra\DaemonTransferRepository setServer(\Luxodactyl\Models\Server $server)
 */
class DaemonTransferRepository extends DaemonRepository
{
    /**
     * @throws DaemonConnectionException
     */
    public function notify(Node $targetNode, Plain $token): void
    {
        try {
            $this->getHttpClient()->post(sprintf('/api/servers/%s/transfer', $this->server->uuid), [
                'json' => [
                    'server_id' => $this->server->uuid,
                    'url' => $targetNode->getConnectionAddress() . '/api/transfers',
                    'token' => 'Bearer ' . $token->toString(),
                    'server' => [
                        'uuid' => $this->server->uuid,
                        'start_on_completion' => false,
                    ],
                ],
            ]);
        } catch (GuzzleException $exception) {
            throw new DaemonConnectionException($exception);
        }
    }
}
