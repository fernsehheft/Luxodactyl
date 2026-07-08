<?php

namespace Luxodactyl\Services\Servers;

use Luxodactyl\Models\Server;
use Luxodactyl\Facades\Activity;
use Illuminate\Database\ConnectionInterface;
use Luxodactyl\Repositories\Wings\DaemonServerRepository;

class StartupCommandUpdateService
{
    public function __construct(
        private ConnectionInterface $connection,
        private DaemonServerRepository $daemonServerRepository,
    ) {
    }

    /**
     * Updates the startup command for a server and syncs the configuration with Wings.
     *
     * @throws \Luxodactyl\Exceptions\Http\Connection\DaemonConnectionException
     * @throws \Throwable
     */
    public function handle(Server $server, string $startup): Server
    {
        $original = $server->startup;

        return $this->connection->transaction(function () use ($server, $startup, $original) {
            $server->update(['startup' => $startup]);

            // Log the activity
            Activity::event('server:startup.command')
                ->subject($server)
                ->property([
                    'old' => $original,
                    'new' => $startup,
                ])
                ->log();

            // Sync the server configuration with Wings daemon
            $this->daemonServerRepository->setServer($server)->sync();

            return $server->refresh();
        });
    }
}