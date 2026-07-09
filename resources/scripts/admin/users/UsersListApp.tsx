import { Person } from '@gravity-ui/icons';
import { useEffect, useState } from 'react';
import getAdminUsers, { type AdminUser } from '@/api/admin/users';

const UsersListApp = () => {
    const [users, setUsers] = useState<AdminUser[] | null>(null);
    const [total, setTotal] = useState(0);
    const [page, setPage] = useState(1);
    const [totalPages, setTotalPages] = useState(1);
    const [query, setQuery] = useState('');
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        let cancelled = false;
        setError(null);

        getAdminUsers({ page, query: query || undefined })
            .then((result) => {
                if (cancelled) return;
                setUsers(result.items);
                setTotal(result.pagination.total);
                setTotalPages(result.pagination.totalPages);
            })
            .catch((err) => {
                if (cancelled) return;
                console.error(err);
                setError('Could not load users. Check the console for details.');
            });

        return () => {
            cancelled = true;
        };
    }, [page, query]);

    return (
        <div className='flex flex-col gap-4'>
            <div className='flex flex-col sm:flex-row sm:items-center justify-between gap-3'>
                <div>
                    <h2 className='text-xl font-bold tracking-tight text-primary'>All Users</h2>
                    <p className='text-sm text-secondary'>{users ? `${total} total` : 'Loading…'}</p>
                </div>
                <input
                    type='text'
                    value={query}
                    onChange={(e) => {
                        setPage(1);
                        setQuery(e.target.value);
                    }}
                    placeholder='Search by email…'
                    className='px-3 py-2 rounded-lg bg-mocha-400 border border-mocha-300 text-primary text-sm placeholder:text-secondary/60 focus:outline-none focus:border-brand focus:ring-2 focus:ring-brand/20 w-full sm:w-64'
                />
            </div>

            {error && (
                <div className='p-3 rounded-lg bg-red-500/10 border border-red-500/30 text-red-300 text-sm'>
                    {error}
                </div>
            )}

            <div className='rounded-2xl border border-mocha-300 overflow-hidden'>
                <table className='w-full text-sm'>
                    <thead>
                        <tr className='bg-mocha-500 text-left text-secondary uppercase text-xs tracking-wide'>
                            <th className='px-4 py-3 font-semibold'>User</th>
                            <th className='px-4 py-3 font-semibold'>Username</th>
                            <th className='px-4 py-3 font-semibold text-center'>2FA</th>
                            <th className='px-4 py-3 font-semibold'>Joined</th>
                        </tr>
                    </thead>
                    <tbody>
                        {!users ? (
                            <tr>
                                <td colSpan={4} className='px-4 py-8 text-center text-secondary'>
                                    Loading users…
                                </td>
                            </tr>
                        ) : users.length === 0 ? (
                            <tr>
                                <td colSpan={4} className='px-4 py-8 text-center text-secondary'>
                                    No users found.
                                </td>
                            </tr>
                        ) : (
                            users.map((user) => (
                                <tr
                                    key={user.id}
                                    className='border-t border-mocha-300 hover:bg-mocha-400 transition-colors cursor-pointer'
                                    onClick={() => {
                                        window.location.href = `/admin/users/view/${user.id}`;
                                    }}
                                >
                                    <td className='px-4 py-3'>
                                        <div className='flex items-center gap-3'>
                                            <div className='size-8 rounded-full bg-mocha-300 flex items-center justify-center shrink-0'>
                                                <Person
                                                    width={16}
                                                    height={16}
                                                    fill='currentColor'
                                                    className='text-secondary'
                                                />
                                            </div>
                                            <div className='min-w-0'>
                                                <div className='flex items-center gap-1.5 text-primary font-medium truncate'>
                                                    {user.email}
                                                    {user.rootAdmin && (
                                                        <span title='Root Administrator' className='text-brand text-xs'>
                                                            ★
                                                        </span>
                                                    )}
                                                </div>
                                                <div className='text-xs text-secondary'>#{user.id}</div>
                                            </div>
                                        </div>
                                    </td>
                                    <td className='px-4 py-3 text-primary'>{user.username}</td>
                                    <td className='px-4 py-3 text-center'>
                                        <span
                                            className={
                                                user.use2fa
                                                    ? 'inline-block px-2 py-0.5 rounded-full text-xs font-medium bg-green-500/15 text-green-300 border border-green-500/30'
                                                    : 'inline-block px-2 py-0.5 rounded-full text-xs font-medium bg-mocha-300 text-secondary border border-mocha-200'
                                            }
                                        >
                                            {user.use2fa ? 'Enabled' : 'Disabled'}
                                        </span>
                                    </td>
                                    <td className='px-4 py-3 text-secondary'>{user.createdAt.toLocaleDateString()}</td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>

            {totalPages > 1 && (
                <div className='flex items-center justify-center gap-2'>
                    <button
                        type='button'
                        disabled={page <= 1}
                        onClick={() => setPage((p) => p - 1)}
                        className='px-3 py-1.5 rounded-lg bg-mocha-300 border border-mocha-200 text-primary text-sm disabled:opacity-40 disabled:cursor-not-allowed hover:bg-mocha-200 transition-colors'
                    >
                        Previous
                    </button>
                    <span className='text-sm text-secondary'>
                        Page {page} of {totalPages}
                    </span>
                    <button
                        type='button'
                        disabled={page >= totalPages}
                        onClick={() => setPage((p) => p + 1)}
                        className='px-3 py-1.5 rounded-lg bg-mocha-300 border border-mocha-200 text-primary text-sm disabled:opacity-40 disabled:cursor-not-allowed hover:bg-mocha-200 transition-colors'
                    >
                        Next
                    </button>
                </div>
            )}
        </div>
    );
};

export default UsersListApp;
