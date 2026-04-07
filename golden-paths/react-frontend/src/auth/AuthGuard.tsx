import { ReactNode } from 'react'
import { useMsal } from '@azure/msal-react'
import { loginRequest } from './AuthProvider'

interface AuthGuardProps {
  children: ReactNode
}

export function AuthGuard({ children }: AuthGuardProps) {
  const { instance, accounts, inProgress } = useMsal()

  if (inProgress !== 'none') {
    return <div>Authenticating...</div>
  }

  if (accounts.length === 0) {
    instance.loginRedirect(loginRequest)
    return null
  }

  return <>{children}</>
}
