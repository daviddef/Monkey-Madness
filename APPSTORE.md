# App Store submission notes — Monkey Fart Madness

Draft copy + a checklist for the listing. **Nothing here is submitted automatically** —
paste what you like into App Store Connect. Everything below is a suggestion, not a decision.

---

## Name & subtitle

| Field | Value | Limit |
|---|---|---|
| App name | `Monkey Fart Madness` | 30 |
| Subtitle | `Dodge bananas. Fart them back.` | 30 |

("Monkey Madness" was already taken — names are globally unique across the store.)

## Promotional text (170)

> Monkeys hang from the branch and fart bananas at you. Dodge, then fart them
> right back — or pick their bananas up and throw them. Four hand-drawn worlds.

## Description

> **Monkeys fart bananas at you. Fart them right back.**
>
> Monkey Fart Madness is a big, silly, laugh-out-loud dodge game. A branch full of
> monkeys moons you and parps bananas in your direction. Your job: don't get hit —
> and get them back.
>
> **Two ways to fight back**
> • 💨 **FART BACK** — costs gas. A rising cloud of green gas that eats bananas on
>   the way up and gasses any monkey it drifts into. Slow and wide: aim it by
>   standing under them.
> • 🍌 **THROW A BANANA** — costs ammo. Fast, auto-aimed, and a reliable bonk.
>
> **Their ammo is your ammo.** Bananas that land in one piece become pickups — walk
> over them to reload. They fart them at you, you throw them back.
>
> **Know your monkeys**
> • Machine-Gun Marmoset — rapid bursts of tiny bananas
> • Boomer Baboon — charges up, then a wide black blast
> • Sniper Chimp — a laser that tracks you, then locks red. Move!
> • King Kong-a-Toot — the boss, in three telegraphed phases
>
> **Four worlds, one tap apart.** Loud!, Doodle, Inkwell and Plasticine each have
> their own art, their own fonts — and their own fart voices.
>
> Watch for brown bananas (soft, mushy, slows you down), black farted ones (ouch),
> and slippery peels — jump those.
>
> **Earn it, don't buy it.** Bonk monkeys for 🍌 Banana Coins, then spend them in the
> Banana Shop on hats and fart colours. Climb seven ranks from Fart Cadet to Gas
> Guardian. Come back for the Fart of the Day. Every single unlock is earned by
> playing — there is nothing to buy.
>
> Built for kids and the adults laughing next to them. Big buttons, two control
> styles, an Easy mode with a genuinely gentler barrage, ten levels and a boss.
>
> **No ads. No in-app purchases. No accounts. Nothing to buy — ever.**

## Keywords (100, comma-separated, no spaces)

`fart,monkey,banana,funny,kids,dodge,silly,arcade,jump,family,cartoon,comedy,gross,pixel`

## What's New (for 1.7)

> • NEW: 🍌 Banana Coins — bonk monkeys, collect coins, spend them in the Banana Shop
> • NEW: Banana Shop — 6 hats and 5 fart colours. All earned. No ads, no purchases.
> • NEW: Ranks — climb from Fart Cadet all the way to Gas Guardian
> • NEW: Fart of the Day — a new twist every day, plus a daily coin bonus
> • NEW: Easy mode — 6 lives and a gentler barrage, for younger players
> • NEW: Magnet power-up — coins fly straight to you
> • Fixed: holding left or right sometimes wouldn't move you

## Earlier: 1.3–1.6

> • Fart and throw are now two different moves — gas clouds vs. auto-aimed bananas
> • Bananas that land can be picked up and thrown back
> • Sniper Chimp — watch for the red laser lock
> • Pause button with a main menu
> • All four art styles on iPhone — now picked by tapping the swim lanes
> • Fills the whole screen, and haptics on every bonk

---

## Checklist

- [x] Bundle id `com.daviddef.monkeymadness`, Team `L9SAXP2E2W`
- [x] Version wired through from `project.yml` (was silently ignored — see git log)
- [x] `ITSAppUsesNonExemptEncryption=false` — no networking, no encryption, exempt
- [x] 1024×1024 icon, opaque RGB, no alpha
- [x] Portrait only, iPhone + iPad (`TARGETED_DEVICE_FAMILY 1,2`)
- [ ] **Age rating** — suggest 4+. Answer the questionnaire honestly: cartoon
      humour, no violence beyond slapstick, no user content, no data collection.
- [ ] **Privacy** — "Data Not Collected" for every category. The app has no
      networking at all; `best score` and settings live in `UserDefaults` on-device.
      A privacy policy URL is still required for the listing.
- [ ] **Screenshots** — 6.9" and 6.5" iPhone required. Suggest one per world plus
      the boss, so the four art styles are the first thing anyone sees.
- [ ] **Kids Category** — only if you want it. It brings extra scrutiny (no
      third-party analytics, parental gates on outbound links). We qualify today
      because there is nothing outbound, but it's a commitment to keep it that way.
- [ ] Support URL (the GitHub repo works)

## Things I'd flag before a public release

1. **It has never been played by hand on a physical device.** Everything is verified
   in the browser harness and the Simulator. The Simulator can't tell you whether
   the five-button bar suits a 6-year-old's thumbs, or whether the haptics land.
   Watch Mateo play a run before pushing to the store.
2. **The control layout is the least-settled design decision.** Five buttons on a
   480pt-wide canvas is tight. The Buttons ⇄ Zones toggle exists to A/B exactly this.
3. **The fart samples are David's own recordings** (8 of them). If any were sourced
   elsewhere, check licensing before shipping commercially.
