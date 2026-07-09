import { type FieldProps, Field as FormikField } from 'formik';
import { forwardRef, type ReactNode } from 'react';

import { cn } from '@/lib/utils';

interface OwnProps {
    name: string;
    label?: string;
    description?: string;
    validate?: (value: unknown) => undefined | string | Promise<unknown>;
    /** Optional icon rendered inside the input, on the left. */
    icon?: ReactNode;
    /** Optional element (e.g. a show/hide password toggle) rendered inside the input, on the right. */
    rightElement?: ReactNode;
}

type Props = OwnProps & Omit<React.InputHTMLAttributes<HTMLInputElement>, 'name'>;

const Field = forwardRef<HTMLInputElement, Props>(
    ({ id, name = false, label, description, validate, icon, rightElement, ...props }, ref) => (
        <FormikField innerRef={ref} name={name} validate={validate}>
            {({ field, form: { errors, touched } }: FieldProps) => (
                <div className='flex flex-col gap-2'>
                    {label && (
                        <label className='text-sm text-[#ffffff77]' htmlFor={id}>
                            {label}
                        </label>
                    )}
                    <div className='relative'>
                        {icon && (
                            <span className='pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-[#ffffff55]'>
                                {icon}
                            </span>
                        )}
                        <input
                            className={cn(
                                'w-full px-4 py-2 rounded-lg outline-hidden bg-[#ffffff17] text-sm',
                                icon && 'pl-10',
                                rightElement && 'pr-10',
                            )}
                            id={id}
                            {...field}
                            {...props}
                        />
                        {rightElement && (
                            <span className='absolute right-3.5 top-1/2 -translate-y-1/2'>{rightElement}</span>
                        )}
                    </div>
                    {touched[field.name] && errors[field.name] ? (
                        <p className={'text-sm font-bold text-[#d36666]'}>
                            {(errors[field.name] as string).charAt(0).toUpperCase() +
                                (errors[field.name] as string).slice(1)}
                        </p>
                    ) : description ? (
                        <p className={'text-sm font-bold'}>{description}</p>
                    ) : null}
                </div>
            )}
        </FormikField>
    ),
);
Field.displayName = 'Field';

export default Field;
