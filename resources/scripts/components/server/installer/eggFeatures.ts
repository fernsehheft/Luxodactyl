import type { MarketplaceType } from '@/api/server/marketplace';

/**
 * The Minecraft loaders the installer knows about, split by whether they load
 * mods (into `mods/`) or plugins (into `plugins/`). Egg features such as
 * "mod/fabric" or "plugin/paper" are matched against these lists.
 */
export const MOD_LOADERS = ['fabric', 'forge', 'quilt', 'neoforge'] as const;
export const PLUGIN_LOADERS = ['paper', 'purpur', 'spigot', 'bukkit', 'pufferfish', 'folia'] as const;

export type LoaderName = (typeof MOD_LOADERS)[number] | (typeof PLUGIN_LOADERS)[number];

const normalize = (value: string): string =>
    value
        .toLowerCase()
        .trim()
        .replace(/[-_\s]/g, '');

/**
 * Normalize raw loader identifiers from egg features onto the canonical names
 * used by marketplace providers (e.g. "neo_forge" -> "neoforge").
 */
const normalizeLoader = (raw: string): string => {
    const n = normalize(raw);
    if (n === 'neoforge' || n === 'neofrge') return 'neoforge';
    return n;
};

/**
 * Extract the loaders a server supports for the given content type from its egg
 * features.
 *
 * @param features e.g. ["eula", "java_version", "mod/fabric", "mclogs"]
 */
export const loadersFor = (features: string[], type: MarketplaceType): string[] => {
    const known = type === 'mod' ? MOD_LOADERS : PLUGIN_LOADERS;
    const found: string[] = [];

    for (const feature of features) {
        const normalized = normalize(feature);
        const prefix = `${type}/`;
        if (!normalized.startsWith(prefix)) continue;

        const loader = normalizeLoader(normalized.slice(prefix.length));
        if (known.includes(loader as never) && !found.includes(loader)) {
            found.push(loader);
        }
    }

    return found;
};

/**
 * Whether the server's egg can install the given content type.
 */
export const supportsType = (features: string[], type: MarketplaceType): boolean => {
    const prefix = `${type}/`;
    return features.some((feature) => normalize(feature).startsWith(prefix));
};

/**
 * Whether this looks like any Minecraft server capable of using mods/plugins.
 */
export const isMinecraftCapable = (features: string[]): boolean =>
    supportsType(features, 'mod') || supportsType(features, 'plugin');

/**
 * Container-relative folder a content type installs into.
 */
export const destinationFolder = (type: MarketplaceType): string => (type === 'plugin' ? 'plugins' : 'mods');
