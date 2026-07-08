<p align="center">
<a aria-label="Read the Luxodactyl introduction blog post" href="https://blueprint.zip/blog/introducing-luxodactyl?utm_source=githubreadme&utm_medium=readme&utm_campaign=LUXODACTYL&utm_id=LUXODACTYL"><img alt="" src=".github/banner_v6.jpg"></a>
</p>
<p align="center">
    <a href="https://discord.gg/sK686yHdaK">
        <img src="https://shieldcn.dev/badge/Discord-Join%20the%20community-5865F2.svg?logo=discord" alt="Join the Discord">
    </a>
    <a href="https://blueprint.zip/blog/introducing-luxodactyl">
        <img src="https://shieldcn.dev/badge/Blog-Read%20the%20announcement-0ea5e9.svg?logo=readme" alt="Read the blog post">
    </a>
</p>
<br/>
<h1 align="center">Luxodactyl</h1>
<p align="center">
    <a href="https://github.com/BlueprintFramework/luxodactyl/actions/workflows/dev-build.yaml">
        <img src="https://shieldcn.dev/badge/Build-Passing-success.svg?logo=githubactions" alt="Build">
    </a>
    <img src="https://shieldcn.dev/badge/Formatter-Biome-60a5fa.svg?logo=biome" alt="Formatted with Biome">
    <img src="https://shieldcn.dev/badge/Linter-Biome-60a5fa.svg?logo=biome" alt="Linted with Biome">
</p>

<br/>

Luxodactyl is a modern, performance-focused game server management panel forked from Pterodactyl. It delivers smaller bundles, faster builds, and an accessible, reimagined interface.

- Not compatible with Blueprint extensions — this is an all-in-one solution.
- Pre-release software. Some UI elements may appear broken and bugs may exist.
- Logo customization is experimental and subject to change.
- Read the docs at [luxodactyl.dev](https://luxodactyl.dev/docs/luxodactyl) before installing.

![Dashboard Image](./.github/server_menu.jpeg)

Built by the maintainer of the original Pyrodactyl project and funded by Blueprint.

## Automated installation (production)

Install the panel and/or Wings on a fresh **Ubuntu 22.04/24.04** or **Debian 11/12** server with a single command. The wizard asks for the database, domain, admin account, SSL and firewall — just like the pterodactyl-installer.

```bash
bash <(curl -sSL https://raw.githubusercontent.com/fernsehheft/Luxodactyl/main/install.sh)
```

Run it as **root** (`sudo -i`). The installer is modular:

```
install.sh                      # bootstrap / entry point
installer/lib/lib.sh            # shared helpers (logging, OS detection, input, db, firewall)
installer/installers/panel.sh   # panel install logic
installer/installers/wings.sh   # wings install logic
installer/ui/panel.sh           # panel wizard (questions)
installer/ui/wings.sh           # wings wizard
installer/ui/ssl.sh             # Let's Encrypt only
installer/ui/uninstall.sh       # uninstall panel/wings
```

Logs are written to `/var/log/luxodactyl-installer.log`.

## Quick start (Docker / development)

```bash
git clone https://github.com/BlueprintFramework/luxodactyl.git
cd luxodactyl
cp .env.example .env
docker compose up -d
```

See the [Installation Guide](https://luxodactyl.dev/docs/luxodactyl/installation) and [Local Development Guide](https://luxodactyl.dev/docs/luxodactyl/local-development) for detailed instructions. Windows is supported for local development only.

![Dashboard Image](./.github/dashboard.jpeg)

## License

Luxodactyl is open-source software licensed under the **Apache License 2.0**.

You are free to use, modify, and redistribute Luxodactyl under the terms of the license. A copy of the full license text is available in the [LICENSE](./LICENSE) file included in this repository.

### Copyright & Attribution

Luxodactyl is built upon the work of previous open-source projects and their contributors:

- **Pterodactyl®**: Copyright © 2015–2022 Dane Everitt and contributors.
- **Pyrodactyl™**: Copyright © 2023–2025 Pyro Inc. and contributors.
- **Pyrodactyl™**: Copyright © 2025–2026 Pyrodactyl-oss and contributors.
- **Luxodactyl**: Copyright © 2026–present Naterfute, Blueprint Framework, and contributors.

All original copyright notices, license notices, and attributions must remain intact when redistributing this software.

Unless explicitly stated otherwise, all source code within this repository is licensed under the **Apache License 2.0**.

## Support

Help Luxodactyl grow by supporting the project:

- [Donate on Ko-fi](https://ko-fi.com/naterfute): support the maintainer.
- [Donate to Blueprint Framework](https://bpfw.io/donate): support the nonprofit funding Luxodactyl.
- [Join the Discord](https://discord.gg/sK686yHdaK): chat with the community and get support.
- Star the repository and share it with others: it helps more people discover Luxodactyl.

<br>

<p align="center">
    <a href="https://github.com/BlueprintFramework/luxodactyl/graphs/contributors">
        <img src="https://shieldcn.dev/contributors/BlueprintFramework/luxodactyl.svg?preset=grid&names=true&bots=true&titleAlign=center&mode=dark&watermark=true" alt="BlueprintFramework/luxodactyl contributors">
    </a>
</p>
