export const PAGE_SIZE = 50;

export const ROLES = {
  ADMIN: 'admin',
  MANAGER: 'manager',
  STAFF: 'staff',
} as const;

export type Role = (typeof ROLES)[keyof typeof ROLES];
