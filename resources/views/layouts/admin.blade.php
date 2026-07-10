<!DOCTYPE html>
<html>

<head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <title>{{ config('app.name', 'Panel') }} - @yield('title')</title>
  <meta content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" name="viewport">
  <meta name="_token" content="{{ csrf_token() }}">

  @php
    $_favType = config('app.logo.type');
    $_favVal = config('app.logo.value');
    if ($_favType === 'upload' && $_favVal) {
      $_favUrl = url('storage/' . $_favVal);
    } elseif ($_favType === 'link' && $_favVal) {
      $_favUrl = $_favVal;
    } else {
      $_favUrl = null;
    }
  @endphp
  @if($_favUrl)
  <link rel="icon" href="{{ $_favUrl }}" />
  <link rel="apple-touch-icon" href="{{ $_favUrl }}" />
  @endif
  <link rel="icon" type="image/png" href="/favicons/favicon-96x96.png" sizes="96x96" />
  <link rel="icon" type="image/svg+xml" href="/favicons/favicon.svg" />
  <link rel="shortcut icon" href="/favicons/favicon.ico" />
  <link rel="apple-touch-icon" sizes="180x180" href="/favicons/apple-touch-icon.png" />
  <meta name="apple-mobile-web-app-title" content="Luxodactyl" />
  <link rel="manifest" href="/favicons/site.webmanifest" />

  <meta name="theme-color" content="#000000">
  <meta name="darkreader-lock">

  @include('layouts.scripts')

  @section('scripts')
  @php
    // @vite() throws if the entry isn't in the manifest (e.g. a partial/failed
    // frontend build) -- checking the manifest content directly, rather than
    // just that the file exists, means a bad build degrades this admin JS
    // widget away instead of taking down every admin page with a 500.
    $_viteManifestPath = public_path('build/manifest.json');
    $_viteAdminEntryReady = false;
    if (file_exists($_viteManifestPath)) {
      $_viteManifestData = json_decode(file_get_contents($_viteManifestPath), true);
      $_viteAdminEntryReady = is_array($_viteManifestData) && isset($_viteManifestData['resources/scripts/admin/index.tsx']);
    }
  @endphp
  @if($_viteAdminEntryReady)
  @vite('resources/scripts/admin/index.tsx')
  @endif
  {!! Theme::css('vendor/select2/select2.min.css?t={cache-version}') !!}
  {!! Theme::css('vendor/bootstrap/bootstrap.min.css?t={cache-version}') !!}
  {!! Theme::css('vendor/adminlte/admin.min.css?t={cache-version}') !!}
  {!! Theme::css('vendor/adminlte/colors/skin-blue.min.css?t={cache-version}') !!}
  {!! Theme::css('vendor/sweetalert/sweetalert.min.css?t={cache-version}') !!}
  {!! Theme::css('vendor/animate/animate.min.css?t={cache-version}') !!}
  {!! Theme::css('css/pterodactyl.css?t={cache-version}') !!}
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/ionicons/2.0.1/css/ionicons.min.css">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

  <!--[if lt IE 9]>
            <script src="https://oss.maxcdn.com/html5shiv/3.7.3/html5shiv.min.js"></script>
            <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
            <![endif]-->
  @show

  {{-- ============================================================= --}}
  {{--  Luxodactyl admin theme — modern dark / cyan reskin overlay   --}}
  {{--  Loaded after all vendor CSS so it wins. Restyles AdminLTE     --}}
  {{--  without touching the individual admin page templates.         --}}
  {{-- ============================================================= --}}
  <link rel="preconnect" href="https://fonts.bunny.net" crossorigin>
  <link href="https://fonts.bunny.net/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <style id="luxodactyl-admin-theme">
    .luxodactyl-admin {
      /* Matches the React client app's tokens 1:1 (resources/scripts/assets/tailwind.css)
         so the admin area reads as the same product, not a differently-themed panel. */
      --lux-bg: #05070a;
      --lux-bg2: #0a0e17;
      --lux-surface: #0d131f;
      --lux-surface-2: #161f2e;
      --lux-border: #242f42;
      --lux-text: #f0f8ff;
      --lux-muted: #9fb4cc;
      --lux-accent: #00d8f6;
      --lux-accent-2: #008bb2;
      --lux-accent-dim: rgba(0, 216, 246, .12);
      --lux-radius: 14px;
      --lux-font: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    }

    /* ---- base ---- */
    .luxodactyl-admin,
    .luxodactyl-admin .content-wrapper,
    .luxodactyl-admin .right-side {
      background: var(--lux-bg) !important;
      color: var(--lux-text);
      font-family: var(--lux-font);
    }
    .luxodactyl-admin,
    .luxodactyl-admin p,
    .luxodactyl-admin span,
    .luxodactyl-admin div,
    .luxodactyl-admin td {
      font-family: var(--lux-font);
    }
    .luxodactyl-admin a { color: var(--lux-accent); }
    .luxodactyl-admin a:hover { color: var(--lux-accent-2); }
    .luxodactyl-admin .text-muted,
    .luxodactyl-admin .text-zinc { color: var(--lux-muted) !important; }

    /* ---- header ---- */
    .luxodactyl-admin .main-header .logo,
    .luxodactyl-admin .main-header .navbar {
      background: var(--lux-bg2) !important;
      border-bottom: 1px solid var(--lux-border);
      transition: none;
    }
    .luxodactyl-admin .main-header .logo {
      border-right: 1px solid var(--lux-border);
      font-family: var(--lux-font);
      font-weight: 800;
      letter-spacing: .3px;
      color: var(--lux-text) !important;
    }
    .luxodactyl-admin .main-header .logo b { font-weight: 800; }
    .luxodactyl-admin .main-header .logo:hover { background: var(--lux-surface) !important; }
    .luxodactyl-admin .main-header .navbar .nav > li > a {
      color: var(--lux-muted) !important;
    }
    .luxodactyl-admin .main-header .navbar .nav > li > a:hover {
      background: var(--lux-surface) !important;
      color: var(--lux-accent) !important;
    }
    .luxodactyl-admin .sidebar-toggle:hover { background: var(--lux-surface) !important; }

    /* ---- sidebar ---- */
    .luxodactyl-admin .main-sidebar,
    .luxodactyl-admin .left-side {
      background: var(--lux-bg2) !important;
      border-right: 1px solid var(--lux-border);
    }
    .luxodactyl-admin .sidebar-menu > li.header {
      background: transparent !important;
      color: var(--lux-muted) !important;
      font-size: 10.5px;
      font-weight: 700;
      letter-spacing: 1.4px;
      text-transform: uppercase;
      padding: 18px 16px 8px;
      opacity: .65;
    }
    .luxodactyl-admin .sidebar-menu > li > a {
      color: #b8c2ce !important;
      font-weight: 500;
      font-size: 14px;
      margin: 2px 10px;
      padding: 10px 14px;
      border-radius: 10px;
      border-left: none !important;
      transition: background .15s ease, color .15s ease;
    }
    .luxodactyl-admin .sidebar-menu > li > a > i,
    .luxodactyl-admin .sidebar-menu > li > a > .bi {
      color: var(--lux-muted);
      margin-right: 8px;
      transition: color .15s ease;
    }
    .luxodactyl-admin .sidebar-menu > li > a:hover {
      background: var(--lux-surface) !important;
      color: #fff !important;
    }
    .luxodactyl-admin .sidebar-menu > li > a:hover > i { color: var(--lux-accent); }
    .luxodactyl-admin .sidebar-menu > li.active > a {
      background: var(--lux-accent-dim) !important;
      color: var(--lux-accent) !important;
      border-left: none !important;
      box-shadow: inset 3px 0 0 var(--lux-accent);
    }
    .luxodactyl-admin .sidebar-menu > li.active > a > i { color: var(--lux-accent); }

    /* ---- content header ---- */
    .luxodactyl-admin .content-header { padding: 22px 20px 6px; }
    .luxodactyl-admin .content-header > h1 {
      font-weight: 800;
      font-size: 24px;
      color: var(--lux-text);
    }
    .luxodactyl-admin .content-header > h1 > small {
      color: var(--lux-muted);
      font-size: 14px;
      font-weight: 400;
    }
    .luxodactyl-admin .content-header > .breadcrumb {
      background: var(--lux-surface) !important;
      border: 1px solid var(--lux-border);
      border-radius: 999px;
      padding: 6px 14px;
    }
    .luxodactyl-admin .breadcrumb > li > a { color: var(--lux-muted); }
    .luxodactyl-admin .breadcrumb > .active { color: var(--lux-text); }

    /* ---- boxes / cards ---- */
    .luxodactyl-admin .box {
      background: var(--lux-surface) !important;
      border: 1px solid var(--lux-border) !important;
      border-top: 1px solid var(--lux-border) !important;
      border-radius: var(--lux-radius);
      box-shadow: 0 1px 2px rgba(0, 0, 0, .25) !important;
      color: var(--lux-text);
    }
    .luxodactyl-admin .box.box-primary { border-top: 2px solid var(--lux-accent) !important; }
    .luxodactyl-admin .box.box-info { border-top: 2px solid var(--lux-accent) !important; }
    .luxodactyl-admin .box.box-success { border-top: 2px solid #34d399 !important; }
    .luxodactyl-admin .box.box-danger { border-top: 2px solid #f87171 !important; }
    .luxodactyl-admin .box.box-warning { border-top: 2px solid #fbbf24 !important; }
    .luxodactyl-admin .box-header { color: var(--lux-text); border-bottom: 1px solid var(--lux-border); padding: 16px 18px; }
    .luxodactyl-admin .box-header .box-title { font-weight: 700; font-size: 16px; }
    .luxodactyl-admin .box-body { padding: 18px; }
    .luxodactyl-admin .box-footer {
      background: transparent !important;
      border-top: 1px solid var(--lux-border);
      color: var(--lux-muted);
    }
    .luxodactyl-admin .nav-tabs-custom { background: var(--lux-surface) !important; border-radius: var(--lux-radius); box-shadow: 0 1px 2px rgba(0,0,0,.25); }
    .luxodactyl-admin .nav-tabs-custom > .nav-tabs { border-bottom: 1px solid var(--lux-border); }
    .luxodactyl-admin .nav-tabs-custom > .nav-tabs > li.active > a { color: var(--lux-accent); }
    .luxodactyl-admin .nav-tabs-custom > .nav-tabs > li.active { border-top-color: var(--lux-accent); }

    /* ---- small info boxes / stats ---- */
    .luxodactyl-admin .info-box,
    .luxodactyl-admin .small-box {
      background: var(--lux-surface) !important;
      border: 1px solid var(--lux-border);
      border-radius: var(--lux-radius);
      color: var(--lux-text) !important;
      box-shadow: 0 1px 2px rgba(0, 0, 0, .25) !important;
    }
    .luxodactyl-admin .small-box h3,
    .luxodactyl-admin .small-box p { color: var(--lux-text) !important; }
    .luxodactyl-admin .info-box-icon { background: var(--lux-accent-dim) !important; color: var(--lux-accent) !important; border-radius: 10px; }

    /* ---- tables ---- */
    .luxodactyl-admin .table { color: var(--lux-text); }
    .luxodactyl-admin .table > thead > tr > th {
      border-bottom: 1px solid var(--lux-border) !important;
      color: var(--lux-muted);
      font-weight: 600;
      font-size: 12px;
      letter-spacing: .4px;
      text-transform: uppercase;
    }
    .luxodactyl-admin .table > tbody > tr > td,
    .luxodactyl-admin .table > tbody > tr > th { border-top: 1px solid var(--lux-border) !important; }
    .luxodactyl-admin .table-hover > tbody > tr:hover { background: var(--lux-surface-2) !important; }
    .luxodactyl-admin .table-striped > tbody > tr:nth-of-type(odd) { background: rgba(255, 255, 255, .015); }

    /* ---- buttons ---- */
    .luxodactyl-admin .btn {
      border-radius: 9px;
      font-weight: 600;
      border: 1px solid transparent;
      transition: filter .15s ease, background .15s ease;
    }
    .luxodactyl-admin .btn-primary {
      background: linear-gradient(180deg, var(--lux-accent), var(--lux-accent-2)) !important;
      border-color: transparent !important;
      color: #05222a !important;
    }
    .luxodactyl-admin .btn-primary:hover { filter: brightness(1.08); }
    .luxodactyl-admin .btn-default {
      background: var(--lux-surface-2) !important;
      border-color: var(--lux-border) !important;
      color: var(--lux-text) !important;
    }
    .luxodactyl-admin .btn-default:hover { background: #232f3e !important; }
    .luxodactyl-admin .btn-success { background: #10b981 !important; color: #fff !important; }
    .luxodactyl-admin .btn-danger { background: #ef4444 !important; color: #fff !important; }
    .luxodactyl-admin .btn-warning { background: #f59e0b !important; color: #201400 !important; }

    /* ---- forms ---- */
    .luxodactyl-admin .form-control,
    .luxodactyl-admin .select2-container--default .select2-selection--single,
    .luxodactyl-admin .select2-dropdown,
    .luxodactyl-admin .select2-search__field {
      background: var(--lux-bg2) !important;
      border: 1px solid var(--lux-border) !important;
      color: var(--lux-text) !important;
      border-radius: 9px;
      box-shadow: none !important;
    }
    .luxodactyl-admin .form-control:focus {
      border-color: var(--lux-accent) !important;
      box-shadow: 0 0 0 3px var(--lux-accent-dim) !important;
    }
    .luxodactyl-admin .form-control::placeholder { color: #5f6b7a; }
    .luxodactyl-admin label { color: #c6d0db; font-weight: 600; }
    .luxodactyl-admin .help-block { color: var(--lux-muted); }
    .luxodactyl-admin .select2-container--default .select2-selection--single .select2-selection__rendered { color: var(--lux-text); line-height: 32px; }
    .luxodactyl-admin .select2-container--default .select2-results__option--highlighted[aria-selected] { background: var(--lux-accent) !important; color: #05222a; }
    .luxodactyl-admin .input-group-addon { background: var(--lux-surface-2) !important; border-color: var(--lux-border) !important; color: var(--lux-muted) !important; }

    /* ---- alerts ---- */
    .luxodactyl-admin .alert { border-radius: 10px; border: 1px solid var(--lux-border); }
    .luxodactyl-admin .alert-success { background: rgba(16, 185, 129, .12) !important; color: #6ee7b7 !important; border-color: rgba(16,185,129,.3); }
    .luxodactyl-admin .alert-danger { background: rgba(239, 68, 68, .12) !important; color: #fca5a5 !important; border-color: rgba(239,68,68,.3); }
    .luxodactyl-admin .alert-info { background: var(--lux-accent-dim) !important; color: #67e8f9 !important; border-color: rgba(34,211,238,.3); }
    .luxodactyl-admin .alert-warning { background: rgba(245, 158, 11, .12) !important; color: #fcd34d !important; border-color: rgba(245,158,11,.3); }

    /* ---- misc ---- */
    .luxodactyl-admin .label-default,
    .luxodactyl-admin .badge { background: var(--lux-surface-2) !important; color: var(--lux-text); border-radius: 6px; }
    .luxodactyl-admin .label-primary, .luxodactyl-admin .badge.bg-blue { background: var(--lux-accent) !important; color: #05222a !important; }
    .luxodactyl-admin .pagination > li > a,
    .luxodactyl-admin .pagination > li > span {
      background: var(--lux-surface) !important;
      border-color: var(--lux-border) !important;
      color: var(--lux-text);
    }
    .luxodactyl-admin .pagination > .active > a,
    .luxodactyl-admin .pagination > .active > span { background: var(--lux-accent) !important; border-color: var(--lux-accent) !important; color: #05222a !important; }
    .luxodactyl-admin .main-footer {
      background: var(--lux-bg2) !important;
      border-top: 1px solid var(--lux-border);
      color: var(--lux-muted);
    }
    .luxodactyl-admin hr { border-top-color: var(--lux-border); }
    .luxodactyl-admin .modal-content { background: var(--lux-surface) !important; color: var(--lux-text); border: 1px solid var(--lux-border); border-radius: var(--lux-radius); }
    .luxodactyl-admin .modal-header, .luxodactyl-admin .modal-footer { border-color: var(--lux-border); }
    .luxodactyl-admin ::-webkit-scrollbar { width: 10px; height: 10px; }
    .luxodactyl-admin ::-webkit-scrollbar-track { background: var(--lux-bg); }
    .luxodactyl-admin ::-webkit-scrollbar-thumb { background: #2a3646; border-radius: 6px; }
    .luxodactyl-admin ::-webkit-scrollbar-thumb:hover { background: #35455a; }
  </style>
</head>

<body class="hold-transition skin-blue fixed sidebar-mini luxodactyl-admin">
  <div class="wrapper">
    <header class="main-header">
      <a href="{{ route('index') }}" class="logo">
        @php
          $logoType = config('app.logo.type');
          $logoValue = config('app.logo.value');
        @endphp
        <span class="logo-mini">
          @if($logoType === 'upload' && $logoValue)
            <img src="{{ url('storage/' . $logoValue) }}" alt="{{ config('app.name', 'Panel') }}" style="max-height:30px;vertical-align:middle;">
          @elseif($logoType === 'link' && $logoValue)
            <img src="{{ $logoValue }}" alt="{{ config('app.name', 'Panel') }}" style="max-height:30px;vertical-align:middle;">
          @else
            <img src="{{ asset('brand/luxodactyl-mark.png') }}" alt="{{ config('app.name', 'Panel') }}" style="max-height:30px;vertical-align:middle;">
          @endif
        </span>
        <span class="logo-lg">
          @if($logoType === 'upload' && $logoValue)
            <img src="{{ url('storage/' . $logoValue) }}" alt="" style="max-height:30px;vertical-align:middle;margin-right:6px;">
          @elseif($logoType === 'link' && $logoValue)
            <img src="{{ $logoValue }}" alt="" style="max-height:30px;vertical-align:middle;margin-right:6px;">
          @else
            <img src="{{ asset('brand/luxodactyl-mark.png') }}" alt="" style="max-height:30px;vertical-align:middle;margin-right:6px;">
          @endif
          <b>{{ config('app.name', 'Luxodactyl') }}</b>
        </span>
      </a>
      <nav class="navbar navbar-static-top">
        <a href="#" class="sidebar-toggle" data-toggle="push-menu" role="button">
          <span class="sr-only">Toggle navigation</span>
          <span class="icon-bar"></span>
          <span class="icon-bar"></span>
          <span class="icon-bar"></span>
        </a>
        <div class="navbar-custom-menu">
          <ul class="nav navbar-nav">
            <li class="user-menu">
              <a href="{{ route('account') }}">

                <span class="hidden-xs">{{ Auth::user()->name_first }} {{ Auth::user()->name_last }}</span>
              </a>
            </li>
            <li>
            <li><a href="{{ route('index') }}" data-toggle="tooltip" data-placement="bottom"
                title="Exit Admin Control"><i class="fa fa-server"></i></a></li>
            </li>
            <li>
            <li><a href="{{ route('auth.logout') }}" id="logoutButton" data-toggle="tooltip" data-placement="bottom"
                title="Logout"><i class="fa fa-sign-out"></i></a></li>
            </li>
          </ul>
        </div>
      </nav>
    </header>
    <aside class="main-sidebar">
      <section class="sidebar">
        <ul class="sidebar-menu">
          <li class="header">BASIC ADMINISTRATION</li>
          <li class="{{ Route::currentRouteName() !== 'admin.index' ?: 'active' }}">
            <a href="{{ route('admin.index') }}">
              <i class="bi bi-house-fill"></i> <span>Overview</span>
            </a>
          </li>
          <li class="{{ !starts_with(Route::currentRouteName(), 'admin.settings') ?: 'active' }}">
            <a href="{{ route('admin.settings')}}">
              <i class="bi bi-gear-fill"></i> <span>Settings</span>
            </a>
          </li>
          <li class="{{ !starts_with(Route::currentRouteName(), 'admin.api') ?: 'active' }}">
            <a href="{{ route('admin.api.index')}}">
              <i class="bi bi-globe"></i> <span>Application API</span>
            </a>
          </li>
          <li class="header">MANAGEMENT</li>
          <li class="{{ !starts_with(Route::currentRouteName(), 'admin.databases') ?: 'active' }}">
            <a href="{{ route('admin.databases') }}">
              <i class="bi bi-database-fill"></i> <span>Databases</span>
            </a>
          </li>
          <li class="{{ !starts_with(Route::currentRouteName(), 'admin.buckets') ?: 'active' }}">
            <a href="{{ route('admin.buckets') }}">
              <i class="bi bi-bucket-fill"></i> <span>S3 Buckets</span>
            </a>
          </li>
          <li class="{{ !starts_with(Route::currentRouteName(), 'admin.locations') ?: 'active' }}">
            <a href="{{ route('admin.locations') }}">
              <i class="bi bi-globe-americas"></i> <span>Locations</span>
            </a>
          </li>
          <li class="{{ !starts_with(Route::currentRouteName(), 'admin.nodes') ?: 'active' }}">
            <a href="{{ route('admin.nodes') }}">
              <i class="bi bi-hdd-fill"></i> <span>Nodes</span>
            </a>
          </li>
          <li class="{{ !starts_with(Route::currentRouteName(), 'admin.servers') ?: 'active' }}">
            <a href="{{ route('admin.servers') }}">
              <i class="bi bi-hdd-stack-fill"></i> <span>Servers</span>
            </a>
          </li>
          <li class="{{ !starts_with(Route::currentRouteName(), 'admin.users') ?: 'active' }}">
            <a href="{{ route('admin.users') }}">
              <i class="bi bi-people-fill"></i> <span>Users</span>
            </a>
          </li>
          <li class="header">SERVICE MANAGEMENT</li>
          <li class="{{ !starts_with(Route::currentRouteName(), 'admin.mounts') ?: 'active' }}">
            <a href="{{ route('admin.mounts') }}">
              <i class="bi bi-magic"></i> <span>Mounts</span>
            </a>
          </li>
          <li class="{{ !starts_with(Route::currentRouteName(), 'admin.nests') ?: 'active' }}">
            <a href="{{ route('admin.nests') }}">
              <i class="bi bi-egg-fill"></i> <span>Nests</span>
            </a>
          </li>
        </ul>
      </section>
    </aside>
    <div class="content-wrapper">
      <section class="content-header">
        @yield('content-header')
      </section>
      <section class="content">
        <div class="row">
          <div class="col-xs-12">
            @if (count($errors) > 0)
              <div class="alert alert-danger">
                There was an error validating the data provided.<br><br>
                <ul>
                  @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                  @endforeach
                </ul>
              </div>
            @endif
            @foreach (Alert::getMessages() as $type => $messages)
              @foreach ($messages as $message)
                <div class="alert alert-{{ $type }} alert-dismissable" role="alert">
                  {{ $message }}
                </div>
              @endforeach
            @endforeach
          </div>
        </div>
        @yield('content')
      </section>
    </div>
    <footer class="main-footer">
      <div class="pull-right small text-zinc" style="margin-right:10px;margin-top:-7px;">
        <strong><i class="fa fa-fw {{ $appIsGit ? 'fa-git-square' : 'fa-code-fork' }}"></i></strong>
        {{ $appVersion }}<br />
        <strong><i class="fa fa-fw fa-clock-o"></i></strong> {{ round(microtime(true) - LARAVEL_START, 3) }}s
      </div>
      Copyright &copy; 2015 - {{ date('Y') }} <a href="https://luxodactyl.dev">fernsehheft</a> and <a
        href="https://luxodactyl.dev">Luxodactyl</a>.
    </footer>
  </div>
  @section('footer-scripts')
  @viteReactRefresh
  <script src="/js/keyboard.polyfill.js" type="application/javascript"></script>
  <script>keyboardeventKeyPolyfill.polyfill();</script>

  {!! Theme::js('vendor/jquery/jquery.min.js?t={cache-version}') !!}
  {!! Theme::js('vendor/sweetalert/sweetalert.min.js?t={cache-version}') !!}
  {!! Theme::js('vendor/bootstrap/bootstrap.min.js?t={cache-version}') !!}
  {!! Theme::js('vendor/slimscroll/jquery.slimscroll.min.js?t={cache-version}') !!}
  {!! Theme::js('vendor/adminlte/app.min.js?t={cache-version}') !!}
  {!! Theme::js('vendor/bootstrap-notify/bootstrap-notify.min.js?t={cache-version}') !!}
  {!! Theme::js('vendor/select2/select2.full.min.js?t={cache-version}') !!}
  {!! Theme::js('js/admin/functions.js?t={cache-version}') !!}
  <script src="/js/autocomplete.js" type="application/javascript"></script>

  @if(Auth::user()->root_admin)
    <script>
      $('#logoutButton').on('click', function (event) {
        event.preventDefault();

        var that = this;
        swal({
          title: 'Do you want to log out?',
          type: 'warning',
          showCancelButton: true,
          confirmButtonColor: '#d9534f',
          cancelButtonColor: '#d33',
          confirmButtonText: 'Log out'
        }, function () {
          $.ajax({
            type: 'POST',
            url: '{{ route('auth.logout') }}',
            data: {
              _token: '{{ csrf_token() }}'
            }, complete: function () {
              window.location.href = '{{route('auth.login')}}';
            }
          });
        });
      });
    </script>
  @endif

  <script>
    $(function () {
      $('[data-toggle="tooltip"]').tooltip();
    })
  </script>
  @show
</body>

</html>
