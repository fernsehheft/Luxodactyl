<?php

namespace Luxodactyl\Repositories\Wings;

use Webmozart\Assert\Assert;
use Luxodactyl\Models\Server;
use Psr\Http\Message\ResponseInterface;
use GuzzleHttp\Exception\TransferException;
use Luxodactyl\Exceptions\Http\Connection\DaemonConnectionException;

/**
 * @method \Luxodactyl\Repositories\Wings\DaemonPowerRepository setNode(\Luxodactyl\Models\Node $node)
 * @method \Luxodactyl\Repositories\Wings\DaemonPowerRepository setServer(\Luxodactyl\Models\Server $server)
 */
class DaemonPowerRepository extends DaemonRepository
{
    /**
     * Sends a power action to the server instance.
     *
     * @throws DaemonConnectionException
     */
    public function send(string $action): ResponseInterface
    {
        Assert::isInstanceOf($this->server, Server::class);

        try {
            return $this->getHttpClient()->post(
                sprintf('/api/servers/%s/power', $this->server->uuid),
                ['json' => ['action' => $action]]
            );
        } catch (TransferException $exception) {
            throw new DaemonConnectionException($exception);
        }
    }
}
