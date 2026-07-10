<?php

namespace Luxodactyl\Http\Controllers\Admin\Nodes;

use Illuminate\View\View;
use Illuminate\Http\Request;
use Luxodactyl\Models\Node;
use Spatie\QueryBuilder\QueryBuilder;
use Luxodactyl\Http\Controllers\Controller;
use Illuminate\Contracts\View\Factory as ViewFactory;
use Luxodactyl\Repositories\Eloquent\NodeRepository;
use Illuminate\Support\Facades\Log;

class NodeController extends Controller
{
    /**
     * NodeController constructor.
     */
    public function __construct(private ViewFactory $view) {}

    /**
     * Returns a listing of nodes on the system.
     */
    public function index(Request $request): View
    {
        $nodes = QueryBuilder::for(
            Node::query()->with('location')->withCount('servers')
        )
            ->allowedFilters(['uuid', 'name'])
            ->allowedSorts(['id'])
            ->paginate(25);

        foreach ($nodes as $node) {
            $stats = app('Luxodactyl\Repositories\Eloquent\NodeRepository')->getUsageStatsRaw($node);
            // NOTE: Pre-creating stats so we donn't do it in the blade

            // A node's memory/disk limit is allowed to be 0 (unlimited / not
            // set). Dividing by it would throw DivisionByZeroError on PHP 8+
            // and 500 the whole nodes list, so treat a 0 base limit as 0% used.
            $memoryBase = $stats['memory']['base_limit'];
            $diskBase = $stats['disk']['base_limit'];
            $memoryPercent = $memoryBase > 0 ? ($stats['memory']['value'] / $memoryBase) * 100 : 0;
            $diskPercent = $diskBase > 0 ? ($stats['disk']['value'] / $diskBase) * 100 : 0;

            $node->memory_percent = round($memoryPercent);
            $node->memory_color = $memoryPercent < 50 ? '#50af51' : ($memoryPercent < 70 ? '#e0a800' : '#d9534f');
            $node->allocated_memory = humanizeSize($stats['memory']['value'] * 1024 * 1024);
            $node->total_memory = humanizeSize($stats['memory']['max'] * 1024 * 1024);

            $node->disk_percent = round($diskPercent);
            $node->disk_color = $diskPercent < 50 ? '#50af51' : ($diskPercent < 70 ? '#e0a800' : '#d9534f');
            $node->allocated_disk = humanizeSize($stats['disk']['value'] * 1024 * 1024);
            $node->total_disk = humanizeSize($stats['disk']['max'] * 1024 * 1024);
        }


        return $this->view->make('admin.nodes.index', ['nodes' => $nodes]);
    }
}
