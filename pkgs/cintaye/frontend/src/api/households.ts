import { api } from './client'
import type { Household, User } from '../types'

export const householdsApi = {
  mine: () => api.get<Household[]>('/api/households/mine'),

  create: (name: string) => api.post<Household>('/api/households', { name }),

  rename: (id: number, name: string) =>
    api.patch<{ id: number; name: string }>(`/api/households/${id}`, { name }),

  members: (id: number) => api.get<User[]>(`/api/households/${id}/members`),

  generateInvite: (id: number) =>
    api.post<{ code: string; expires_at: string }>(`/api/households/${id}/invite`),

  join: (code: string) => api.post<Household>('/api/households/join', { code }),

  inviteInfo: (code: string) =>
    api.get<{ household_name: string }>(`/api/invites/${code}`),
}
