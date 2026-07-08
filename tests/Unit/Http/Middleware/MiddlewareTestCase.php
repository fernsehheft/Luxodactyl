<?php

namespace Luxodactyl\Tests\Unit\Http\Middleware;

use Luxodactyl\Tests\TestCase;
use Luxodactyl\Tests\Traits\Http\RequestMockHelpers;
use Luxodactyl\Tests\Traits\Http\MocksMiddlewareClosure;
use Luxodactyl\Tests\Assertions\MiddlewareAttributeAssertionsTrait;

abstract class MiddlewareTestCase extends TestCase
{
    use MiddlewareAttributeAssertionsTrait;
    use MocksMiddlewareClosure;
    use RequestMockHelpers;

    /**
     * Setup tests with a mocked request object and normal attributes.
     */
    public function setUp(): void
    {
        parent::setUp();

        $this->buildRequestMock();
    }
}
