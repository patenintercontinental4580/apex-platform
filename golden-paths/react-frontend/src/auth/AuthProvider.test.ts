import { describe, it, expect, vi, beforeEach } from 'vitest'

// Mock the MSAL browser module before importing AuthProvider
vi.mock('@azure/msal-browser', () => ({
  BrowserCacheLocation: {
    SessionStorage: 'sessionStorage',
    LocalStorage: 'localStorage',
  },
  PublicClientApplication: vi.fn().mockImplementation((config) => ({
    config,
    loginRedirect: vi.fn(),
    acquireTokenSilent: vi.fn(),
  })),
}))

import { msalConfig, loginRequest } from './AuthProvider'

describe('AuthProvider', () => {
  beforeEach(() => {
    // Provide required env vars
    vi.stubEnv('VITE_AZURE_CLIENT_ID', 'test-client-id')
    vi.stubEnv('VITE_AZURE_TENANT_ID', 'test-tenant-id')
  })

  it('uses VITE_AZURE_CLIENT_ID as clientId', () => {
    expect(msalConfig.auth.clientId).toBe(import.meta.env.VITE_AZURE_CLIENT_ID)
  })

  it('constructs authority from VITE_AZURE_TENANT_ID', () => {
    expect(msalConfig.auth.authority).toContain(import.meta.env.VITE_AZURE_TENANT_ID)
    expect(msalConfig.auth.authority).toContain('https://login.microsoftonline.com/')
  })

  it('sets redirectUri to window.location.origin', () => {
    expect(msalConfig.auth.redirectUri).toBe(window.location.origin)
  })

  it('uses SessionStorage cache location', () => {
    expect(msalConfig.cache?.cacheLocation).toBe('sessionStorage')
  })

  it('does not store auth state in cookie', () => {
    expect(msalConfig.cache?.storeAuthStateInCookie).toBe(false)
  })

  it('loginRequest includes required scopes', () => {
    expect(loginRequest.scopes).toContain('openid')
    expect(loginRequest.scopes).toContain('profile')
    expect(loginRequest.scopes).toContain('email')
  })
})
