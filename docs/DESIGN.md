# CoachSpace — Design

> The visual direction, the rules that keep the app from looking generic, and the interaction mechanics.
> Status: direction chosen (D-009), typeface and mechanics decided (D-023 to D-025). Navigation and screens are
> in `UX_SPECIFICATION.md`. The Penpot file is the source for exact values; `src/theme/tokens.ts` mirrors it.

## 1. Direction: "Matchday"

Chosen from three explorations (page "Directions" in the Penpot file). References: Nike, Strava.

| Element | Rule |
|---|---|
| Colour | Black, white and **one** accent (signal orange `#FF4B14` in the exploration). Greys only as neutrals. No gradients. |
| Type | Display: Barlow Condensed, heavy, uppercase, tight — for titles, times and numbers only. Text: Inter Tight (D-025). Two families, no more. |
| Shape | **Square corners.** Little or no rounding on buttons, cards and avatars (owner's request). |
| Layout | Full-bleed blocks instead of floating cards. Hierarchy from size and contrast, not from boxes and shadows. |
| Numbers | The number the person came for (the time, how many are in) is the biggest thing on the screen. |
| Icons | One set, one weight: Phosphor (MIT licence), bold; filled for the active tab. |

To verify before the system is final: colour contrast (WCAG AA) for every text/background pair, and that the
accent is never the only signal of meaning.

## 2. Design requirements (set by the owner, D-010)

| Area | Requirement |
|---|---|
| Identity | Sporty, modern and functional; never a generic template. |
| Typography | At most two type families; a consistent hierarchy; functional text stays legible. |
| Spacing | A spacing system based on multiples of 4 and 8 px. |
| Components | Buttons, cards, forms and lists follow shared rules. |
| Accessibility | WCAG AA contrast where it applies, adequate touch targets, visible focus states. |
| Navigation | No unnecessary sections; the main flows take few steps. |
| Data | Priority to information that helps the coach decide or act. |
| Responsive | Phone, tablet and desktop behaviours are designed separately. |
| Quality | Test real screens with long data, empty states, errors and different sizes. |

How they are applied:

- **Spacing scale:** 4, 8, 12, 16, 20, 24, 32, 40, 48, 64. No other values.
- **Touch targets:** at least 44 x 44 pt on iOS and 48 x 48 dp on Android, whatever the visual size.
- **Contrast:** 4.5:1 for text, 3:1 for large text and for the parts of controls that carry meaning. Colour is
  never the only signal: answers also carry a label or an icon.
- **Focus:** every control has a visible focus state on web and with a keyboard.
- **Breakpoints:** phone (under 600 px) uses a bottom tab bar and one column; tablet (600 to 1023 px) and
  desktop (1024 px and up) get their own layouts, designed, not stretched.
- **Every screen is designed in its states:** filled, empty, loading, error, and with long names and long lists.
- **A screen earns its place** by helping someone decide or act; statistics with no decision attached stay out.

## 3. What makes an interface look generic, and what we do instead

Collected from practitioner write-ups (opinion, not hard evidence; sources at the end).

| Generic tell | Our rule |
|---|---|
| Default purple/indigo accent, lavender tints | One deliberate accent chosen for the brand |
| One default font everywhere | A display face with character, used sparingly |
| Rounded corners on everything, card inside card | Square corners; blocks and dividers, few cards |
| Gradients, glass effects, soft shadows as decoration | Flat colour; no shadows unless something really floats |
| Loose letter-spacing on headings | Tight tracking on large type |
| Every screen the same centred stack of cards | Each screen is built around its one main fact or action |
| Emoji as icons, mixed icon styles | One icon set |
| Decoration that "looks impressive in a screenshot" | Remove first; add only what carries information |

Working method that follows: a written system (spacing grid, two fonts, one accent) before screens; real
content in every design; design each state (empty, loading, error), not only the full one.

## 4. Interaction mechanics

| Mechanic | Where | Why | Status |
|---|---|---|---|
| **Slide to answer** | Player's event screen | Answering is the core action; a physical gesture with a clear end state is faster and more satisfying than two small buttons | Decided (D-023), with a button alternative |
| **Haptic feedback** | On answering, on sending a reminder, on errors | Confirms the action without reading | In |
| **Live countdown** | Next event | Makes the screen feel current | In |
| **Numbers that count up** | Answer totals, attendance | Draws the eye to what changed | Optional polish, after the beta |
| **Swipe on a row** | Event and member lists | Quick actions without opening a screen | Not in the first version: every action has a visible control |
| **Bottom sheets** | Team switcher, confirmations | Keeps the person in context | In (team switcher, confirmations, short choices) |
| **Pull to refresh, skeleton loading** | Lists | Expected in a modern app; no blank screens | Pull to refresh in; a spinner instead of skeletons in the first version |

Not included: streaks (D-011), badges, points or leaderboards between children; a reason for absence (D-024).

## 5. State of the Penpot file

| Page | Contents |
|---|---|
| Directions | The three explorations and the first coach home |
| Components | 23 Phosphor icons; `button` (primary, secondary, inverse); `tag` (solid, accent, outline); `avatar` (dark, light); `answer` (in, out, none); `event-row` (training, match); `member-row`; `tab-bar` (one variant per active tab); `top-bar` (light, dark) |
| Screens | Phone, 390 x 844. Start: sign in, join team. Coach: home, home (empty), event, attendance, calendar, new event, team, chat, documents, notifications, more. Player: home, event (answer), event (answered), can't come (obsolete, D-024) |

- **Tokens** (Tokens tab, sets `base` and `semantic`): colours, the spacing scale, radius 0, two font families and
  eleven type styles; every fill, gap, padding and text style in the screens is bound to a token.
- The phone screens are the accepted base (D-012). New screens are composed from these components following
  `UX_SPECIFICATION.md` (A-012); the Penpot updates that remain are listed in its §7.
- **Not designed yet:** tablet and desktop layouts (later, D-027).

## 6. Resources (all free)

| Need | Resource | Notes |
|---|---|---|
| Fonts | Barlow Condensed, Inter Tight (Google Fonts, open licence) | Bundled in the app |
| Icons | Phosphor Icons (MIT) | Has a React Native package |
| Animation | React Native Reanimated | Already in the project |
| Gestures | React Native Gesture Handler | Already in the project |
| Haptics | Expo Haptics | To add when first needed |
| Images | Expo Image | To add when first needed |
| Custom drawing (charts, pitch) | React Native Skia | Only if a screen needs it |

Versions and current APIs must be checked in the official documentation when each is added.

## 7. Sources

- [7 signs a UI has been vibe coded (The Fountain Institute)](https://www.thefountaininstitute.com/blog/signs-vibe-coded-ui)
- [How to de-slopify your designs (UX Collective)](https://uxdesign.cc/how-to-de-slopify-your-designs-4c40c57c1dc9)
- [How to apply professional design principles in AI app development (Expo)](https://expo.dev/blog/how-to-apply-professional-design-principles-in-ai-app-development.md)
- [Why AI design looks generic (Superdesign)](https://www.superdesign.dev/blog/why-ai-design-looks-generic)
- [Why over 100 million athletes are hooked on Strava (UX Collective)](https://uxdesign.cc/why-over-100-million-athletes-are-hooked-on-strava-545708e17552)
- [Understanding how athletes use the feed (Strava Design)](https://medium.com/strava-design/understanding-how-athletes-use-the-feed-aae986eaa818)
- [Nike Run Club gamification (Appcues)](https://goodux.appcues.com/blog/nike-run-club-gamification)
- [Phosphor Icons](https://phosphoricons.com)
