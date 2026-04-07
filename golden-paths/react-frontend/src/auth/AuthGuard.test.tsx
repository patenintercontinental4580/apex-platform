import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { AuthGuard } from './AuthGuard'

// Mock useMsal hook
const mockLoginRedirect = vi.fn()
const mockUseMsal = vi.fn()

vi.mock('@azure/msal-react', () => ({
  useMsal: () => mockUseMsal(),
  MsalProvider: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}))

vi.mock('./AuthProvider', () => ({
  loginRequest: { scopes: ['openid'] },
}))

describe('AuthGuard', () => {
  it('shows loading state when auth is in progress', () => {
    mockUseMsal.mockReturnValue({
      instance: { loginRedirect: mockLoginRedirect },
      accounts: [],
      inProgress: 'login',
    })

    render(<AuthGuard><div>Protected Content</div></AuthGuard>)
    expect(screen.getByText('Authenticating...')).toBeTruthy()
    expect(screen.queryByText('Protected Content')).toBeNull()
  })

  it('redirects to login when no accounts and inProgress is none', () => {
    mockUseMsal.mockReturnValue({
      instance: { loginRedirect: mockLoginRedirect },
      accounts: [],
      inProgress: 'none',
    })

    render(<AuthGuard><div>Protected Content</div></AuthGuard>)
    expect(mockLoginRedirect).toHaveBeenCalledOnce()
    expect(screen.queryByText('Protected Content')).toBeNull()
  })

  it('renders children when user is authenticated', () => {
    mockUseMsal.mockReturnValue({
      instance: { loginRedirect: mockLoginRedirect },
      accounts: [{ username: 'user@example.com', homeAccountId: '123' }],
      inProgress: 'none',
    })

    render(<AuthGuard><div>Protected Content</div></AuthGuard>)
    expect(screen.getByText('Protected Content')).toBeTruthy()
  })

  it('does not call loginRedirect when authenticated', () => {
    mockLoginRedirect.mockClear()
    mockUseMsal.mockReturnValue({
      instance: { loginRedirect: mockLoginRedirect },
      accounts: [{ username: 'user@example.com', homeAccountId: '123' }],
      inProgress: 'none',
    })

    render(<AuthGuard><div>Protected Content</div></AuthGuard>)
    expect(mockLoginRedirect).not.toHaveBeenCalled()
  })

  it('renders multiple children when authenticated', () => {
    mockUseMsal.mockReturnValue({
      instance: { loginRedirect: mockLoginRedirect },
      accounts: [{ username: 'user@example.com', homeAccountId: '123' }],
      inProgress: 'none',
    })

    render(
      <AuthGuard>
        <div>Child One</div>
        <div>Child Two</div>
      </AuthGuard>
    )
    expect(screen.getByText('Child One')).toBeTruthy()
    expect(screen.getByText('Child Two')).toBeTruthy()
  })
})
