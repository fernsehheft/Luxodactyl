<?php

namespace Luxodactyl\Http\Controllers\Api\Remote\Backups;

use Illuminate\Http\Request;
use Luxodactyl\Models\Backup;
use Illuminate\Http\JsonResponse;
use Luxodactyl\Facades\Activity;
use Luxodactyl\Http\Controllers\Controller;
use Luxodactyl\Exceptions\Http\HttpForbiddenException;
use Luxodactyl\Exceptions\Service\Backup\BackupLockedException;
use Symfony\Component\HttpKernel\Exception\BadRequestHttpException;

class BackupDeleteController extends Controller
{

    /**
     * Handles the deletion of a backup from the remote daemon.
     *
     * @throws \Throwable
     */
    public function __invoke(Request $request, string $backup): JsonResponse
    {
        // Get the node associated with the request.
        /** @var \Luxodactyl\Models\Node $node */
        $node = $request->attributes->get('node');

        /** @var Backup $model */
        $model = Backup::query()
            ->where('uuid', $backup)
            ->firstOrFail();

        // Check that the backup is "owned" by the node making the request. This avoids other nodes
        // from messing with backups that they don't own.
        /** @var \Luxodactyl\Models\Server $server */
        $server = $model->server;
        if ($server->node_id !== $node->id) {
            throw new HttpForbiddenException('You do not have permission to access that backup.');
        }

        try {
            // Log the backup deletion activity
            $log = Activity::event('server:backup.delete')
                ->subject($model, $model->server)
                ->property('name', $model->name);

            $log->transaction(function () use ($model) {
                // Simply mark the backup as deleted
                $model->delete();
            });

            return new JsonResponse([], JsonResponse::HTTP_NO_CONTENT);
        } catch (BackupLockedException $exception) {
            throw new BadRequestHttpException('Cannot delete a backup that is marked as locked.');
        }
    }
}