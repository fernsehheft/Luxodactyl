<?php

namespace Luxodactyl\Http\Controllers\Api\Remote;

use Illuminate\Http\JsonResponse;
use Luxodactyl\Http\Controllers\Controller;
use Luxodactyl\Services\Elytra\ElytraJobService;
use Luxodactyl\Http\Requests\Api\Remote\ElytraJobCompleteRequest;

class ElytraJobCompletionController extends Controller
{
    public function __construct(
        private ElytraJobService $elytraJobService,
    ) {}

    public function update(ElytraJobCompleteRequest $request, string $jobId): JsonResponse
    {
        try {
            $this->elytraJobService->updateJobStatus($jobId, $request->validated());

            return response()->json([
                'success' => true,
                'message' => 'Job status updated successfully',
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}