import http, {
    type FractalResponseData,
    getPaginationSet,
    type PaginatedResult,
    withQueryBuilderParams,
} from '@/api/http';

export interface AdminUser {
    id: number;
    externalId: string | null;
    uuid: string;
    username: string;
    email: string;
    firstName: string;
    lastName: string;
    rootAdmin: boolean;
    use2fa: boolean;
    createdAt: Date;
}

export const rawDataToAdminUser = ({ attributes }: FractalResponseData): AdminUser => ({
    id: attributes.id as number,
    externalId: (attributes.external_id as string | null) ?? null,
    uuid: attributes.uuid as string,
    username: attributes.username as string,
    email: attributes.email as string,
    firstName: attributes.first_name as string,
    lastName: attributes.last_name as string,
    rootAdmin: Boolean(attributes.root_admin),
    use2fa: Boolean(attributes['2fa']),
    createdAt: new Date(attributes.created_at as string),
});

interface Params {
    page?: number;
    query?: string;
}

// Talks directly to the same Application API the panel has always exposed
// (/api/application/*) rather than a separate admin-only endpoint. Root admin
// web sessions are already authorized against it (see
// ApplicationApiRequest::authorize(), which treats a Sanctum session token as
// fully trusted) so no new backend surface is needed for this.
export default ({ page, query }: Params = {}): Promise<PaginatedResult<AdminUser>> =>
    new Promise((resolve, reject) => {
        http.get('/api/application/users', {
            params: withQueryBuilderParams({
                page,
                filters: query ? { email: query } : undefined,
            }),
        })
            .then(({ data }) =>
                resolve({
                    items: (data.data || []).map(rawDataToAdminUser),
                    pagination: getPaginationSet(data.meta.pagination),
                }),
            )
            .catch(reject);
    });
