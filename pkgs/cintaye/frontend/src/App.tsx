import { createBrowserRouter, RouterProvider, Navigate, Outlet } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { authApi } from './api/auth'
import Login from './pages/Login'
import Register from './pages/Register'
import RecipeList from './pages/RecipeList'
import RecipeDetail from './pages/RecipeDetail'
import RecipeEdit from './pages/RecipeEdit'
import ImportRecipe from './pages/ImportRecipe'
import HouseholdSettings from './pages/HouseholdSettings'
import Nav from './components/Nav'

function AuthGuard() {
  const { data: user, isLoading } = useQuery({
    queryKey: ['me'],
    queryFn: authApi.me,
    retry: false,
  })

  if (isLoading) return <div style={{ padding: '2rem' }}>Loading…</div>
  if (!user) return <Navigate to="/login" replace />

  return (
    <>
      <Nav user={user} />
      <main style={{ maxWidth: 900, margin: '0 auto', padding: '1.5rem 1rem' }}>
        <Outlet context={user} />
      </main>
    </>
  )
}

const router = createBrowserRouter([
  { path: '/login', element: <Login /> },
  { path: '/register', element: <Register /> },
  {
    element: <AuthGuard />,
    children: [
      { path: '/', element: <RecipeList /> },
      { path: '/recipes/new', element: <RecipeEdit /> },
      { path: '/recipes/import', element: <ImportRecipe /> },
      { path: '/recipes/:id', element: <RecipeDetail /> },
      { path: '/recipes/:id/edit', element: <RecipeEdit /> },
      { path: '/household', element: <HouseholdSettings /> },
    ],
  },
])

export default function App() {
  return <RouterProvider router={router} />
}
