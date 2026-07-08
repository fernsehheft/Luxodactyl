/// <reference types="vite/client" />

interface ImportMetaEnv {
    readonly VITE_LUXODACTYL_VERSION: string;
    readonly VITE_COMMIT_HASH: string;
    readonly VITE_BRANCH_NAME: string;
    readonly VITE_LUXODACTYL_BUILD_NUMBER: string;
}

interface ImportMeta {
    readonly env: ImportMetaEnv;
}
