import { useCallback, useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import type { Server } from '@/api/server/getServer';
import getServerResourceUsage, { type ServerPowerState, type ServerStats } from '@/api/server/getServerResourceUsage';
import { bytesToString, ip, mbToBytes } from '@/lib/formatters';
import { cn } from '@/lib/utils';

type Tone = 'green' | 'red' | 'blue' | 'yellow' | 'gray';

const TONE_CLASSES: Record<Tone, { dot: string; glow: string; text: string; bg: string }> = {
    green: {
        dot: 'bg-[#43C760]',
        glow: 'shadow-[0_0_10px_1px_rgba(67,199,96,0.6)]',
        text: 'text-[#8fe3a4]',
        bg: 'bg-[#43C760]/10',
    },
    red: {
        dot: 'bg-[#C74343]',
        glow: 'shadow-[0_0_10px_1px_rgba(199,67,67,0.6)]',
        text: 'text-[#e69a9a]',
        bg: 'bg-[#C74343]/10',
    },
    blue: {
        dot: 'bg-[#4381c7]',
        glow: 'shadow-[0_0_10px_1px_rgba(67,129,199,0.6)]',
        text: 'text-[#9ac2ec]',
        bg: 'bg-[#4381c7]/10',
    },
    yellow: {
        dot: 'bg-[#c7aa43]',
        glow: 'shadow-[0_0_10px_1px_rgba(199,170,67,0.6)]',
        text: 'text-[#e6cf8f]',
        bg: 'bg-[#c7aa43]/10',
    },
    gray: {
        dot: 'bg-white/30',
        glow: '',
        text: 'text-white/50',
        bg: 'bg-white/5',
    },
};

interface StatusMeta {
    label: string;
    tone: Tone;
}

const getStatusMeta = (
    server: Server,
    stats: ServerStats | null,
    isSuspended: boolean,
    isInstalling: boolean,
): StatusMeta => {
    if (isSuspended) {
        return { label: server.status === 'suspended' ? 'Suspended' : 'Connection Error', tone: 'red' };
    }
    if (server.isTransferring) {
        return { label: 'Transferring', tone: 'blue' };
    }
    if (isInstalling) {
        return { label: 'Installing', tone: 'blue' };
    }
    if (server.status === 'restoring_backup') {
        return { label: 'Restoring Backup', tone: 'blue' };
    }
    if (!stats) {
        return { label: 'Connecting', tone: 'gray' };
    }

    const STATUS_META: Record<ServerPowerState, StatusMeta> = {
        running: { label: 'Running', tone: 'green' },
        starting: { label: 'Starting', tone: 'yellow' },
        stopping: { label: 'Stopping', tone: 'yellow' },
        offline: { label: 'Offline', tone: 'red' },
        installing: { label: 'Installing', tone: 'blue' },
    };

    return STATUS_META[stats.status] || STATUS_META.offline;
};

const StatusPill = ({ meta }: { meta: StatusMeta }) => {
    const tone = TONE_CLASSES[meta.tone];

    return (
        <div
            className={cn(
                'flex items-center gap-1.5 w-fit whitespace-nowrap rounded-full px-2.5 py-1 text-xs font-medium',
                tone.bg,
                tone.text,
            )}
        >
            <span className={cn('size-1.5 rounded-full', tone.dot, tone.glow)} />
            {meta.label}
        </div>
    );
};

const UsageMeter = ({
    label,
    valueText,
    percent,
    alarm,
    className,
}: {
    label: string;
    valueText: string;
    percent: number | null;
    alarm: boolean;
    className?: string;
}) => (
    <div className={cn('flex flex-1 flex-col gap-1.5 min-w-[6rem]', className)}>
        <div className='flex items-center justify-between gap-3 text-[11px] font-semibold text-white/35'>
            <span className='uppercase tracking-wide'>{label}</span>
            <span className={alarm ? 'text-red-300' : 'text-white/70'}>{valueText}</span>
        </div>
        <div className='h-1.5 rounded-full bg-white/10 overflow-hidden'>
            {percent !== null && (
                <div
                    className={cn(
                        'h-full rounded-full transition-all duration-500',
                        alarm ? 'bg-red-400' : 'bg-brand-400',
                    )}
                    style={{ width: `${percent}%` }}
                />
            )}
        </div>
    </div>
);

const ServerRow = ({
    server,
    layout = 'list',
    className,
}: {
    server: Server;
    layout?: 'list' | 'grid';
    className?: string;
}) => {
    const [isSuspended, setIsSuspended] = useState(server.status === 'suspended');
    const [isInstalling, setIsInstalling] = useState(server.status === 'installing');
    const [stats, setStats] = useState<ServerStats | null>(null);

    // Memoized so its identity is stable across renders. Using an inline function
    // here as a useEffect dependency makes the polling effect re-fire every render
    // -> setStats -> re-render -> re-fire, i.e. a setState-in-useEffect infinite
    // loop ("Maximum update depth exceeded").
    const getStats = useCallback(() => {
        getServerResourceUsage(server.uuid)
            .then((data) => setStats(data))
            .catch((error) => console.error(error));
    }, [server.uuid]);

    useEffect(() => {
        setIsSuspended(stats?.isSuspended || server.status === 'suspended');
    }, [stats?.isSuspended, server.status]);

    useEffect(() => {
        setIsInstalling(stats?.isInstalling || server.status === 'installing');
    }, [stats?.isInstalling, server.status]);

    useEffect(() => {
        // Don't waste a HTTP request if there is nothing important to show to the user because
        // the server is suspended.
        if (isSuspended) return;

        getStats();
        const interval = setInterval(getStats, 30000);

        return () => clearInterval(interval);
    }, [isSuspended, getStats]);

    const showMeters = stats && !isSuspended && !isInstalling;

    const cpuPercent =
        stats && server.limits.cpu > 0 ? Math.min(100, (stats.cpuUsagePercent / server.limits.cpu) * 100) : null;
    const cpuAlarm = server.limits.cpu > 0 && (stats?.cpuUsagePercent ?? 0) / server.limits.cpu >= 0.9;

    const memoryLimitBytes = mbToBytes(server.limits.memory);
    const memoryPercent =
        stats && server.limits.memory > 0 ? Math.min(100, (stats.memoryUsageInBytes / memoryLimitBytes) * 100) : null;
    const memoryAlarm = server.limits.memory > 0 && (stats?.memoryUsageInBytes ?? 0) / memoryLimitBytes >= 0.9;

    const diskLimitBytes = mbToBytes(server.limits.disk);
    const diskPercent =
        stats && server.limits.disk > 0 ? Math.min(100, (stats.diskUsageInBytes / diskLimitBytes) * 100) : null;
    const diskAlarm = server.limits.disk > 0 && (stats?.diskUsageInBytes ?? 0) / diskLimitBytes >= 0.9;

    const statusMeta = getStatusMeta(server, stats, isSuspended, isInstalling);

    const address = server.allocations
        .filter((alloc) => alloc.isDefault)
        .map((allocation) => `${allocation.alias || ip(allocation.ip)}:${allocation.port}`)
        .join(', ');

    const meters = (
        <div className={cn('flex gap-6', layout === 'grid' ? 'w-full' : 'w-full sm:w-auto')}>
            <UsageMeter
                label='CPU'
                valueText={showMeters ? `${stats.cpuUsagePercent.toFixed(1)}%` : '--'}
                percent={showMeters ? cpuPercent : null}
                alarm={!!showMeters && cpuAlarm}
            />
            <UsageMeter
                label='RAM'
                valueText={showMeters ? bytesToString(stats.memoryUsageInBytes, 0) : '--'}
                percent={showMeters ? memoryPercent : null}
                alarm={!!showMeters && memoryAlarm}
            />
            <UsageMeter
                label='Disk'
                valueText={showMeters ? bytesToString(stats.diskUsageInBytes, 0) : '--'}
                percent={showMeters ? diskPercent : null}
                alarm={!!showMeters && diskAlarm}
            />
        </div>
    );

    return (
        <Link
            to={`/server/${server.id}`}
            className={cn(
                'group flex gap-4 rounded-xl border border-mocha-400 bg-mocha-500 p-5 transition-colors duration-200 hover:border-mocha-300 hover:bg-mocha-400/60',
                layout === 'grid' ? 'flex-col' : 'flex-col sm:flex-row sm:items-center',
                className,
            )}
        >
            <div className='flex min-w-0 flex-1 items-center justify-between gap-3'>
                <div className='min-w-0'>
                    <p className='truncate text-lg font-bold tracking-tight'>{server.name}</p>
                    {address && <p className='truncate text-sm text-white/40'>{address}</p>}
                </div>
                {layout === 'grid' && <StatusPill meta={statusMeta} />}
            </div>

            {layout === 'list' && (
                <div className='flex shrink-0 items-center gap-4'>
                    <StatusPill meta={statusMeta} />
                    {showMeters ? (
                        <div className='hidden sm:block'>{meters}</div>
                    ) : (
                        !isSuspended &&
                        !isInstalling &&
                        !server.isTransferring && (
                            <div className='hidden text-xs text-white/30 sm:block'>Sit tight!</div>
                        )
                    )}
                </div>
            )}

            {layout === 'grid' && showMeters && meters}
        </Link>
    );
};

export default ServerRow;
