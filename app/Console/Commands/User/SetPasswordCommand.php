<?php

namespace Luxodactyl\Console\Commands\User;

use Illuminate\Console\Command;
use Luxodactyl\Models\User;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Luxodactyl\Services\Users\UserUpdateService;

class SetPasswordCommand extends Command
{
    protected $description = 'Reset the password for an existing user identified by email or username. Used to recover access to an account that already exists, e.g. when reinstalling the panel without wiping the database.';

    protected $signature = 'p:user:password {--email=} {--username=} {--password=} {--admin}';

    /**
     * SetPasswordCommand constructor.
     */
    public function __construct(private UserUpdateService $updateService)
    {
        parent::__construct();
    }

    /**
     * Handle command request to reset a user's password.
     *
     * @throws \Throwable
     */
    public function handle()
    {
        $email = $this->option('email');
        $username = $this->option('username');

        if (empty($email) && empty($username)) {
            $this->error('You must provide either --email or --username to identify the account.');

            return 1;
        }

        $query = User::query();
        $query = $email ? $query->where('email', $email) : $query->where('username', $username);

        try {
            /** @var User $user */
            $user = $query->firstOrFail();
        } catch (ModelNotFoundException) {
            $this->error('No user could be found matching the given email/username.');

            return 1;
        }

        $password = $this->option('password') ?? $this->secret(trans('command/messages.user.ask_password'));

        $data = ['password' => $password];
        if ($this->option('admin')) {
            $data['root_admin'] = true;
        }

        $this->updateService->handle($user, $data);

        $this->info("Password updated for {$user->username} ({$user->email}).");
    }
}
