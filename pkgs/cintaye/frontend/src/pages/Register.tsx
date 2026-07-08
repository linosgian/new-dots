import { useState, FormEvent } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { authApi } from '../api/auth'
import { householdsApi } from '../api/households'
import { ApiError } from '../api/client'
import styles from './Auth.module.css'

export default function Register() {
  const navigate = useNavigate()
  const qc = useQueryClient()
  const [searchParams] = useSearchParams()
  const inviteCode = searchParams.get('invite') ?? ''

  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')

  const { data: inviteInfo, error: inviteError } = useQuery({
    queryKey: ['invite', inviteCode],
    queryFn: () => householdsApi.inviteInfo(inviteCode),
    enabled: inviteCode !== '',
    retry: false,
  })

  const register = useMutation({
    mutationFn: () => authApi.register(username, password, inviteCode || undefined),
    onSuccess: user => {
      qc.setQueryData(['me'], user)
      navigate('/')
    },
  })

  const submit = (e: FormEvent) => {
    e.preventDefault()
    register.mutate()
  }

  const inviteInvalid = inviteCode !== '' && inviteError != null

  return (
    <div className={styles.container}>
      <div className={styles.card}>
        <h1 className={styles.title}>Cintaye</h1>

        {inviteCode && inviteInfo && (
          <div className={styles.inviteBanner}>
            You've been invited to join <strong>{inviteInfo.household_name}</strong>.
            Create your account to join.
          </div>
        )}

        {inviteInvalid && (
          <div className={styles.inviteError}>
            This invite link is invalid or has expired.
          </div>
        )}

        {!inviteCode && (
          <p className={styles.subtitle}>Create your account</p>
        )}

        <form onSubmit={submit} className={styles.form}>
          <label className={styles.label}>
            Username
            <input
              className={styles.input}
              type="text"
              value={username}
              onChange={e => setUsername(e.target.value)}
              autoComplete="username"
              required
              minLength={2}
            />
          </label>
          <label className={styles.label}>
            Password
            <input
              className={styles.input}
              type="password"
              value={password}
              onChange={e => setPassword(e.target.value)}
              autoComplete="new-password"
              required
              minLength={8}
            />
          </label>
          {register.error && (
            <p className={styles.error}>
              {register.error instanceof ApiError ? register.error.message : 'Registration failed'}
            </p>
          )}
          <button
            type="submit"
            className={styles.btn}
            disabled={register.isPending || inviteInvalid}
          >
            {register.isPending ? 'Creating account…' : 'Create account'}
          </button>
        </form>
        <p className={styles.footer}>
          Have an account? <Link to="/login">Sign in</Link>
        </p>
      </div>
    </div>
  )
}
