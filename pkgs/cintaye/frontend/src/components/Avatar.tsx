import styles from './Avatar.module.css'

const COLORS = [
  '#4a9e6b',
  '#5b8dd9',
  '#e07b39',
  '#8b5cf6',
  '#e85d75',
  '#0ea5a0',
  '#d4831d',
  '#6b7db3',
]

function avatarColor(username: string): string {
  let hash = 0
  for (let i = 0; i < username.length; i++) {
    hash = (hash * 31 + username.charCodeAt(i)) >>> 0
  }
  return COLORS[hash % COLORS.length]
}

interface AvatarProps {
  username: string
  size?: 'sm' | 'md'
}

export default function Avatar({ username, size = 'md' }: AvatarProps) {
  return (
    <span
      className={`${styles.avatar} ${styles[size]}`}
      style={{ background: avatarColor(username) }}
      aria-hidden="true"
    >
      {username[0]?.toUpperCase()}
    </span>
  )
}
