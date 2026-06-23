const STORAGE_KEY = 'tilawa_admin.login';

export interface AdminLoginPreferences {
  email: string;
  password: string;
}

export function loadAdminLoginPreferences(): AdminLoginPreferences | null {
  if (typeof localStorage === 'undefined') {
    return null;
  }

  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) {
      return null;
    }

    const parsed = JSON.parse(raw) as Partial<AdminLoginPreferences>;
    if (
      typeof parsed.email === 'string' &&
      typeof parsed.password === 'string'
    ) {
      return { email: parsed.email, password: parsed.password };
    }
  } catch {
    return null;
  }

  return null;
}

export function saveAdminLoginPreferences(
  email: string,
  password: string,
): void {
  if (typeof localStorage === 'undefined') {
    return;
  }

  localStorage.setItem(STORAGE_KEY, JSON.stringify({ email, password }));
}
