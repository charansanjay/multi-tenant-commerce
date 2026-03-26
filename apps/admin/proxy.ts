import { createProxyClient } from '@/lib/supabase/proxy';
import { type NextRequest } from 'next/server';

export async function proxy(request: NextRequest) {
  const { supabase, response } = createProxyClient(request);

  // Refresh the session — must be called before any redirects
  await supabase.auth.getUser();

  return response;
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)'],
};
