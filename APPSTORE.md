# App Store submission — Monkey Fart Madness

Everything App Store Connect will ask for, written out and ready to paste.
Fields are in the order the form presents them.

**I can't submit this for you, and shouldn't.** The age rating and privacy sections are
legal declarations made in your name, and submission publishes to the store. Those are
yours to click. Everything else below is done.

- Bundle id `com.daviddef.monkeymadness` · Team `L9SAXP2E2W` · Version **2.0** build **11**
- Facts below were read out of the shipped archive and the source, not from memory.

---

## 1 · App Information

| Field | Value |
|---|---|
| **Name** (30) | `Monkey Fart Madness` |
| **Subtitle** (30) | `Dodge bananas. Fart them back.` |
| **Primary category** | Games → **Arcade** |
| **Secondary category** | Games → **Family** |
| **Content rights** | Contains no third-party content ✔ |
| **Age rating** | See §5 — **read that one before you answer** |

"Monkey Madness" alone was already taken; store names are globally unique.

**Privacy Policy URL** — done and **verified live** (HTTP 200, serving
[`docs/privacy.html`](docs/privacy.html) via GitHub Pages). Paste this straight in:

```
https://daviddef.github.io/Monkey-Madness/privacy.html
```

**Support URL** — `https://github.com/daviddef/Monkey-Madness`

---

## 2 · Pricing & Availability

Free. No in-app purchases. All territories.

---

## 3 · Version Information (2.0)

### Promotional text (170 — editable any time without review)

```
Monkeys hang from the branch and fart bananas at you. Dodge, then fart them right back — or pick their bananas up and throw them. Four hand-drawn worlds. No ads, ever.
```

### Description (4000)

```
Monkeys fart bananas at you. Fart them right back.

Monkey Fart Madness is a big, silly, laugh-out-loud dodge game. A branch full of monkeys moons you and parps bananas in your direction. Your job: don't get hit — and get them back.

TWO WAYS TO FIGHT BACK
• FART BACK — costs gas. A rising cloud of green gas that eats bananas on the way up and gasses any monkey it drifts into. Slow and wide: you aim it by standing under them.
• THROW A BANANA — costs ammo. Fast, auto-aimed, and a reliable bonk.

THEIR AMMO IS YOUR AMMO
Bananas that land in one piece become pickups — walk over them to reload. They fart them at you, you throw them back.

KNOW YOUR MONKEYS
• Machine-Gun Marmoset — rapid bursts of tiny bananas
• Boomer Baboon — charges up, then a wide black blast
• Sniper Chimp — a laser that tracks you, then locks red. Move!
• Balloon Monkey — floats out in the open. One hit and it POPS.
• Baby Monkey — tiny, squeaky, and worth double bananas
• King Kong-a-Toot — the boss, in three telegraphed phases

MOVE LIKE A MONKEY
Tap to fart-jump. Tap again in mid-air to double jump. Or hold it as you fall and ride your own gas down — the Mega-Hover.

FOUR WORLDS, ONE TAP APART
Loud!, Doodle, Inkwell and Plasticine each have their own art, their own fonts, their own music — and their own fart voices. Pick one right from the front screen.

Watch for brown bananas (soft, mushy, slows you down), black farted ones (ouch), falling coconuts, and slippery peels — jump those.

EARN IT, DON'T BUY IT
Bonk monkeys for Banana Coins, then spend them in the Banana Shop on hats and fart colours. Climb seven ranks from Fart Cadet to Gas Guardian. Come back for the Fart of the Day. Every single unlock is earned by playing. There is nothing to buy.

Built for kids and the adults laughing next to them. Big buttons, two control styles, and an Easy mode with a genuinely gentler barrage — not just extra hearts. Ten levels and a boss.

No ads. No in-app purchases. No accounts. No tracking. Nothing to buy — ever.
```

### Keywords (100, comma-separated, no spaces)

```
funny,silly,kids,arcade,jump,family,cartoon,comedy,gross,toilet,humor,ape,jungle,tap,boss
```

Deliberately excludes *monkey*, *fart*, *madness*, *dodge* and *banana* — Apple already
indexes the name and subtitle, so repeating them there is wasted space.

### What's New in 2.0

```
• NEW: DOUBLE JUMP — parp again in mid-air to go higher
• NEW: Mega-Hover — hold jump as you fall to ride your own gas down
• NEW: Falling coconuts — watch for the shadow!
• NEW: Music for every world (off by default — turn it on in Settings)
• Tidier main menu, with everything adjustable now under Settings
• FIXED: left and right sometimes not responding
```

### Copyright

```
2026 David de Franceski
```

---

## 4 · App Privacy

Answer: **"Data Not Collected"** — every category, no exceptions.

This isn't a hopeful reading; it's checkable. The source contains zero networking symbols
(no `URLSession`, no `WKWebView`, no sockets), zero analytics or ad SDKs, zero StoreKit,
and zero usage-description keys in `Info.plist`. There is no code path that could send
anything anywhere.

Saved progress (`mm_coins`, `mm_hat`, `mm_theme`, `fartback_best`, …) lives in
`UserDefaults` on-device. Apple does not count on-device-only storage as collection.

---

## 5 · Age Rating — read this before answering

**I previously suggested 4+ in this file. That was wrong, and I've corrected it.**

Apple's threshold for **4+ is that the app contains *no* cartoon violence and *no* crude
humor whatsoever**. **9+** is the first tier that permits "infrequent cartoon or fantasy
violence, profanity or crude humor." A game named *Monkey Fart Madness*, whose core loop is
throwing projectiles at monkeys, does not clear a "none" bar on either count.

My honest read of the questionnaire:

| Question | Answer | Why |
|---|---|---|
| Cartoon or Fantasy Violence | **Infrequent/Mild** | Bloodless slapstick — monkeys get gassed and stunned, never hurt |
| Profanity or Crude Humor | **Infrequent/Mild** | It's a fart game. This one isn't arguable. |
| Realistic Violence | None | |
| Horror/Fear Themes | None | |
| Mature/Suggestive Themes | None | Butts are played for laughs, nothing suggestive |
| Medical/Treatment info | None | |
| Gambling, Contests | None | |
| Unrestricted Web Access | No | No links out of the app at all |
| User-Generated Content / Chat | No | |
| In-app controls (parental) | None needed | Nothing to gate |

**That lands you at 9+, most likely.** Two honest caveats, because this is your declaration
and not mine:

1. **You could argue "Frequent" rather than "Infrequent" for crude humor** — farting is the
   whole game, not an occasional gag. Frequent crude humor pushes to **13+**, which would be
   absurd for this game but is the literal reading. Most kids' fart-comedy titles answer
   Infrequent/Mild and are rated 9+. I'd answer Infrequent/Mild and feel fine about it.
2. **Plenty of 4+ games arguably contain mild cartoon violence** (Mario stomps goombas) and
   their developers answered "None". You may be tempted. **Don't** — under-declaring is the
   thing Apple re-rates apps for, and a forced re-rating after launch is worse than shipping
   9+ on day one.

**The irony worth naming: this game is built for a 6-year-old and will probably rate 9+.**
That changes nothing for Mateo — you install it, he plays it. It only affects store
placement.

### Kids Category — my recommendation: **don't**

You qualify (no tracking, no outbound links, no third-party SDKs), but it's a standing
commitment, it brings extra review scrutiny, and a 9+ rating would put you in the 9–11
bracket anyway — which isn't the audience. Ship as a normal Games app.

---

## 6 · Export Compliance

Already answered in the binary: `ITSAppUsesNonExemptEncryption = false` is in
`Info.plist`, so App Store Connect won't prompt. Correct — no networking, no encryption
beyond what iOS itself does.

---

## 7 · Screenshots

**Required:** iPhone 6.9" (1320×2868). **Also required because you ship iPad**
(`TARGETED_DEVICE_FAMILY = 1,2`): iPad 13" (2064×2752). Other sizes auto-scale from these.

**Status: not done — this is the one blocker I couldn't clear.** I captured a set from the
Simulator and threw them away, because another project's simulator session was running
concurrently on the same device and kept launching its app over ours: one "screenshot of
Doodle" was actually a completely different app's title screen. Four plausible-looking wrong
files are worse than none, so they're deleted.

Easiest fix is to take them by hand on your own iPhone from the TestFlight build
(Volume Up + Side button) — that also has the happy side effect of making you play it.
Or say the word and I'll retry on a freshly-created, uncontested simulator.

Suggested order, so the four art styles are the first thing anyone sees:

1. **Loud!** mid-barrage — the hook
2. **Doodle** — a completely different-looking game
3. **Inkwell** — ditto
4. **Plasticine** — ditto
5. **The boss** — King Kong-a-Toot
6. **Banana Shop** — proves "all earned, nothing bought"

> If you don't want to ship iPad on day one, set `TARGETED_DEVICE_FAMILY: "1"` in
> `ios/project.yml` and the iPad screenshot requirement disappears. Say the word.

---

## 8 · App Review notes (paste into "Notes")

```
No account or sign-in is required — the game opens straight into playable content.

There is no networking of any kind in this app: no analytics, no ads, no third-party
SDKs, no in-app purchases. All progress is stored on-device in UserDefaults.

To reach the boss quickly: Settings → Difficulty → Easy, then play through. The four
art styles are switched by tapping the coloured lanes on the title screen.

This is a family game built for my six-year-old son. The humour is entirely
fart-and-banana slapstick; nothing is harmed on screen.
```

---

## Checklist

- [x] Bundle id, team, version wired through from `project.yml`
- [x] `ITSAppUsesNonExemptEncryption=false`
- [x] 1024×1024 icon, opaque RGB, no alpha
- [x] Portrait only, iPhone + iPad
- [x] Name, subtitle, description, keywords, promo text, What's New — §1/§3
- [x] Privacy policy written, published, and verified live at the URL in §1
- [ ] **Screenshots** — see §7, not done, needs a real device or a clean simulator
- [ ] **You:** answer the age-rating questionnaire (§5)
- [ ] **You:** confirm "Data Not Collected" in App Privacy (§4)
- [ ] **You:** upload screenshots + paste copy, then Submit

## Before you press Submit

1. **It has still never been played by hand on a physical device.** Everything is verified
   in a browser harness, a node simulation and the Simulator. None of those can tell you
   whether the control bar suits a 6-year-old's thumbs.
2. **Build 11's touch fix is specifically unverifiable in the Simulator** — the home-indicator
   gesture conflict it fixes doesn't reproduce there. It needs Mateo's thumbs on TestFlight
   before it goes public.
3. **The fart samples are your own recordings** (8 of them). If any were sourced elsewhere,
   check licensing before shipping commercially — §1 declares no third-party content.
4. The home-screen label still truncates to "Monkey Fart…". Fixable in a minute if it bugs
   you (`CFBundleDisplayName` → something shorter like "Fart Madness").
