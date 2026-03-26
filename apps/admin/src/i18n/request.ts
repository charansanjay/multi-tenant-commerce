// This file tells next-intl how to load the correct locale messages for each request

import { getRequestConfig } from 'next-intl/server';
import { cookies } from 'next/headers';

export default getRequestConfig(async () => {
  const cookieStore = await cookies();
  const locale = cookieStore.get('locale')?.value ?? 'en';

  const validLocales = ['en', 'cs', 'de'];
  const resolvedLocale = validLocales.includes(locale) ? locale : 'en';

  return {
    locale: resolvedLocale,
    messages: (await import(`../i18n/${resolvedLocale}.json`)).default,
  };
});
