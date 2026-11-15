import { createInstance } from 'i18next';
import { initReactI18next, useTranslation } from 'react-i18next';

import { en } from './en';
import { es } from './es';

export const languages = ['en', 'es'] as const;
export type Language = (typeof languages)[number];

/** Locale used to format dates and times for each interface language. */
export const dateLocale: Record<Language, string> = { en: 'en-GB', es: 'es-ES' };

// English by default; Spanish is chosen in the More tab (project rule, D-005).
const i18n = createInstance();

i18n.use(initReactI18next).init({
  resources: { en: { translation: en }, es: { translation: es } },
  lng: 'en',
  fallbackLng: 'en',
  interpolation: { escapeValue: false },
});

/** The interface language. A hook, so screens update when the language changes. */
export function useLanguage(): Language {
  const { i18n: instance } = useTranslation();
  return instance.language === 'es' ? 'es' : 'en';
}

export default i18n;
