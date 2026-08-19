import ReactMarkdown from 'react-markdown'
import remarkGfm from 'remark-gfm'
import styles from './Markdown.module.css'

interface Props {
  children: string
  className?: string
  inline?: boolean
}

export default function Markdown({ children, className, inline }: Props) {
  if (inline) {
    return (
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        components={{ p: ({ children }) => <>{children}</> }}
      >
        {children}
      </ReactMarkdown>
    )
  }
  return (
    <div className={`${styles.md} ${className ?? ''}`}>
      <ReactMarkdown remarkPlugins={[remarkGfm]}>{children}</ReactMarkdown>
    </div>
  )
}
