import { Link } from 'react-router-dom'
import type { Recipe } from '../types'
import styles from './RecipeCard.module.css'

export default function RecipeCard({ recipe }: { recipe: Recipe }) {
  const time = recipe.total_time_minutes ?? recipe.cook_time_minutes
  return (
    <Link to={`/recipes/${recipe.id}`} className={styles.card}>
      {recipe.image_path ? (
        <img
          className={styles.image}
          src={`/images/${recipe.image_path}`}
          alt={recipe.title}
          loading="lazy"
        />
      ) : (
        <div className={styles.imagePlaceholder} />
      )}
      <div className={styles.body}>
        <h3 className={styles.title}>{recipe.title}</h3>
        {recipe.description && (
          <p className={styles.desc}>{recipe.description}</p>
        )}
        <div className={styles.meta}>
          {time && <span>{time} min</span>}
          {recipe.servings && <span>{recipe.servings} servings</span>}
        </div>
        {recipe.tags && recipe.tags.length > 0 && (
          <div className={styles.tags}>
            {recipe.tags.map(t => <span key={t} className={styles.tag}>{t}</span>)}
          </div>
        )}
      </div>
    </Link>
  )
}
