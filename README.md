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
- **Two ways to fight back — they're different weapons:**
  - **💨 FART BACK** (costs **gas**) — raises a **fart barrier** that blocks whatever is
    already above you, then sends a **rising cloud of gas** up the screen. It eats every
    banana in its path and **gasses** any monkey it drifts into (**60 × combo**). It takes
    ~1.5s to reach the branch, so monkeys can swing clear — you aim it by *standing under
    them*. Slow, wide, and great against a barrage.
  - **🍌 THROW BANANA** (costs **1 ammo**) — a fast, **auto-aimed** throw at the nearest
    monkey. Reliable **stun** for **100 × combo**, but you can run out.
- **Ammo comes from the monkeys**: bananas that land intact become **pickups** — walk over
  them to reload (up to 6). Black farted ones just splat. So the loop is: *they fart bananas
  at you → you dodge → you pick them up → you throw them back.*
- **Banana types**: 🟡 regular (–1 life) · 🟤 **brown mushy** (soft splat, slows you, no
  life lost) · ⚫ **black farted** (dangerous, stink trail, –1 life).
- **Peels**: bananas that hit the ground can leave a peel — **jump over it** or you
  **slip and fall** (lose control for a moment).
- **Monkey types**: regular · **Machine-Gun Marmoset** (small, rapid bursts of tiny
  fast bananas) · **Boomer Baboon** (big, telegraphs a **!!** charge then fires a wide
  3-banana black blast). Variety ramps up as you survive longer.
- **Gas meter**: farting costs gas that recharges, so you can't just spam it.
- Chain stuns to build your combo. Getting hit resets it. You have 4 lives.

### Controls
| | Touch | Keyboard |
|---|---|---|
| Move | on-screen ◀ ▶ | ← → |
| Fart-jump | ⤒ button | Space / ↑ |
| Fart back | 💨 button | F / ↓ |
| Throw banana | 🍌 button | B / X |

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
