import { useState, FormEvent } from 'react'
import { useOutletContext } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { householdsApi } from '../api/households'
import { authApi } from '../api/auth'
import type { User } from '../types'
import styles from './HouseholdSettings.module.css'

export default function HouseholdSettings() {
  const user = useOutletContext<User>()
  const qc = useQueryClient()

  const [selectedHouseholdId, setSelectedHouseholdId] = useState<number | null>(null)
  const [generatedInvite, setGeneratedInvite] = useState<{ code: string; expires_at: string } | null>(null)
  const [joinCode, setJoinCode] = useState('')
  const [joinError, setJoinError] = useState('')
  const [newHouseholdName, setNewHouseholdName] = useState('')
  const [renameValue, setRenameValue] = useState('')
  const [isRenaming, setIsRenaming] = useState(false)
  const [copied, setCopied] = useState(false)

  const { data: households = [] } = useQuery({
    queryKey: ['households'],
    queryFn: householdsApi.mine,
  })

  const effectiveHouseholdId = selectedHouseholdId ?? households[0]?.id ?? null
  const currentHousehold = households.find(h => h.id === effectiveHouseholdId)

  const { data: members = [] } = useQuery({
    queryKey: ['household-members', effectiveHouseholdId],
    queryFn: () => householdsApi.members(effectiveHouseholdId!),
    enabled: effectiveHouseholdId !== null,
  })

  const generateInvite = useMutation({
    mutationFn: () => householdsApi.generateInvite(effectiveHouseholdId!),
    onSuccess: data => {
      setGeneratedInvite(data)
      setCopied(false)
    },
  })

  const joinHousehold = useMutation({
    mutationFn: () => householdsApi.join(joinCode),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['households'] })
      setJoinCode('')
      setJoinError('')
    },
    onError: () => setJoinError('Invalid or expired code'),
  })

  const renameHousehold = useMutation({
    mutationFn: () => householdsApi.rename(effectiveHouseholdId!, renameValue),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['households'] })
      setIsRenaming(false)
      setRenameValue('')
    },
  })

  const createHousehold = useMutation({
    mutationFn: () => householdsApi.create(newHouseholdName),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['households'] })
      setNewHouseholdName('')
    },
  })

  const toggleOtherHouseholds = useMutation({
    mutationFn: (val: boolean) => authApi.updateMe({ show_other_households: val }),
    onSuccess: updated => qc.setQueryData(['me'], updated),
  })

  const inviteLink = generatedInvite
    ? `${window.location.origin}/register?invite=${generatedInvite.code}`
    : null

  const copyLink = () => {
    if (!inviteLink) return
    navigator.clipboard.writeText(inviteLink).then(() => {
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    })
  }

  const submitJoin = (e: FormEvent) => {
    e.preventDefault()
    setJoinError('')
    joinHousehold.mutate()
  }

  const isOwner = currentHousehold?.owner_id === user.id

  return (
    <div className={styles.container}>
      <h1 className={styles.heading}>Household settings</h1>

      {households.length > 1 && (
        <div className={styles.card}>
          <h2 className={styles.cardTitle}>Your households</h2>
          <div className={styles.householdList}>
            {households.map(h => (
              <button
                key={h.id}
                type="button"
                className={`${styles.householdBtn} ${effectiveHouseholdId === h.id ? styles.active : ''}`}
                onClick={() => {
                  setSelectedHouseholdId(h.id)
                  setGeneratedInvite(null)
                  setIsRenaming(false)
                }}
              >
                {h.name}
                {h.owner_id === user.id && <span className={styles.ownerBadge}>owner</span>}
              </button>
            ))}
          </div>
        </div>
      )}

      {currentHousehold && (
        <div className={styles.card}>
          <div className={styles.householdHeader}>
            {isRenaming ? (
              <form
                className={styles.renameForm}
                onSubmit={e => { e.preventDefault(); renameHousehold.mutate() }}
              >
                <input
                  className={styles.input}
                  value={renameValue}
                  onChange={e => setRenameValue(e.target.value)}
                  placeholder={currentHousehold.name}
                  autoFocus
                  required
                />
                <button type="submit" className={styles.btnPrimary} disabled={renameHousehold.isPending}>
                  Save
                </button>
                <button type="button" className={styles.btnGhost} onClick={() => setIsRenaming(false)}>
                  Cancel
                </button>
              </form>
            ) : (
              <>
                <h2 className={styles.cardTitle}>{currentHousehold.name}</h2>
                {isOwner && (
                  <button
                    className={styles.btnGhost}
                    onClick={() => { setIsRenaming(true); setRenameValue(currentHousehold.name) }}
                  >
                    Rename
                  </button>
                )}
              </>
            )}
          </div>

          <div className={styles.section}>
            <h3 className={styles.sectionTitle}>Members</h3>
            {members.map(m => (
              <div key={m.id} className={styles.member}>
                <span>{m.username}</span>
                {m.id === currentHousehold.owner_id && <span className={styles.ownerBadge}>owner</span>}
              </div>
            ))}
          </div>

          {isOwner && (
            <div className={styles.section}>
              <h3 className={styles.sectionTitle}>Invite someone</h3>
              <p className={styles.hint}>
                Generate a link and send it to the person you'd like to invite.
                Each link is single-use and expires in 7 days.
              </p>
              <button
                className={styles.btnOutline}
                onClick={() => generateInvite.mutate()}
                disabled={generateInvite.isPending}
              >
                {generateInvite.isPending ? 'Generating…' : 'Generate invite link'}
              </button>

              {inviteLink && (
                <div className={styles.inviteBox}>
                  <input
                    className={styles.inviteLinkInput}
                    value={inviteLink}
                    readOnly
                    onFocus={e => e.target.select()}
                  />
                  <button type="button" className={styles.copyBtn} onClick={copyLink}>
                    {copied ? 'Copied!' : 'Copy'}
                  </button>
                  <span className={styles.expires}>
                    Expires {new Date(generatedInvite!.expires_at).toLocaleDateString()}
                  </span>
                </div>
              )}
            </div>
          )}
        </div>
      )}

      <div className={styles.card}>
        <h2 className={styles.cardTitle}>Join a household</h2>
        <p className={styles.hint}>Paste an invite link or just the code from the URL.</p>
        <form onSubmit={submitJoin} className={styles.joinForm}>
          <input
            className={styles.input}
            value={joinCode}
            onChange={e => setJoinCode(e.target.value.replace(/.*invite=/, ''))}
            placeholder="Invite code or link"
            required
          />
          {joinError && <p className={styles.error}>{joinError}</p>}
          <button type="submit" className={styles.btnPrimary} disabled={joinHousehold.isPending}>
            {joinHousehold.isPending ? 'Joining…' : 'Join'}
          </button>
        </form>
      </div>

      {user.is_admin && (
        <div className={styles.card}>
          <h2 className={styles.cardTitle}>Create new household</h2>
          <form
            onSubmit={e => { e.preventDefault(); createHousehold.mutate() }}
            className={styles.joinForm}
          >
            <input
              className={styles.input}
              value={newHouseholdName}
              onChange={e => setNewHouseholdName(e.target.value)}
              placeholder="Household name"
              required
            />
            <button type="submit" className={styles.btnPrimary} disabled={createHousehold.isPending}>
              {createHousehold.isPending ? 'Creating…' : 'Create'}
            </button>
          </form>
        </div>
      )}

      <div className={styles.card}>
        <h2 className={styles.cardTitle}>Preferences</h2>
        <label className={styles.toggle}>
          <input
            type="checkbox"
            checked={user.show_other_households}
            onChange={e => toggleOtherHouseholds.mutate(e.target.checked)}
          />
          <span>
            Show recipes from other households
            <span className={styles.toggleHint}>
              Recipes from all households appear in your list (read-only).
            </span>
          </span>
        </label>
      </div>
    </div>
  )
}
