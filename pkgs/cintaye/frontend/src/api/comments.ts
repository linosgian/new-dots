import { api } from './client'
import type { Comment } from '../types'

export const commentsApi = {
  list: (recipeId: number) => api.get<Comment[]>(`/api/recipes/${recipeId}/comments`),

  create: (recipeId: number, body: string) =>
    api.post<Comment>(`/api/recipes/${recipeId}/comments`, { body }),

  delete: (commentId: number) => api.delete<{ ok: string }>(`/api/comments/${commentId}`),
}
