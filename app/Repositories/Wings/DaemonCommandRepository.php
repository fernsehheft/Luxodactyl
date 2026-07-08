<?php

namespace Luxodactyl\Repositories\Wings;

use Webmozart\Assert\Assert;
use Luxodactyl\Models\Server;
use Psr\Http\Message\ResponseInterface;
use GuzzleHttp\Exception\TransferException;
use Luxodactyl\Exceptions\Http\Connection\DaemonConnectionException;

/**
 * @method \Luxodactyl\Repositories\Wings\DaemonCommandRepository setNode(\Luxodactyl\Models\Node $node)
 * @method \Luxodactyl\Repositories\Wings\DaemonCommandRepository setServer(\Luxodactyl\Models\Server $server)
 */
class DaemonCommandRepository extends DaemonRepository
{
    /**
     * Sends a command or multiple commands to a running server instance.
     *
     * @throws DaemonConnectionException
     */
    public function send(array|string $command): ResponseInterface
    {
        Assert::isInstanceOf($this->server, Server::class);

        try {
            return $this->getHttpClient()->post(
                sprintf('/api/servers/%s/commands', $this->server->uuid),
                [
                    'json' => ['commands' => is_array($command) ? $command : [$command]],
                ]
            );
        } catch (TransferException $exception) {
            throw new DaemonConnectionException($exception);
        }
    }
}
