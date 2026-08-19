import { Link, useNavigate } from 'react-router-dom'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { authApi } from '../api/auth'
import Avatar from './Avatar'
import { useTheme } from '../hooks/useTheme'
import type { User } from '../types'
import styles from './Nav.module.css'

export default function Nav({ user }: { user: User }) {
  const navigate = useNavigate()
  const qc = useQueryClient()
  const { theme, toggle } = useTheme()

  const logout = useMutation({
    mutationFn: authApi.logout,
    onSuccess: () => {
      qc.clear()
      navigate('/login')
    },
  })

  return (
    <nav className={styles.nav}>
      <div className={styles.left}>
        <Link to="/" className={styles.brand}>Cintaye</Link>
        <Link to="/recipes/new">New recipe</Link>
        <Link to="/recipes/import">Import</Link>
        <Link to="/household">Household</Link>
      </div>
      <div className={styles.right}>
        <button
          className={styles.themeToggle}
          onClick={toggle}
          title={theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}
          aria-label={theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}
        >
          {theme === 'dark' ? '☀' : '☾'}
        </button>
        <Avatar username={user.username} size="sm" />
        <span className={styles.username}>{user.username}</span>
        <button
          className={styles.logoutBtn}
          onClick={() => logout.mutate()}
          disabled={logout.isPending}
        >
          Sign out
        </button>
      </div>
    </nav>
  )
}
