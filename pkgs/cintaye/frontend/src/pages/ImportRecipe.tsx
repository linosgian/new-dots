import { useState, FormEvent } from 'react'
import { Link } from 'react-router-dom'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { recipesApi } from '../api/recipes'
import { ApiError } from '../api/client'
import type { Recipe } from '../types'
import styles from './ImportRecipe.module.css'

type BatchResult = { url: string; recipe?: Recipe; error?: string }

export default function ImportRecipe() {
  const qc = useQueryClient()
  const [mode, setMode] = useState<'url' | 'paste'>('url')
  const [urlsText, setUrlsText] = useState('')
  const [jsonld, setJsonld] = useState('')
  const [batchResults, setBatchResults] = useState<BatchResult[] | null>(null)
  const [singleRecipe, setSingleRecipe] = useState<Recipe | null>(null)

  const urls = urlsText.split('\n').map(u => u.trim()).filter(Boolean)

  const batchMutation = useMutation({
    mutationFn: () => recipesApi.importBatch(urls),
    onSuccess: results => {
      setBatchResults(results)
      qc.invalidateQueries({ queryKey: ['recipes'] })
    },
  })

  const singleMutation = useMutation({
    mutationFn: () => recipesApi.import({ jsonld }),
    onSuccess: recipe => {
      setSingleRecipe(recipe)
      qc.invalidateQueries({ queryKey: ['recipes'] })
    },
  })

  const isPending = batchMutation.isPending || singleMutation.isPending

  const submit = (e: FormEvent) => {
    e.preventDefault()
    setBatchResults(null)
    setSingleRecipe(null)
    if (mode === 'url') {
      batchMutation.mutate()
    } else {
      singleMutation.mutate()
    }
  }

  const switchMode = (next: 'url' | 'paste') => {
    setMode(next)
    setBatchResults(null)
    setSingleRecipe(null)
  }

  const error = batchMutation.error ?? singleMutation.error

  return (
    <div className={styles.container}>
      <h1 className={styles.heading}>Import recipe</h1>

      <div className={styles.tabs}>
        <button
          type="button"
          className={`${styles.tab} ${mode === 'url' ? styles.active : ''}`}
          onClick={() => switchMode('url')}
        >
          From URL
        </button>
        <button
          type="button"
          className={`${styles.tab} ${mode === 'paste' ? styles.active : ''}`}
          onClick={() => switchMode('paste')}
        >
          Paste JSON-LD
        </button>
      </div>

      <form onSubmit={submit} className={styles.form}>
        {mode === 'url' ? (
          <label className={styles.label}>
            Recipe URLs
            <span className={styles.labelHint}>One URL per line</span>
            <textarea
              className={styles.textarea}
              value={urlsText}
              onChange={e => setUrlsText(e.target.value)}
              placeholder={'https://example.com/recipes/chicken-tikka\nhttps://example.com/recipes/pasta'}
              rows={5}
              required
            />
          </label>
        ) : (
          <label className={styles.label}>
            JSON-LD text
            <textarea
              className={styles.textarea}
              value={jsonld}
              onChange={e => setJsonld(e.target.value)}
              placeholder={`{"@context":"https://schema.org","@type":"Recipe","name":"…"}`}
              rows={10}
              required
            />
          </label>
        )}

        {error && (
          <p className={styles.error}>
            {error instanceof ApiError ? error.message : 'Import failed'}
          </p>
        )}

        <button type="submit" className={styles.btnPrimary} disabled={isPending}>
          {isPending
            ? 'Importing…'
            : mode === 'url' && urls.length > 1
            ? `Import ${urls.length} recipes`
            : 'Import'}
        </button>
      </form>

      {batchResults && (
        <div className={styles.results}>
          {batchResults.map((r, i) => (
            <div
              key={i}
              className={`${styles.resultItem} ${r.error ? styles.resultError : styles.resultSuccess}`}
            >
              <span className={styles.resultIcon}>{r.error ? '✕' : '✓'}</span>
              <div className={styles.resultBody}>
                {r.recipe ? (
                  <Link to={`/recipes/${r.recipe.id}`} className={styles.resultTitle}>
                    {r.recipe.title}
                  </Link>
                ) : (
                  <span className={styles.resultUrl}>{r.url}</span>
                )}
                {r.error && <span className={styles.resultErrorMsg}>{r.error}</span>}
              </div>
            </div>
          ))}
        </div>
      )}

      {singleRecipe && (
        <div className={styles.preview}>
          <h2 className={styles.previewTitle}>{singleRecipe.title}</h2>
          {singleRecipe.description && (
            <p className={styles.previewDesc}>{singleRecipe.description}</p>
          )}
          <div className={styles.previewActions}>
            <Link to={`/recipes/${singleRecipe.id}`} className={styles.btnPrimary}>
              View recipe
            </Link>
            <Link to={`/recipes/${singleRecipe.id}/edit`} className={styles.btnOutline}>
              Edit before saving
            </Link>
          </div>
        </div>
      )}
    </div>
  )
}
