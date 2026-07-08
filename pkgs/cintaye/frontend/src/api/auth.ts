import { api } from './client'
import type { User } from '../types'

export const authApi = {
  register: (username: string, password: string, inviteCode?: string) =>
    api.post<User>('/api/auth/register', { username, password, invite_code: inviteCode ?? '' }),

  login: (username: string, password: string) =>
    api.post<User>('/api/auth/login', { username, password }),

  logout: () => api.post<{ ok: string }>('/api/auth/logout'),

  me: () => api.get<User>('/api/auth/me'),

  updateMe: (data: Partial<Pick<User, 'show_other_households'>>) =>
    api.patch<User>('/api/users/me', data),
}
