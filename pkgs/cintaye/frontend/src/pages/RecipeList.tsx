import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useOutletContext } from 'react-router-dom'
import { recipesApi } from '../api/recipes'
import { authApi } from '../api/auth'
import RecipeCard from '../components/RecipeCard'
import type { User } from '../types'
import styles from './RecipeList.module.css'

export default function RecipeList() {
  const user = useOutletContext<User>()
  const qc = useQueryClient()

  const [search, setSearch] = useState('')
  const [activeTag, setActiveTag] = useState('')
  const [debouncedSearch, setDebouncedSearch] = useState('')

  const { data: recipes = [], isLoading } = useQuery({
    queryKey: ['recipes', debouncedSearch, activeTag],
    queryFn: () => recipesApi.list({ q: debouncedSearch, tag: activeTag }),
  })

  const { data: tags = [] } = useQuery({
    queryKey: ['tags'],
    queryFn: recipesApi.tags,
  })

  const toggleOtherHouseholds = useMutation({
    mutationFn: (val: boolean) => authApi.updateMe({ show_other_households: val }),
    onSuccess: updated => {
      qc.setQueryData(['me'], updated)
      qc.invalidateQueries({ queryKey: ['recipes'] })
    },
  })

  const handleSearch = (val: string) => {
    setSearch(val)
    clearTimeout((handleSearch as unknown as { timer?: ReturnType<typeof setTimeout> }).timer)
    ;(handleSearch as unknown as { timer?: ReturnType<typeof setTimeout> }).timer = setTimeout(
      () => setDebouncedSearch(val),
      300,
    )
  }

  return (
    <div>
      <div className={styles.header}>
        <h2 className={styles.heading}>Recipes</h2>
        <div className={styles.actions}>
          <Link to="/recipes/new" className={styles.btnPrimary}>+ New recipe</Link>
          <Link to="/recipes/import" className={styles.btnOutline}>Import</Link>
        </div>
      </div>

      <div className={styles.filters}>
        <input
          className={styles.search}
          type="search"
          placeholder="Search recipes…"
          value={search}
          onChange={e => handleSearch(e.target.value)}
        />
        <label className={styles.toggle}>
          <input
            type="checkbox"
            checked={user.show_other_households}
            onChange={e => toggleOtherHouseholds.mutate(e.target.checked)}
          />
          Show other households
        </label>
      </div>

      {tags.length > 0 && (
        <div className={styles.tagBar}>
          <button
            className={`${styles.tagBtn} ${activeTag === '' ? styles.tagActive : ''}`}
            onClick={() => setActiveTag('')}
          >
            All
          </button>
          {tags.map(tag => (
            <button
              key={tag}
              className={`${styles.tagBtn} ${activeTag === tag ? styles.tagActive : ''}`}
              onClick={() => setActiveTag(activeTag === tag ? '' : tag)}
            >
              {tag}
            </button>
          ))}
        </div>
      )}

      {isLoading ? (
        <p className={styles.empty}>Loading…</p>
      ) : recipes.length === 0 ? (
        <p className={styles.empty}>
          {search || activeTag ? 'No recipes match your filters.' : 'No recipes yet. Add your first one!'}
        </p>
      ) : (
        <div className={styles.grid}>
          {recipes.map(r => <RecipeCard key={r.id} recipe={r} />)}
        </div>
      )}
    </div>
  )
}
