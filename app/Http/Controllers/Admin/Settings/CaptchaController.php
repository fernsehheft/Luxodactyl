<?php

namespace Luxodactyl\Http\Controllers\Admin\Settings;

use Illuminate\View\View;
use Illuminate\Http\RedirectResponse;
use Prologue\Alerts\AlertsMessageBag;
use Illuminate\Contracts\Console\Kernel;
use Illuminate\View\Factory as ViewFactory;
use Luxodactyl\Http\Controllers\Controller;
use Luxodactyl\Services\Captcha\CaptchaManager;
use Illuminate\Contracts\Encryption\Encrypter;
use Luxodactyl\Contracts\Repository\SettingsRepositoryInterface;
use Luxodactyl\Http\Requests\Admin\Settings\CaptchaSettingsFormRequest;
use Luxodactyl\Enums\Captcha\Captchas;

class CaptchaController extends Controller
{
    /**
     * CaptchaController constructor.
     */
    public function __construct(
        private AlertsMessageBag $alert,
        private CaptchaManager $captcha,
        private Encrypter $encrypter,
        private Kernel $kernel,
        private SettingsRepositoryInterface $settings,
        private ViewFactory $view,
    ) {}

    /**
     * Render captcha settings UI.
     */
    public function index(): View
    {

        return $this->view->make('admin.settings.captcha', [
            'providers' => Captchas::all(),
        ]);
    }

    /**
     * Update captcha settings.
     *
     * @throws \Luxodactyl\Exceptions\Model\DataValidationException
     * @throws \Luxodactyl\Exceptions\Repository\RecordNotFoundException
     */
    public function update(CaptchaSettingsFormRequest $request): RedirectResponse
    {
        $values = $request->normalize();

        foreach ($values as $key => $value) {
            // Encrypt secret keys before storing
            if (in_array($key, \Luxodactyl\Providers\SettingsServiceProvider::getEncryptedKeys()) && !empty($value)) {
                $value = $this->encrypter->encrypt($value);
            }

            $this->settings->set('settings::' . $key, $value);
        }

        $this->kernel->call('queue:restart');
        $this->alert->success('Captcha settings have been updated successfully and the queue worker was restarted to apply these changes.')->flash();

        return redirect()->route('admin.settings.captcha');
    }
}
