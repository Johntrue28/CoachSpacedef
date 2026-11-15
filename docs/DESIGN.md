# CoachSpace — Design

> The visual direction, the rules that keep the app from looking generic, and the interaction mechanics.
> Status: direction chosen by the owner (D-009); the design system and screens are being built in Penpot.
> The Penpot file is the source for exact values; this document holds the rules.

## 1. Direction: "Matchday"

Chosen from three explorations (page "Directions" in the Penpot file). References: Nike, Strava.

| Element | Rule |
|---|---|
| Colour | Black, white and **one** accent (signal orange `#FF4B14` in the exploration). Greys only as neutrals. No gradients. |
| Type | Display: Barlow Condensed, heavy, uppercase, tight — for titles, times and numbers only. Text: Inter. Two families, no more. |
| Shape | **Square corners.** Little or no rounding on buttons, cards and avatars (owner's request). |
| Layout | Full-bleed blocks instead of floating cards. Hierarchy from size and contrast, not from boxes and shadows. |
| Numbers | The number the person came for (the time, how many are in) is the biggest thing on the screen. |
| Icons | One set, one weight: Phosphor (MIT licence), bold; filled for the active tab. |

To verify before the system is final: colour contrast (WCAG AA) for every text/background pair, and that the
accent is never the only signal of meaning.

## 2. What makes an interface look generic, and what we do instead

Collected from practitioner write-ups (opinion, not hard evidence; sources at the end).

| Generic tell | Our rule |
|---|---|
| Default purple/indigo accent, lavender tints | One deliberate accent chosen for the brand |
| Inter (or one default font) everywhere | A display face with character, used sparingly |
| Rounded corners on everything, card inside card | Square corners; blocks and dividers, few cards |
| Gradients, glass effects, soft shadows as decoration | Flat colour; no shadows unless something really floats |
| Loose letter-spacing on headings | Tight tracking on large type |
| Every screen the same centred stack of cards | Each screen is built around its one main fact or action |
| Emoji as icons, mixed icon styles | One icon set |
| Decoration that "looks impressive in a screenshot" | Remove first; add only what carries information |

Working method that follows: a written system (spacing grid, two fonts, one accent) before screens; real
content in every design; design each state (empty, loading, error), not only the full one.

## 3. Interaction mechanics (proposed; each needs the owner's approval before it is built)

| Mechanic | Where | Why |
|---|---|---|
| **Slide to answer** | Player's event screen | Answering is the core action; a physical gesture with a clear end state is faster and more satisfying than two small buttons |
| **Haptic feedback** | On answering, on sending a reminder, on errors | Confirms the action without reading |
| **Live countdown** | Next event | Makes the screen feel current |
| **Numbers that count up** | Answer totals, attendance | Draws the eye to what changed |
| **Swipe on a row** | Event and member lists | Quick actions without opening a screen |
| **Bottom sheets** | Absence reason, quick create | Keeps the person in context |
| **Pull to refresh, skeleton loading** | Lists | Expected in a modern app; no blank screens |
| **Team streak** | Coach's home | A light, Strava-style motivator built from attendance statistics (level 2) |

Not proposed: badges, points or leaderboards between children. Open question for the owner: how far to go
with motivation features in an app used by minors.

## 4. Resources (all free)

| Need | Resource | Notes |
|---|---|---|
| Fonts | Barlow Condensed, Inter (Google Fonts, open licence) | Bundled in the app |
| Icons | Phosphor Icons (MIT) | Has a React Native package |
| Animation | React Native Reanimated | Already in the project |
| Gestures | React Native Gesture Handler | Already in the project |
| Haptics | Expo Haptics | To add when first needed |
| Images | Expo Image | To add when first needed |
| Custom drawing (charts, pitch) | React Native Skia | Only if a screen needs it |

Versions and current APIs must be checked in the official documentation when each is added.

## 5. Sources

- [7 signs a UI has been vibe coded (The Fountain Institute)](https://www.thefountaininstitute.com/blog/signs-vibe-coded-ui)
- [How to de-slopify your designs (UX Collective)](https://uxdesign.cc/how-to-de-slopify-your-designs-4c40c57c1dc9)
- [How to apply professional design principles in AI app development (Expo)](https://expo.dev/blog/how-to-apply-professional-design-principles-in-ai-app-development.md)
- [Why AI design looks generic (Superdesign)](https://www.superdesign.dev/blog/why-ai-design-looks-generic)
- [Why over 100 million athletes are hooked on Strava (UX Collective)](https://uxdesign.cc/why-over-100-million-athletes-are-hooked-on-strava-545708e17552)
- [Understanding how athletes use the feed (Strava Design)](https://medium.com/strava-design/understanding-how-athletes-use-the-feed-aae986eaa818)
- [Nike Run Club gamification (Appcues)](https://goodux.appcues.com/blog/nike-run-club-gamification)
- [Phosphor Icons](https://phosphoricons.com)
