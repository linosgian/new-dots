import { api } from './client'
import type { Recipe, RecipeRequest } from '../types'

export const recipesApi = {
  list: (params?: { q?: string; tag?: string }) => {
    const qs = new URLSearchParams()
    if (params?.q) qs.set('q', params.q)
    if (params?.tag) qs.set('tag', params.tag)
    const query = qs.toString()
    return api.get<Recipe[]>(`/api/recipes${query ? `?${query}` : ''}`)
  },

  get: (id: number, scale?: number) => {
    const qs = scale && scale !== 1 ? `?scale=${scale}` : ''
    return api.get<Recipe>(`/api/recipes/${id}${qs}`)
  },

  create: (data: RecipeRequest) => api.post<Recipe>('/api/recipes', data),

  update: (id: number, data: RecipeRequest) => api.put<Recipe>(`/api/recipes/${id}`, data),

  delete: (id: number) => api.delete<{ ok: string }>(`/api/recipes/${id}`),

  import: (data: { url?: string; jsonld?: string }) =>
    api.post<Recipe>('/api/recipes/import', data),

  importBatch: (urls: string[]) =>
    api.post<{ url: string; recipe?: Recipe; error?: string }[]>('/api/recipes/import', { urls }),

  uploadImage: (id: number, file: File) => {
    const form = new FormData()
    form.append('image', file)
    return api.upload<{ image_path: string }>(`/api/recipes/${id}/image`, form)
  },

  tags: () => api.get<string[]>('/api/tags'),
}
