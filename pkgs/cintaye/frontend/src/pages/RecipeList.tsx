import { useState, useCallback } from 'react'
import { Link } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useOutletContext } from 'react-router-dom'
import { recipesApi } from '../api/recipes'
import { authApi } from '../api/auth'
import RecipeCard from '../components/RecipeCard'
import type { Recipe, User } from '../types'
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

  const [collapsed, setCollapsed] = useState<Set<number>>(new Set())
  const toggleSection = useCallback((id: number) => {
    setCollapsed(prev => {
      const next = new Set(prev)
      next.has(id) ? next.delete(id) : next.add(id)
      return next
    })
  }, [])

  // Group by household only when the cross-household toggle is on and
  // the results actually span more than one household.
  const householdIds = [...new Set(recipes.map(r => r.household_id))]
  const grouped = user.show_other_households && householdIds.length > 1

  const sections: { id: number; name: string; recipes: Recipe[] }[] = grouped
    ? householdIds.map(id => ({
        id,
        name: recipes.find(r => r.household_id === id)?.household_name ?? `Household ${id}`,
        recipes: recipes.filter(r => r.household_id === id),
      }))
    : [{ id: 0, name: '', recipes }]

  const empty = !isLoading && recipes.length === 0

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
      ) : empty ? (
        <p className={styles.empty}>
          {search || activeTag ? 'No recipes match your filters.' : 'No recipes yet. Add your first one!'}
        </p>
      ) : (
        sections.map(section => {
          const isCollapsed = collapsed.has(section.id)
          return (
            <div key={section.id} className={grouped ? styles.section : undefined}>
              {grouped && (
                <button
                  className={styles.sectionHeading}
                  onClick={() => toggleSection(section.id)}
                  aria-expanded={!isCollapsed}
                >
                  <span>{section.name}</span>
                  <span className={styles.sectionMeta}>
                    {section.recipes.length} recipe{section.recipes.length !== 1 ? 's' : ''}
                  </span>
                  <span className={`${styles.chevron} ${isCollapsed ? styles.chevronCollapsed : ''}`}>
                    ›
                  </span>
                </button>
              )}
              {!isCollapsed && (
                <div className={styles.grid}>
                  {section.recipes.map(r => <RecipeCard key={r.id} recipe={r} />)}
                </div>
              )}
            </div>
          )
        })
      )}
    </div>
  )
}
