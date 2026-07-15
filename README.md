# 🍌 Monkey Madness: Fart Fury 💨

A hilarious, addictive iOS-bound dodge game where flatulent monkeys rocket bananas
at you out of their butts — and you fart them **right back**. Built belly-laughs
first, skill second.

This repo evolves the original *Mateo's Monkey Madness* (a browser dodge game made
for a 6-year-old) into a richer, funnier, fart-powered game with real skill and
juice.

---

## What's in here

| File | What it is |
|------|------------|
| **[`MonkeyMadness_FartBack_Themed.html`](MonkeyMadness_FartBack_Themed.html)** | 💥 **Flagship playable build** — the Fart Back core with a **swappable art-direction theme system**. Pick your world (Loud! / Doodle / Inkwell / Plasticine) right on the start screen. Fully vector art, no emoji. |
| **[`MonkeyMadness_ArtDirections.html`](MonkeyMadness_ArtDirections.html)** | 🎨 **Art-direction explorations** — four fresh, distinct visual worlds, each rendering the same scene so you can compare. Research-backed. |
| **[`MonkeyMadness_FartBack_Prototype.html`](MonkeyMadness_FartBack_Prototype.html)** | 🎮 **First prototype** of the Fart Back core loop (emoji art). Kept for reference. |
| **[`MonkeyMadness_FartFury_Roadmap.html`](MonkeyMadness_FartFury_Roadmap.html)** | 🗺️ **Design & gameplay roadmap** — vision, gameplay directions, comedy toolkit, retention loop, phased build plan. |

---

## ▶️ Play the prototype

Open `MonkeyMadness_FartBack_Prototype.html` in any modern browser (desktop or
mobile). No build step, no dependencies. **Turn the sound on** — the synthesized
farts are ~70% of the comedy.

### How to play
- **Dodge** — monkeys moon you and **fart bananas** out their butts (with a gust + "PBBT!").
- Tap **💨 FART BLAST** to fire a **banana out of your own butt** at the nearest monkey
  *and* raise a **fart barrier** above you that blocks incoming bananas. A landed shot
  **stuns** a monkey for **100 × combo**.
- **Banana types**: 🟡 regular (–1 life) · 🟤 **brown mushy** (soft splat, slows you, no
  life lost) · ⚫ **black farted** (dangerous, stink trail, –1 life).
- **Peels**: bananas that hit the ground can leave a peel — **jump over it** or you
  **slip and fall** (lose control for a moment).
- **Gas meter**: blasting costs gas that recharges, so you can't just spam it.
- Chain stuns to build your combo. Getting hit resets it. You have 4 lives.

### Controls
| | Touch | Keyboard |
|---|---|---|
| Move | on-screen ◀ ▶ | ← → |
| Fart-jump | ⤒ button | Space / ↑ |
| Fart blast | 💨 button | F / ↓ |

---

## 🎨 Art direction — swappable themes

The look-and-feel is a **theme**, not baked in. Each world is defined as data + a few
draw hooks in a `THEMES` object, so adding a new one doesn't touch the gameplay. Four
ship today, switchable from the start screen (and remembered):

- **Loud!** — maximalist WarioWare chaos: halftone dots, clashing candy colours, fat outlines, airhorn farts.
- **Doodle** — a kid's crayon sketchbook: ruled paper, wobbly lines, googly eyes, kazoo farts.
- **Inkwell** — 1930s rubber-hose cartoon: aged paper, film grain, pie-cut eyes, brass raspberries.
- **Plasticine** — handmade claymation: warm clay, soft shadows, squishy, wet-squelch farts.

Each theme also carries its own **sound personality** (the fart synth reads the active theme).

## 🗺️ The plan

The roadmap recommends: **build the dodge core, then layer the player-fart counter
("Fart Back"), and bank vertical/arena modes for later updates.**

- **Phase 0 — Prototype** *(this repo)*: prove the core gag is funny.
- **Phase 1 — MVP slice**: full juice pass, 3 monkey types, deflect, 10 levels + boss.
- **Phase 2 — Rich graphics + retention**: parallax, particles, coins, cosmetic
  fart-skins, daily challenge.
- **Phase 3 — Modes + polish**: jetpack-climber mode, co-op arena, App Store assets.

Target platform is a native **iOS SpriteKit** app; the prototype validates the feel
in plain HTML5 canvas + Web Audio first.

---

*Made for Mateo. 🐒*
