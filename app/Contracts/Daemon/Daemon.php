<?php

namespace Luxodactyl\Contracts\Daemon;

use Luxodactyl\Models\Node;

interface Daemon
{
    public function getConfiguration(Node $node): array;
    public function getAutoDeploy(Node $node, string $token): string;
}
