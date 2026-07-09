import { Route, Routes } from 'react-router-dom';

import ForgotPasswordContainer from '@/components/auth/ForgotPasswordContainer';
import LoginCheckpointContainer from '@/components/auth/LoginCheckpointContainer';
import LoginContainer from '@/components/auth/LoginContainer';
import ResetPasswordContainer from '@/components/auth/ResetPasswordContainer';
import Logo from '@/components/elements/HydroLogo';
import { NotFound } from '@/components/elements/ScreenBlock';

const AuthenticationRouter = () => {
    return (
        <div
            className={
                'absolute w-full h-full flex justify-center items-center rounded-md [--page-padding:--spacing(8)]'
            }
        >
            <div
                style={{
                    backgroundImage: 'url(/assets/auth-noise.png)',
                    backgroundSize: '1920px 1080px',
                    backgroundRepeat: 'repeat',
                    backgroundPosition: '0 0',
                }}
                className='pointer-events-none fixed inset-0 z-1 opacity-[0.4]'
            ></div>
            <div className='flex size-full'>
                <div className='w-full max-w-4xl z-2 flex items-center bg-bg-lowered align-middle px-[calc(var(--page-padding)*3)]'>
                    <Routes>
                        <Route path='login' element={<LoginContainer />} />
                        <Route path='login/checkpoint/*' element={<LoginCheckpointContainer />} />
                        <Route path='password' element={<ForgotPasswordContainer />} />
                        <Route path='password/reset/:token' element={<ResetPasswordContainer />} />
                        <Route path='*' element={<NotFound />} />
                    </Routes>
                </div>
                <div className='w-full relative overflow-hidden'>
                    <div className='flex items-center gap-4 h-6 absolute right-(--page-padding) top-(--page-padding) text-lg z-10'>
                        <Logo className='h-full w-full flex inset-0' />
                        <div className='border-l border-gray-200 h-full' />
                        Games
                    </div>

                    {/* Gradients */}
                    <div className='opacity-50'>
                        <div className='absolute inset-0 bg-gradient-to-tr from-transparent via-brand-400/5 to-brand-600/10' />
                        <div className='absolute inset-0 bg-gradient-to-tr to-transparent via-brand-400/5 from-brand-600/10' />
                        <div className='absolute top-0 left-0 w-full h-32 bg-gradient-to-b from-brand-500/13 to-transparent' />
                    </div>

                    {/* Soft glow accent behind the hero copy */}
                    <div
                        className='pointer-events-none absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] rounded-full opacity-20 blur-3xl'
                        style={{ background: 'var(--color-brand-grad)' }}
                    />

                    <div className='relative z-2 flex flex-col justify-center h-full max-w-md mx-auto px-(--page-padding) gap-4'>
                        <span className='text-sm font-medium tracking-wide uppercase text-secondary'>
                            Game server management
                        </span>
                        <h1 className='text-4xl font-medium leading-tight text-primary'>
                            Your servers,
                            <br />
                            always within reach.
                        </h1>
                        <p className='text-secondary text-base'>
                            Sign in to start, stop, and configure your servers from one place.
                        </p>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default AuthenticationRouter;
