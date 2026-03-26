import { createProxyClient } from '@/lib/supabase/proxy';
import { NextResponse, type NextRequest } from 'next/server';
import { ROLE_ROUTE_MAP } from '@/lib/constants';

export async function proxy(request: NextRequest) {
  const { supabase, response } = createProxyClient(request);
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { pathname } = request.nextUrl;

  // Not authenticated — redirect to login
  if (!user && pathname !== '/login') {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  // Authenticated on login page — redirect to dashboard
  if (user && pathname === '/login') {
    return NextResponse.redirect(new URL('/dashboard', request.url));
  }

  if (user) {
    const role = user.app_metadata?.role as string | undefined;

    // Missing tenant context — account setup issue
    if (!user.app_metadata?.tenant_id) {
      return NextResponse.redirect(new URL('/login?error=account_error', request.url));
    }

    // Role-restricted route check
    const allowedRoles = ROLE_ROUTE_MAP[pathname];
    if (allowedRoles && role && !allowedRoles.includes(role as 'admin' | 'manager' | 'staff')) {
      return NextResponse.redirect(new URL('/dashboard', request.url));
    }
  }

  return response;
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)'],
};
