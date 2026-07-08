import type { SectionRequest, IngredientRequest, InstructionRequest } from '../types'
import styles from './SectionEditor.module.css'

interface Props {
  sections: SectionRequest[]
  onChange: (sections: SectionRequest[]) => void
}

export default function SectionEditor({ sections, onChange }: Props) {
  const addSection = (kind: 'ingredients' | 'instructions') => {
    const pos = sections.length + 1
    onChange([...sections, { kind, title: '', position: pos, ingredients: [], instructions: [] }])
  }

  const updateSection = (idx: number, update: Partial<SectionRequest>) => {
    onChange(sections.map((s, i) => (i === idx ? { ...s, ...update } : s)))
  }

  const removeSection = (idx: number) => {
    onChange(sections.filter((_, i) => i !== idx).map((s, i) => ({ ...s, position: i + 1 })))
  }

  const moveSection = (idx: number, dir: -1 | 1) => {
    const next = [...sections]
    const swap = idx + dir
    if (swap < 0 || swap >= next.length) return
    ;[next[idx], next[swap]] = [next[swap], next[idx]]
    onChange(next.map((s, i) => ({ ...s, position: i + 1 })))
  }

  return (
    <div className={styles.container}>
      {sections.map((sec, idx) => (
        <div key={idx} className={styles.section}>
          <div className={styles.sectionHeader}>
            <span className={styles.kindBadge}>{sec.kind}</span>
            <input
              className={styles.titleInput}
              value={sec.title ?? ''}
              onChange={e => updateSection(idx, { title: e.target.value })}
              placeholder="Section title (optional)"
            />
            <div className={styles.sectionControls}>
              <button type="button" onClick={() => moveSection(idx, -1)} disabled={idx === 0} title="Move up">↑</button>
              <button type="button" onClick={() => moveSection(idx, 1)} disabled={idx === sections.length - 1} title="Move down">↓</button>
              <button type="button" onClick={() => removeSection(idx)} className={styles.removeBtn} title="Remove section">×</button>
            </div>
          </div>

          {sec.kind === 'ingredients' ? (
            <IngredientRows
              items={sec.ingredients ?? []}
              onChange={items => updateSection(idx, { ingredients: items })}
            />
          ) : (
            <InstructionRows
              items={sec.instructions ?? []}
              onChange={items => updateSection(idx, { instructions: items })}
            />
          )}
        </div>
      ))}

      <div className={styles.addButtons}>
        <button type="button" className={styles.addBtn} onClick={() => addSection('ingredients')}>
          + Add ingredient section
        </button>
        <button type="button" className={styles.addBtn} onClick={() => addSection('instructions')}>
          + Add instruction section
        </button>
      </div>
    </div>
  )
}

function IngredientRows({
  items,
  onChange,
}: {
  items: IngredientRequest[]
  onChange: (items: IngredientRequest[]) => void
}) {
  const add = () =>
    onChange([...items, { position: items.length + 1, name: '', unit: '', note: '' }])

  const update = (idx: number, patch: Partial<IngredientRequest>) =>
    onChange(items.map((it, i) => (i === idx ? { ...it, ...patch } : it)))

  const remove = (idx: number) =>
    onChange(items.filter((_, i) => i !== idx).map((it, i) => ({ ...it, position: i + 1 })))

  return (
    <div className={styles.rows}>
      {items.length > 0 && (
        <div className={styles.ingHeader}>
          <span style={{ width: 70 }}>Amount</span>
          <span style={{ width: 80 }}>Unit</span>
          <span style={{ flex: 1 }}>Name</span>
          <span style={{ flex: 1 }}>Note</span>
          <span style={{ width: 24 }} />
        </div>
      )}
      {items.map((ing, idx) => (
        <div key={idx} className={styles.ingRow}>
          <input
            className={styles.cell}
            style={{ width: 70 }}
            type="number"
            min={0}
            step="any"
            value={ing.amount ?? ''}
            onChange={e => update(idx, { amount: e.target.value ? Number(e.target.value) : undefined })}
            placeholder="—"
          />
          <input
            className={styles.cell}
            style={{ width: 80 }}
            value={ing.unit ?? ''}
            onChange={e => update(idx, { unit: e.target.value })}
            placeholder="cup"
          />
          <input
            className={styles.cell}
            style={{ flex: 1 }}
            value={ing.name}
            onChange={e => update(idx, { name: e.target.value })}
            placeholder="Ingredient"
            required
          />
          <input
            className={styles.cell}
            style={{ flex: 1 }}
            value={ing.note ?? ''}
            onChange={e => update(idx, { note: e.target.value })}
            placeholder="Note"
          />
          <button type="button" className={styles.removeRow} onClick={() => remove(idx)}>×</button>
        </div>
      ))}
      <button type="button" className={styles.addRow} onClick={add}>+ Add ingredient</button>
    </div>
  )
}

function InstructionRows({
  items,
  onChange,
}: {
  items: InstructionRequest[]
  onChange: (items: InstructionRequest[]) => void
}) {
  const add = () => onChange([...items, { position: items.length + 1, body: '' }])

  const update = (idx: number, body: string) =>
    onChange(items.map((it, i) => (i === idx ? { ...it, body } : it)))

  const remove = (idx: number) =>
    onChange(items.filter((_, i) => i !== idx).map((it, i) => ({ ...it, position: i + 1 })))

  return (
    <div className={styles.rows}>
      {items.map((inst, idx) => (
        <div key={idx} className={styles.instRow}>
          <span className={styles.stepNum}>{idx + 1}</span>
          <textarea
            className={styles.instTextarea}
            value={inst.body}
            onChange={e => update(idx, e.target.value)}
            placeholder="Step…"
            rows={2}
          />
          <button type="button" className={styles.removeRow} onClick={() => remove(idx)}>×</button>
        </div>
      ))}
      <button type="button" className={styles.addRow} onClick={add}>+ Add step</button>
    </div>
  )
}
