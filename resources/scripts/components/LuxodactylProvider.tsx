// Provides necessary information for components to function properly
// million-ignore
const LuxodactylProvider = ({ children }) => {
    return (
        <div
            data-luxodactyl-luxodactylprovider=''
            data-luxodactyl-luxodactyl-version={import.meta.env.VITE_LUXODACTYL_VERSION}
            data-luxodactyl-luxodactyl-build={import.meta.env.VITE_LUXODACTYL_BUILD_NUMBER}
            data-luxodactyl-commit-hash={import.meta.env.VITE_COMMIT_HASH}
            style={{
                display: 'contents',
            }}
        >
            {children}
        </div>
    );
};

export default LuxodactylProvider;
