<?php

namespace Pterodactyl\Console\Commands\Bucket;

use Illuminate\Console\Command;
use Pterodactyl\Services\S3\S3CreationService;

class MakeBucketCommand extends Command
{
    protected $signature = 'p:bucket:make
                            {--name= : A display name for this S3 configuration.}
                            {--description= : A brief description of this S3 configuration.}
                            {--access-key= : The S3 access key.}
                            {--secret-key= : The S3 secret key.}
                            {--endpoint= : The S3 endpoint URL (leave blank for AWS S3).}
                            {--bucket-name= : The S3 bucket name.}
                            {--use-path-style-endpoint= : Use path-style endpoints? (1=yes / 0=no).}
                            {--enabled= : Whether this configuration is enabled (1=enabled / 0=disabled).}';

    protected $description = 'Creates a new S3 bucket configuration on the system via the CLI.';

    public function __construct(private S3CreationService $creationService)
    {
        parent::__construct();
    }

    public function handle()
    {
        $data['name'] = $this->option('name') ?? $this->ask('Enter a display name for this S3 configuration');
        $data['description'] = $this->option('description') ?? $this->ask('Enter a brief description of this S3 configuration', '');
        $data['access_key'] = $this->option('access-key') ?? $this->ask('Enter the S3 access key');
        $data['secret_key'] = $this->option('secret-key') ?? $this->ask('Enter the S3 secret key');
        $data['endpoint'] = $this->option('endpoint') ?? $this->ask('Enter the S3 endpoint URL (leave blank for AWS S3)', '');
        $data['bucket_name'] = $this->option('bucket-name') ?? $this->ask('Enter the S3 bucket name');
        $data['use_path_style_endpoint'] = $this->option('use-path-style-endpoint') ?? $this->confirm('Use path-style endpoints?', false);
        $data['enabled'] = $this->option('enabled') ?? $this->confirm('Should this configuration be enabled?', true);

        $bucket = $this->creationService->handle($data);
        $this->line('Successfully created a new S3 bucket configuration "' . $data['name'] . '" with id ' . $bucket->id . '.');
    }
}
