import styles from './ScaleControl.module.css'

interface Props {
  scale: number
  onChange: (scale: number) => void
}

const PRESETS = [0.5, 1, 1.5, 2, 3, 4]

export default function ScaleControl({ scale, onChange }: Props) {
  return (
    <div className={styles.container}>
      <span className={styles.label}>Scale:</span>
      <div className={styles.presets}>
        {PRESETS.map(p => (
          <button
            key={p}
            type="button"
            className={`${styles.preset} ${scale === p ? styles.active : ''}`}
            onClick={() => onChange(p)}
          >
            {p}×
          </button>
        ))}
      </div>
      <input
        type="number"
        className={styles.custom}
        value={scale}
        min={0.1}
        max={20}
        step={0.1}
        onChange={e => {
          const v = parseFloat(e.target.value)
          if (v > 0) onChange(v)
        }}
      />
    </div>
  )
}
