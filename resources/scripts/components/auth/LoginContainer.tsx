import { Eye, EyeSlash, Lock, Person } from '@gravity-ui/icons';
import type { FormikHelpers } from 'formik';
import { Formik } from 'formik';
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { object, string } from 'yup';
import login from '@/api/auth/login';
import LoginFormContainer, { TitleSection } from '@/components/auth/LoginFormContainer';
import Button from '@/components/elements/Button';
import Captcha, { getCaptchaResponse } from '@/components/elements/Captcha';
import Field from '@/components/elements/Field';

import CaptchaManager from '@/lib/captcha';

import useFlash from '@/plugins/useFlash';

import SecondaryLink from '../ui/secondary-link';

interface Values {
    user: string;
    password: string;
}

interface ErrorResponse {
    response: string;
    message: string;
    detail: string;
    code: string;
}

function LoginContainer() {
    const { clearFlashes, clearAndAddHttpError } = useFlash();
    const navigate = useNavigate();
    const [showPassword, setShowPassword] = useState(false);

    const onSubmit = (values: Values, { setSubmitting }: FormikHelpers<Values>) => {
        // clearFlashes();

        let loginData: Values = values;
        if (CaptchaManager.isEnabled()) {
            const captchaResponse = getCaptchaResponse();
            const fieldName = CaptchaManager.getProviderInstance().getResponseFieldName();

            if (fieldName) {
                if (captchaResponse) {
                    loginData = { ...values, [fieldName]: captchaResponse };
                } else {
                    console.error('Captcha enabled but no response available');
                    clearAndAddHttpError({
                        error: new Error('Please complete the captcha verification.'),
                    });
                    setSubmitting(false);
                    return;
                }
            }
        } else {
            // No captcha required
        }

        login(loginData)
            .then((response) => {
                if (response.complete) {
                    clearFlashes();
                    window.location.href = response.intended || '/';
                    return;
                }
                navigate('/auth/login/checkpoint', {
                    state: { token: response.confirmationToken },
                });
            })
            .catch((error: ErrorResponse) => {
                setSubmitting(false);

                if (error.code === 'InvalidCredentials') {
                    clearAndAddHttpError({
                        error: new Error('Invalid username or password. Please try again.'),
                    });
                } else if (error.code === 'DisplayException') {
                    clearAndAddHttpError({
                        error: new Error(error.detail || error.message),
                    });
                } else {
                    clearAndAddHttpError({ error });
                }
            });
    };

    return (
        <Formik
            onSubmit={onSubmit}
            initialValues={{ user: '', password: '' }}
            validationSchema={object().shape({
                user: string().required('A username or email must be provided.'),
                password: string().required('Please enter your account password.'),
            })}
        >
            {({ isSubmitting }) => (
                <LoginFormContainer className={`flex flex-col gap-6`}>
                    <TitleSection title='Welcome back' subtitle='Sign in to manage your servers' />

                    <div className=''>
                        <Field
                            id='user'
                            type={'text'}
                            label={'Username or Email'}
                            name={'user'}
                            disabled={isSubmitting}
                            autoComplete='username'
                            autoFocus
                            icon={<Person width={16} height={16} fill='currentColor' />}
                        />
                    </div>

                    <div className={`relative`}>
                        <Field
                            id='password'
                            type={showPassword ? 'text' : 'password'}
                            label={'Password'}
                            name={'password'}
                            disabled={isSubmitting}
                            autoComplete='current-password'
                            icon={<Lock width={16} height={16} fill='currentColor' />}
                            rightElement={
                                <button
                                    type='button'
                                    tabIndex={-1}
                                    onClick={() => setShowPassword((s) => !s)}
                                    className='pointer-events-auto flex items-center text-[#ffffff55] hover:text-white/80 transition-colors'
                                    aria-label={showPassword ? 'Hide password' : 'Show password'}
                                >
                                    {showPassword ? (
                                        <EyeSlash width={16} height={16} fill='currentColor' />
                                    ) : (
                                        <Eye width={16} height={16} fill='currentColor' />
                                    )}
                                </button>
                            }
                        />
                    </div>

                    <div className='flex justify-end -mt-2'>
                        <SecondaryLink to='/auth/password'>Forgot your password?</SecondaryLink>
                    </div>

                    <Captcha
                        className='-mt-2'
                        onError={(error) => {
                            console.error('Captcha error:', error);
                            clearAndAddHttpError({
                                error: new Error('Captcha verification failed. Please try again.'),
                            });
                        }}
                    />

                    <Button
                        className={`w-full rounded-lg p-2.5 px-4 text-black font-medium hover:cursor-pointer hover:opacity-90 active:scale-[0.99] transition-all duration-150 ease-in-out`}
                        style={{ background: 'var(--color-brand-grad)' }}
                        type={'submit'}
                        size={'xlarge'}
                        isLoading={isSubmitting}
                        disabled={isSubmitting}
                    >
                        Sign in
                    </Button>
                </LoginFormContainer>
            )}
        </Formik>
    );
}

export default LoginContainer;
