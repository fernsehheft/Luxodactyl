// million-ignore
const Logo = ({ className }: { className?: string } = {}) => {
    const customLogo = (window as Record<string, unknown>).SiteConfiguration?.logo as string | undefined;

    return (
        <img
            src={customLogo || '/brand/luxodactyl-mark.png'}
            alt='Logo'
            className={className || 'flex h-full w-full shrink-0 object-contain'}
            style={{ maxWidth: '100%', maxHeight: '100%' }}
        />
    );
};

export default Logo;

// vim: nowrap
