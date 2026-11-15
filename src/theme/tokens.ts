/**
 * Design tokens. They mirror the token sets "base" and "semantic" in the Penpot file.
 * Screens and components use the semantic values only; raw values live here and nowhere else.
 */
const base = {
  black: '#0B0B0C',
  white: '#FFFFFF',
  orange: '#FF4B14',
  grey100: '#F3F3F0',
  grey200: '#E4E4E0',
  grey400: '#B5B5B0',
  grey600: '#6B6B6B',
  grey700: '#4A4A4A',
  grey800: '#262626',
} as const;

export const color = {
  bg: {
    default: base.white,
    inverse: base.black,
    subtle: base.grey100,
    accent: base.orange,
    inverseSubtle: base.grey800,
  },
  text: {
    default: base.black,
    muted: base.grey600,
    inverse: base.white,
    inverseMuted: base.grey400,
    onAccent: base.black,
    accent: base.orange,
  },
  border: {
    default: base.grey200,
    strong: base.black,
    inverse: base.grey700,
  },
  answer: {
    in: base.white,
    out: base.orange,
    none: base.grey700,
  },
} as const;

/** Spacing scale (multiples of 4 and 8). No other values. */
export const space = {
  0: 0,
  4: 4,
  8: 8,
  12: 12,
  16: 16,
  20: 20,
  24: 24,
  32: 32,
  40: 40,
  48: 48,
  64: 64,
} as const;

export const radius = { none: 0 } as const;

/** Minimum touch target: 44 pt on iOS, 48 dp on Android. 48 covers both. */
export const touchTarget = 48;

const display = 'BarlowCondensed_800ExtraBold';
const displayBold = 'BarlowCondensed_700Bold';
const text = 'InterTight_400Regular';
const textSemiBold = 'InterTight_600SemiBold';

/** Type styles, named as in Penpot (type.display.*, type.text.*). Line heights are in points. */
export const type = {
  displayHero: { fontFamily: display, fontSize: 120, lineHeight: 108, letterSpacing: -2 },
  displayXl: { fontFamily: display, fontSize: 64, lineHeight: 61, letterSpacing: -1, textTransform: 'uppercase' },
  displayTitle: { fontFamily: display, fontSize: 48, lineHeight: 48, textTransform: 'uppercase' },
  displayStat: { fontFamily: display, fontSize: 40, lineHeight: 36 },
  displayHeading: { fontFamily: display, fontSize: 28, lineHeight: 28, textTransform: 'uppercase' },
  displayButton: {
    fontFamily: displayBold,
    fontSize: 20,
    lineHeight: 24,
    letterSpacing: 0.6,
    textTransform: 'uppercase',
  },
  title: { fontFamily: textSemiBold, fontSize: 16, lineHeight: 20 },
  body: { fontFamily: text, fontSize: 14, lineHeight: 20 },
  bodyStrong: { fontFamily: textSemiBold, fontSize: 14, lineHeight: 20 },
  label: { fontFamily: textSemiBold, fontSize: 12, lineHeight: 14, letterSpacing: 0.8, textTransform: 'uppercase' },
  labelSmall: {
    fontFamily: textSemiBold,
    fontSize: 10,
    lineHeight: 12,
    letterSpacing: 0.6,
    textTransform: 'uppercase',
  },
} as const;

export type TypeVariant = keyof typeof type;
export type TextColor = keyof typeof color.text;
