import { useState, FormEvent } from 'react'
import { useParams, Link, useNavigate, useOutletContext } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { recipesApi } from '../api/recipes'
import { commentsApi } from '../api/comments'
import ScaleControl from '../components/ScaleControl'
import Avatar from '../components/Avatar'
import type { User } from '../types'
import styles from './RecipeDetail.module.css'

function formatAmount(amount: number | undefined) {
  if (amount === undefined) return ''
  const rounded = Math.round(amount * 100) / 100
  if (rounded === Math.floor(rounded)) return String(rounded)
  return rounded.toFixed(2).replace(/\.?0+$/, '')
}

const UNIT_ABBR: Record<string, string> = {
  grams: 'g', gram: 'g',
  tablespoons: 'tbsp', tablespoon: 'tbsp',
  teaspoons: 'tsp', teaspoon: 'tsp',
  milliliters: 'ml', milliliter: 'ml',
  millilitres: 'ml', millilitre: 'ml',
  liters: 'l', liter: 'l', litres: 'l', litre: 'l',
  kilograms: 'kg', kilogram: 'kg',
  ounces: 'oz', ounce: 'oz',
  pounds: 'lb', pound: 'lb',
}

function abbr(unit: string | undefined): string {
  if (!unit) return ''
  return UNIT_ABBR[unit.toLowerCase()] ?? unit
}

function formatTime(minutes: number) {
  if (minutes < 60) return `${minutes} min`
  const h = Math.floor(minutes / 60)
  const m = minutes % 60
  return m > 0 ? `${h}h ${m}min` : `${h}h`
}

export default function RecipeDetail() {
  const { id } = useParams<{ id: string }>()
  const user = useOutletContext<User>()
  const navigate = useNavigate()
  const qc = useQueryClient()
  const recipeId = Number(id)

  const [scale, setScale] = useState(1)
  const [commentBody, setCommentBody] = useState('')

  const { data: recipe, isLoading, error } = useQuery({
    queryKey: ['recipe', recipeId],
    queryFn: () => recipesApi.get(recipeId),
  })

  const { data: comments = [] } = useQuery({
    queryKey: ['comments', recipeId],
    queryFn: () => commentsApi.list(recipeId),
    enabled: !!recipe,
  })

  const deleteRecipe = useMutation({
    mutationFn: () => recipesApi.delete(recipeId),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['recipes'] })
      navigate('/')
    },
  })

  const addComment = useMutation({
    mutationFn: () => commentsApi.create(recipeId, commentBody),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['comments', recipeId] })
      setCommentBody('')
    },
  })

  const deleteComment = useMutation({
    mutationFn: (commentId: number) => commentsApi.delete(commentId),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['comments', recipeId] }),
  })

  const submitComment = (e: FormEvent) => {
    e.preventDefault()
    if (commentBody.trim()) addComment.mutate()
  }

  if (isLoading) return <p>Loading…</p>
  if (error || !recipe) return <p>Recipe not found.</p>

  const isOwner = recipe.created_by === user.id
  const ingredientSections = recipe.sections?.filter(s => s.kind === 'ingredients') ?? []
  const instructionSections = recipe.sections?.filter(s => s.kind === 'instructions') ?? []

  return (
    <div className={styles.container}>
      {recipe.image_path && (
        <img className={styles.heroImage} src={`/images/${recipe.image_path}`} alt={recipe.title} />
      )}

      <div className={styles.header}>
        <div>
          <h1 className={styles.title}>{recipe.title}</h1>
          {recipe.source_url && (
            <a href={recipe.source_url} target="_blank" rel="noopener noreferrer" className={styles.source}>
              Original recipe ↗
            </a>
          )}
        </div>
        {isOwner && (
          <div className={styles.headerActions}>
            <Link to={`/recipes/${recipe.id}/edit`} className={styles.btnOutline}>Edit</Link>
            <button
              className={styles.btnDanger}
              onClick={() => { if (confirm('Delete this recipe?')) deleteRecipe.mutate() }}
            >
              Delete
            </button>
          </div>
        )}
      </div>

      {recipe.description && <p className={styles.description}>{recipe.description}</p>}

      {(recipe.prep_time_minutes || recipe.cook_time_minutes || recipe.total_time_minutes || recipe.servings) && (
        <div className={styles.meta}>
          {recipe.prep_time_minutes && <div className={styles.metaItem}><span>Prep</span>{formatTime(recipe.prep_time_minutes)}</div>}
          {recipe.cook_time_minutes && <div className={styles.metaItem}><span>Cook</span>{formatTime(recipe.cook_time_minutes)}</div>}
          {recipe.total_time_minutes && <div className={styles.metaItem}><span>Total</span>{formatTime(recipe.total_time_minutes)}</div>}
          {recipe.servings && (
            <div className={styles.metaItem}>
              <span>Serves</span>
              {Math.round(recipe.servings * scale * 10) / 10}
            </div>
          )}
        </div>
      )}

      {recipe.tags && recipe.tags.length > 0 && (
        <div className={styles.tags}>
          {recipe.tags.map(t => <span key={t} className={styles.tag}>{t}</span>)}
        </div>
      )}

      <div className={styles.scaleRow}>
        <ScaleControl scale={scale} onChange={setScale} />
      </div>

      <div className={styles.columns}>
        {ingredientSections.length > 0 && (
          <div className={styles.ingredients}>
            <h2 className={styles.sectionHeading}>Ingredients</h2>
            {ingredientSections.map(sec => (
              <div key={sec.id} className={styles.section}>
                {sec.title && <h3 className={styles.subsection}>{sec.title}</h3>}
                <ul className={styles.ingredientList}>
                  {(sec.ingredients ?? []).map(ing => (
                    <li key={ing.id} className={styles.ingredient}>
                      <span className={styles.ingAmount}>
                        {ing.amount !== undefined ? formatAmount(ing.amount * scale) : ''}
                      </span>
                      <span className={styles.ingUnit}>{abbr(ing.unit)}</span>
                      <span className={styles.ingName}>
                        {ing.name}
                        {ing.note && <span className={styles.note}> ({ing.note})</span>}
                      </span>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        )}

        {instructionSections.length > 0 && (
          <div className={styles.instructions}>
            <h2 className={styles.sectionHeading}>Instructions</h2>
            {instructionSections.map(sec => (
              <div key={sec.id} className={styles.section}>
                {sec.title && <h3 className={styles.subsection}>{sec.title}</h3>}
                <ol className={styles.instructionList}>
                  {(sec.instructions ?? []).map(inst => (
                    <li key={inst.id} className={styles.instruction}>{inst.body}</li>
                  ))}
                </ol>
              </div>
            ))}
          </div>
        )}
      </div>

      <div className={styles.comments}>
        <h2 className={styles.sectionHeading}>Comments</h2>
        {comments.length === 0 && <p className={styles.empty}>No comments yet.</p>}
        {comments.map(c => (
          <div key={c.id} className={styles.comment}>
            <div className={styles.commentMeta}>
              <Avatar username={c.username ?? '?'} size="sm" />
              <strong>{c.username}</strong>
              <span className={styles.commentDate}>
                {new Date(c.created_at).toLocaleDateString('en-GB')}
              </span>
              {c.user_id === user.id && (
                <button
                  className={styles.deleteComment}
                  onClick={() => deleteComment.mutate(c.id)}
                >
                  Delete
                </button>
              )}
            </div>
            <p className={styles.commentBody}>{c.body}</p>
          </div>
        ))}
        <form onSubmit={submitComment} className={styles.commentForm}>
          <textarea
            className={styles.commentInput}
            value={commentBody}
            onChange={e => setCommentBody(e.target.value)}
            placeholder="Add a comment…"
            rows={3}
          />
          <button
            type="submit"
            className={styles.btnPrimary}
            disabled={addComment.isPending || !commentBody.trim()}
          >
            Post
          </button>
        </form>
      </div>
    </div>
  )
}
