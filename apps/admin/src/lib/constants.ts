export const PAGE_SIZE = 50;

export const ROLES = {
  ADMIN: 'admin',
  MANAGER: 'manager',
  STAFF: 'staff',
} as const;

export type Role = (typeof ROLES)[keyof typeof ROLES];

export const ROLE_ROUTE_MAP: Record<string, Array<Role>> = {
  '/settings': ['admin'],
  '/audit-logs': ['admin'],
  '/sales': ['admin'],
};
