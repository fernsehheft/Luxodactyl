<?php

namespace Luxodactyl\Providers;

use Illuminate\Support\ServiceProvider;
use Luxodactyl\Repositories\Eloquent\EggRepository;
use Luxodactyl\Repositories\Eloquent\NestRepository;
use Luxodactyl\Repositories\Eloquent\NodeRepository;
use Luxodactyl\Repositories\Eloquent\TaskRepository;
use Luxodactyl\Repositories\Eloquent\UserRepository;
use Luxodactyl\Repositories\Eloquent\ApiKeyRepository;
use Luxodactyl\Repositories\Eloquent\S3Repository;
use Luxodactyl\Repositories\Eloquent\ServerRepository;
use Luxodactyl\Repositories\Eloquent\SessionRepository;
use Luxodactyl\Repositories\Eloquent\SubuserRepository;
use Luxodactyl\Repositories\Eloquent\DatabaseRepository;
use Luxodactyl\Repositories\Eloquent\LocationRepository;
use Luxodactyl\Repositories\Eloquent\ScheduleRepository;
use Luxodactyl\Repositories\Eloquent\SettingsRepository;
use Luxodactyl\Repositories\Eloquent\AllocationRepository;
use Luxodactyl\Contracts\Repository\EggRepositoryInterface;
use Luxodactyl\Repositories\Eloquent\EggVariableRepository;
use Luxodactyl\Contracts\Repository\NestRepositoryInterface;
use Luxodactyl\Contracts\Repository\NodeRepositoryInterface;
use Luxodactyl\Contracts\Repository\TaskRepositoryInterface;
use Luxodactyl\Contracts\Repository\UserRepositoryInterface;
use Luxodactyl\Repositories\Eloquent\DatabaseHostRepository;
use Luxodactyl\Contracts\Repository\ApiKeyRepositoryInterface;
use Luxodactyl\Contracts\Repository\S3RepositoryInterface;
use Luxodactyl\Contracts\Repository\ServerRepositoryInterface;
use Luxodactyl\Repositories\Eloquent\ServerVariableRepository;
use Luxodactyl\Contracts\Repository\SessionRepositoryInterface;
use Luxodactyl\Contracts\Repository\SubuserRepositoryInterface;
use Luxodactyl\Contracts\Repository\DatabaseRepositoryInterface;
use Luxodactyl\Contracts\Repository\LocationRepositoryInterface;
use Luxodactyl\Contracts\Repository\ScheduleRepositoryInterface;
use Luxodactyl\Contracts\Repository\SettingsRepositoryInterface;
use Luxodactyl\Contracts\Repository\AllocationRepositoryInterface;
use Luxodactyl\Contracts\Repository\EggVariableRepositoryInterface;
use Luxodactyl\Contracts\Repository\DatabaseHostRepositoryInterface;
use Luxodactyl\Contracts\Repository\ServerVariableRepositoryInterface;

class RepositoryServiceProvider extends ServiceProvider
{
    /**
     * Register all the repository bindings.
     */
    public function register(): void
    {
        // Eloquent Repositories
        $this->app->bind(AllocationRepositoryInterface::class, AllocationRepository::class);
        $this->app->bind(ApiKeyRepositoryInterface::class, ApiKeyRepository::class);
        $this->app->bind(DatabaseRepositoryInterface::class, DatabaseRepository::class);
        $this->app->bind(DatabaseHostRepositoryInterface::class, DatabaseHostRepository::class);
        $this->app->bind(EggRepositoryInterface::class, EggRepository::class);
        $this->app->bind(EggVariableRepositoryInterface::class, EggVariableRepository::class);
        $this->app->bind(LocationRepositoryInterface::class, LocationRepository::class);
        $this->app->bind(NestRepositoryInterface::class, NestRepository::class);
        $this->app->bind(NodeRepositoryInterface::class, NodeRepository::class);
        $this->app->bind(ScheduleRepositoryInterface::class, ScheduleRepository::class);
        $this->app->bind(S3RepositoryInterface::class, S3Repository::class);
        $this->app->bind(ServerRepositoryInterface::class, ServerRepository::class);
        $this->app->bind(ServerVariableRepositoryInterface::class, ServerVariableRepository::class);
        $this->app->bind(SessionRepositoryInterface::class, SessionRepository::class);
        $this->app->bind(SettingsRepositoryInterface::class, SettingsRepository::class);
        $this->app->bind(SubuserRepositoryInterface::class, SubuserRepository::class);
        $this->app->bind(TaskRepositoryInterface::class, TaskRepository::class);
        $this->app->bind(UserRepositoryInterface::class, UserRepository::class);
    }
}
