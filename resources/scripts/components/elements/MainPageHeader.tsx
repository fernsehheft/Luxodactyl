import type { JSX } from 'react';

import { cn } from '@/lib/utils';

interface MainPageHeaderProps {
    children?: React.ReactNode;
    direction?: 'row' | 'column';
    titleChildren?: JSX.Element;
    title?: string;
    headChildren?: JSX.Element;
}

export const MainPageHeader: React.FC<MainPageHeaderProps> = ({
    children,
    headChildren,
    titleChildren,
    title,
    direction = 'row',
}) => {
    return (
        <div
            className={cn(
                'flex',
                direction === 'row' ? 'items-center flex-col md:flex-row' : 'items-start flex-col',
                'justify-between',
                'mb-6 gap-4 select-none',
            )}
        >
            <div className='flex items-center gap-3 flex-wrap min-w-0'>
                <h1 className='text-2xl font-bold tracking-tight'>{title}</h1>
                {headChildren}
                {titleChildren}
            </div>
            {children}
        </div>
    );
};
