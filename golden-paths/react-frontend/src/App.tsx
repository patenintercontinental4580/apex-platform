import { AuthGuard } from './auth/AuthGuard'

function App() {
  return (
    <AuthGuard>
      <div>
        <h1>Apex Platform App</h1>
      </div>
    </AuthGuard>
  )
}

export default App
