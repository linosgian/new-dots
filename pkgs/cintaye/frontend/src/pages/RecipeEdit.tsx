import { useState, useEffect, useRef, FormEvent, ChangeEvent } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { recipesApi } from '../api/recipes'
import TagInput from '../components/TagInput'
import SectionEditor from '../components/SectionEditor'
import type { RecipeRequest, SectionRequest, Recipe } from '../types'
import styles from './RecipeEdit.module.css'

function recipeToRequest(r: Recipe): RecipeRequest {
  return {
    title: r.title,
    description: r.description ?? '',
    prep_time_minutes: r.prep_time_minutes,
    cook_time_minutes: r.cook_time_minutes,
    total_time_minutes: r.total_time_minutes,
    servings: r.servings,
    source_url: r.source_url ?? '',
    tags: r.tags ?? [],
    sections: (r.sections ?? []).map(s => ({
      kind: s.kind,
      title: s.title ?? '',
      position: s.position,
      ingredients: s.ingredients?.map(ing => ({
        position: ing.position,
        amount: ing.amount,
        unit: ing.unit ?? '',
        name: ing.name,
        note: ing.note ?? '',
      })),
      instructions: s.instructions?.map(inst => ({
        position: inst.position,
        body: inst.body,
      })),
    })),
  }
}

const emptyForm: RecipeRequest = {
  title: '',
  description: '',
  tags: [],
  sections: [],
}

export default function RecipeEdit() {
  const { id } = useParams<{ id?: string }>()
  const navigate = useNavigate()
  const qc = useQueryClient()
  const isEdit = !!id
  const recipeId = id ? Number(id) : undefined

  const { data: existing } = useQuery({
    queryKey: ['recipe', recipeId, 1],
    queryFn: () => recipesApi.get(recipeId!),
    enabled: isEdit,
  })

  const [form, setForm] = useState<RecipeRequest>(emptyForm)
  const [imageFile, setImageFile] = useState<File | null>(null)
  const [imagePreview, setImagePreview] = useState<string | null>(null)
  const descRef = useRef<HTMLTextAreaElement>(null)

  useEffect(() => {
    if (existing) setForm(recipeToRequest(existing))
  }, [existing])

  useEffect(() => {
    const el = descRef.current
    if (!el) return
    el.style.height = 'auto'
    el.style.height = el.scrollHeight + 'px'
  }, [form.description])

  const set = (patch: Partial<RecipeRequest>) => setForm(f => ({ ...f, ...patch }))

  const createMutation = useMutation({
    mutationFn: () => recipesApi.create(form),
    onSuccess: async recipe => {
      if (imageFile) {
        await recipesApi.uploadImage(recipe.id, imageFile).catch(() => null)
      }
      qc.invalidateQueries({ queryKey: ['recipes'] })
      navigate(`/recipes/${recipe.id}`)
    },
  })

  const updateMutation = useMutation({
    mutationFn: () => recipesApi.update(recipeId!, form),
    onSuccess: async recipe => {
      if (imageFile) {
        await recipesApi.uploadImage(recipe.id, imageFile).catch(() => null)
      }
      qc.invalidateQueries({ queryKey: ['recipes'] })
      qc.invalidateQueries({ queryKey: ['recipe', recipeId] })
      navigate(`/recipes/${recipe.id}`)
    },
  })

  const handleImage = (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    setImageFile(file)
    setImagePreview(URL.createObjectURL(file))
  }

  const submit = (e: FormEvent) => {
    e.preventDefault()
    if (isEdit) updateMutation.mutate()
    else createMutation.mutate()
  }

  const isPending = createMutation.isPending || updateMutation.isPending
  const error = createMutation.error ?? updateMutation.error

  const num = (val: number | undefined) => (val === undefined ? '' : String(val))
  const toNum = (s: string) => (s === '' ? undefined : Number(s))

  return (
    <div className={styles.container}>
      <h1 className={styles.heading}>{isEdit ? 'Edit recipe' : 'New recipe'}</h1>
      <form onSubmit={submit} className={styles.form}>

        <section className={styles.fieldGroup}>
          <label className={styles.label}>
            Title *
            <input
              className={styles.input}
              value={form.title}
              onChange={e => set({ title: e.target.value })}
              required
              placeholder="Recipe title"
            />
          </label>

          <label className={styles.label}>
            Description <span className={styles.hint}>Markdown supported</span>
            <textarea
              ref={descRef}
              className={styles.textarea}
              value={form.description ?? ''}
              onChange={e => set({ description: e.target.value })}
              placeholder="Brief description"
              rows={3}
            />
          </label>

          <label className={styles.label}>
            Source URL
            <input
              className={styles.input}
              type="url"
              value={form.source_url ?? ''}
              onChange={e => set({ source_url: e.target.value })}
              placeholder="https://…"
            />
          </label>
        </section>

        <section className={styles.fieldGroup}>
          <h2 className={styles.subheading}>Timing & servings</h2>
          <div className={styles.row}>
            <label className={styles.label}>
              Prep time (min)
              <input
                className={styles.input}
                type="number"
                min={0}
                value={num(form.prep_time_minutes)}
                onChange={e => set({ prep_time_minutes: toNum(e.target.value) })}
              />
            </label>
            <label className={styles.label}>
              Cook time (min)
              <input
                className={styles.input}
                type="number"
                min={0}
                value={num(form.cook_time_minutes)}
                onChange={e => set({ cook_time_minutes: toNum(e.target.value) })}
              />
            </label>
            <label className={styles.label}>
              Total time (min)
              <input
                className={styles.input}
                type="number"
                min={0}
                value={num(form.total_time_minutes)}
                onChange={e => set({ total_time_minutes: toNum(e.target.value) })}
              />
            </label>
            <label className={styles.label}>
              Servings
              <input
                className={styles.input}
                type="number"
                min={1}
                value={num(form.servings)}
                onChange={e => set({ servings: toNum(e.target.value) })}
              />
            </label>
          </div>
        </section>

        <section className={styles.fieldGroup}>
          <label className={styles.label}>
            Tags
            <TagInput tags={form.tags ?? []} onChange={tags => set({ tags })} />
          </label>
        </section>

        <section className={styles.fieldGroup}>
          <h2 className={styles.subheading}>Image</h2>
          {(imagePreview ?? (existing?.image_path && `/images/${existing.image_path}`)) && (
            <img
              className={styles.imagePreview}
              src={imagePreview ?? `/images/${existing!.image_path}`}
              alt="Preview"
            />
          )}
          <input type="file" accept="image/*" onChange={handleImage} />
        </section>

        <section className={styles.fieldGroup}>
          <h2 className={styles.subheading}>Sections</h2>
          <SectionEditor
            sections={form.sections as SectionRequest[]}
            onChange={sections => set({ sections })}
          />
        </section>

        {error && <p className={styles.error}>{(error as Error).message}</p>}

        <div className={styles.actions}>
          <button
            type="button"
            className={styles.btnOutline}
            onClick={() => navigate(-1)}
          >
            Cancel
          </button>
          <button type="submit" className={styles.btnPrimary} disabled={isPending}>
            {isPending ? 'Saving…' : isEdit ? 'Save changes' : 'Create recipe'}
          </button>
        </div>
      </form>
    </div>
  )
}
