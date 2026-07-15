import UIKit

// MARK: - Colour helper
private func hex(_ s: String, _ a: CGFloat = 1) -> UIColor {
    var h = s; if h.hasPrefix("#") { h.removeFirst() }
    var v: UInt64 = 0; Scanner(string: h).scanHexInt64(&v)
    return UIColor(red: CGFloat((v >> 16) & 0xff)/255, green: CGFloat((v >> 8) & 0xff)/255,
                   blue: CGFloat(v & 0xff)/255, alpha: a)
}
private func R(_ a: CGFloat, _ b: CGFloat) -> CGFloat { CGFloat.random(in: a...b) }

// MARK: - Entities
private final class Player {
    var x: CGFloat = 240, y: CGFloat = 0, vy: CGFloat = 0
    var onGround = true, inv = false
    var invT: CGFloat = 0, blinkT: CGFloat = 0, gas: CGFloat = 100
    var squashT: CGFloat = 0, blastFlash: CGFloat = 0, barrierT: CGFloat = 0
    var face: Int = 0, faceT: CGFloat = 0, mushT: CGFloat = 0, slipT: CGFloat = 0
    var shieldT: CGFloat = 0, x2T: CGFloat = 0, slowT: CGFloat = 0, freeFartT: CGFloat = 0
}
private final class Monkey {
    var x: CGFloat, y: CGFloat, bx: CGFloat, by: CGFloat
    var swingT: CGFloat, swayX: CGFloat, vx: CGFloat, retargetT: CGFloat
    var throwT: CGFloat, angryT: CGFloat = 0, stun: CGFloat = 0, wob: CGFloat = 0, gust: CGFloat = 0
    var kind = "reg", charge: CGFloat = 0
    init(x: CGFloat, y: CGFloat) {
        self.x = x; self.y = y; bx = x; by = y
        swingT = R(0, 6.28); swayX = R(7, 13)
        vx = (Bool.random() ? -1 : 1) * R(30, 68); retargetT = R(1.4, 3.4); throwT = R(0.7, 1.8)
    }
}
private final class Banana {
    var x: CGFloat, y: CGFloat, vx: CGFloat, vy: CGFloat, rot: CGFloat, rotV: CGFloat
    var friendly: Bool; var type: String; var small = false
    init(x: CGFloat, y: CGFloat, vx: CGFloat, vy: CGFloat, rotV: CGFloat, friendly: Bool, type: String) {
        self.x = x; self.y = y; self.vx = vx; self.vy = vy; rot = 0; self.rotV = rotV; self.friendly = friendly; self.type = type
    }
}
private final class Pop { var x, y, life, maxLife, rot: CGFloat; var text: String; var color: UIColor
    init(x: CGFloat, y: CGFloat, text: String, color: UIColor, rot: CGFloat) { self.x = x; self.y = y; life = 0.7; maxLife = 0.7; self.text = text; self.color = color; self.rot = rot } }
private final class Peel { var x, life: CGFloat; var kind: String; init(x: CGFloat, life: CGFloat, kind: String) { self.x = x; self.life = life; self.kind = kind } }
private final class PowerUp { var x, y, vy, life: CGFloat; var kind: String; var landed: Bool
    init(x: CGFloat, y: CGFloat, vy: CGFloat, kind: String) { self.x = x; self.y = y; self.vy = vy; life = 7; self.kind = kind; landed = false } }
private final class Boss {
    var x: CGFloat = 240, bx: CGFloat = 240, by: CGFloat = 98
    var hp: CGFloat = 100, maxHp: CGFloat = 100
    var atkT: CGFloat = 1.4, chargeT: CGFloat = 0, bobT: CGFloat = 0, swingT: CGFloat = 0, hitFlash: CGFloat = 0, vx: CGFloat = 46
    var phase = 1, lastPhase = 1
    var roarT: CGFloat = 1.4, weakT: CGFloat = 0, slamT: CGFloat = 0, slamHit: CGFloat = 0, deathT: CGFloat = 0, wob: CGFloat = 0, angryT: CGFloat = 0
    var minionsSpawned = false
    var tell = ""
}
private final class Particle {
    var x, y, vx, vy, life, maxLife, size: CGFloat; var kind: String
    init(x: CGFloat, y: CGFloat, vx: CGFloat, vy: CGFloat, life: CGFloat, size: CGFloat, kind: String) {
        self.x = x; self.y = y; self.vx = vx; self.vy = vy; self.life = life; maxLife = life; self.size = size; self.kind = kind
    }
}
private final class Cloud { var x, y, r, life, maxLife: CGFloat
    init(x: CGFloat, y: CGFloat, r: CGFloat, life: CGFloat) { self.x = x; self.y = y; self.r = r; self.life = life; maxLife = life } }
private final class Floater { var x, y, vy, life, maxLife, size: CGFloat; var text: String; var color: UIColor
    init(x: CGFloat, y: CGFloat, text: String, color: UIColor, size: CGFloat) {
        self.x = x; self.y = y; vy = -46; life = 1.1; maxLife = 1.1; self.text = text; self.color = color; self.size = size } }

// MARK: - Game view
final class GameView: UIView {

    // logical canvas
    private let LW: CGFloat = 480, LH: CGFloat = 760
    private var CTRL_TOP: CGFloat { LH - 120 }
    private var GROUND_Y: CGFloat { CTRL_TOP - 42 }
    private var PLAYER_GY: CGFloat { GROUND_Y - 26 }
    private let BRANCH_Y: CGFloat = 42
    private let GRAV: CGFloat = 1500, JUMP: CGFloat = -660, PSPEED: CGFloat = 305
    private let GAS_MAX: CGFloat = 100, BLAST_COST: CGFloat = 34, GAS_RECHARGE: CGFloat = 30
    private let DEFLECT_R: CGFloat = 96, BARRIER_T: CGFloat = 0.5
    private let PEEL_LIFE: CGFloat = 5, PEEL_R: CGFloat = 20, SLIP_T: CGFloat = 1.2
    private let PU_SHIELD: CGFloat = 6, PU_X2: CGFloat = 8, PU_SLOW: CGFloat = 4, PU_FREE: CGFloat = 4.5
    private let LIVES_MAX = 4
    private let cMask = hex("25d4e8"), cGold = hex("ffe234"), cPlug = hex("b06bff"), cBeano = hex("93e552"), cBean = hex("ffab2e"), cMega = hex("ff4db8")

    // Loud theme palette
    private let cBgBase = hex("2a1857"), cBgDot = hex("ff3d7f"), cGround = hex("17d1e8"), cGroundEdge = hex("0fb0c6")
    private let cOutline = hex("000000"), cMonkeyBody = hex("8a4bd6"), cMonkeyFace = hex("ffe022"), cEar = hex("7a3ec6")
    private let cPlayerBody = hex("17d1e8"), cPlayerSkin = hex("ffb0c7"), cBanana = hex("ffe234"), cBananaTip = hex("e0b800")
    private let cFart = hex("7CFF5A"), cAccent = hex("ffe022"), cText = hex("ffffff"), cPanel = hex("2a1857", 0.92), cBorder = hex("ff3d7f")
    private let cWood = hex("3a2557"), cLeaf = hex("17d1e8")

    // state
    private enum St { case start, play, leveldone, boss, win, over }
    private var st: St = .start
    private let LEVELS: [(secs: CGFloat, monkeys: Int)] = [(9,1),(10,1),(11,1),(12,2),(12,2),(13,2),(13,3),(14,3),(15,3),(16,4)]
    private var level = 1, levelT: CGFloat = 0
    private var boss: Boss?
    private var lives = 4
    private var score: CGFloat = 0
    private var best = UserDefaults.standard.integer(forKey: "fartback_best")
    private var combo = 0
    private var gameT: CGFloat = 0, tipT: CGFloat = 3.5
    private var shakeT: CGFloat = 0, shakeMag: CGFloat = 0
    private var hitstop: CGFloat = 0, flashT: CGFloat = 0, megaRingT: CGFloat = 0
    private var flashCol: UIColor = .white

    private let P = Player()
    private var monkeys: [Monkey] = []
    private var bananas: [Banana] = []
    private var particles: [Particle] = []
    private var clouds: [Cloud] = []
    private var floaters: [Floater] = []
    private var pops: [Pop] = []
    private var peels: [Peel] = []
    private var powerups: [PowerUp] = []

    // input
    private struct Btn { let id: String; let cx: CGFloat; let cy: CGFloat; let r: CGFloat; let glyph: String }
    private lazy var buttons: [Btn] = [
        Btn(id: "L", cx: 54, cy: LH - 60, r: 38, glyph: "\u{25C0}"),
        Btn(id: "R", cx: 140, cy: LH - 60, r: 38, glyph: "\u{25B6}"),
        Btn(id: "FART", cx: 302, cy: LH - 62, r: 47, glyph: "\u{1F4A8}"),
        Btn(id: "JUMP", cx: 424, cy: LH - 60, r: 38, glyph: "\u{2912}")
    ]
    private var touchBtn: [ObjectIdentifier: String] = [:]

    // display link + transform
    private var link: CADisplayLink?
    private var lastTs: CFTimeInterval = 0
    private var s: CGFloat = 1, tx: CGFloat = 0, ty: CGFloat = 0
    private var cg: CGContext!
    private let audio = FartAudio()

    override init(frame: CGRect) { super.init(frame: frame); backgroundColor = .black; isMultipleTouchEnabled = true; P.y = PLAYER_GY }
    required init?(coder: NSCoder) { fatalError() }

    func start() {
        stop()
        let l = CADisplayLink(target: self, selector: #selector(tick))
        l.add(to: .main, forMode: .common)
        link = l; lastTs = 0
        switch ProcessInfo.processInfo.environment["AUTOPLAY"] {  // dev: for automated screenshots
        case "1": startGame()
        case "boss": startGame(); startBoss(); boss?.hp = 62; boss?.chargeT = 0.4
        case "win": startGame(); winGame()
        default: break
        }
    }
    func stop() { link?.invalidate(); link = nil }

    @objc private func tick(_ dl: CADisplayLink) {
        if lastTs == 0 { lastTs = dl.timestamp; return }
        let dt = min(CGFloat(dl.timestamp - lastTs), 0.05)
        lastTs = dl.timestamp
        if hitstop > 0 { hitstop -= dt } else { update(dt) }
        setNeedsDisplay()
    }

    // MARK: - Flow
    private func resetForLevel(_ inv: CGFloat) {
        bananas.removeAll(); particles.removeAll(); clouds.removeAll(); floaters.removeAll()
        pops.removeAll(); peels.removeAll(); powerups.removeAll(); monkeys.removeAll()
        P.x = LW/2; P.y = PLAYER_GY; P.vy = 0; P.onGround = true; P.inv = true; P.invT = inv; P.blinkT = 0
        P.gas = GAS_MAX; P.squashT = 0; P.blastFlash = 0; P.barrierT = 0; P.face = 0; P.faceT = 0; P.mushT = 0
        P.slipT = 0; P.shieldT = 0; P.x2T = 0; P.slowT = 0; P.freeFartT = 0; megaRingT = 0
    }
    private func startGame() {
        st = .play; lives = LIVES_MAX; score = 0; combo = 0; gameT = 0; tipT = 3.5; hitstop = 0; flashT = 0
        level = 1; levelT = 0; boss = nil
        resetForLevel(1.2); setMonkeyCount(LEVELS[0].monkeys)
    }
    private func completeLevel() {
        if level >= 10 { startBoss() } else { st = .leveldone; levelT = 0; burstFx(P.x, P.y, 14); audio.tone(f0: 520, f1: 120, dur: 0.3, gain: 0.24) }
    }
    private func nextLevel() { level += 1; levelT = 0; resetForLevel(1.0); setMonkeyCount(LEVELS[level-1].monkeys); st = .play }
    private func startBoss() {
        st = .boss; levelT = 0; resetForLevel(1.6); boss = Boss()
        addPop(LW/2, 168, "KING KONG-A-TOOT!", hex("ff5a5a")); doFlash(hex("ff5a5a"), 0.4); addShake(14, 0.6)
        audio.fart(freq: 90, dur: 1.0, flutter: 6, cutoff: 700, gain: 0.5)
    }
    private func winGame() {
        st = .win; audio.tone(f0: 400, f1: 900, dur: 0.1, gain: 0.2)
        for _ in 0..<40 { particles.append(Particle(x: R(0, LW), y: R(-40, LH*0.4), vx: R(-30, 30), vy: R(60, 180), life: R(1.5, 3), size: R(6, 13), kind: "star")) }
        let fs = Int(score); if fs > best { best = fs; UserDefaults.standard.set(best, forKey: "fartback_best") }
    }
    private func setMonkeyCount(_ n: Int) {
        while monkeys.count < n {
            let m = Monkey(x: R(60, LW-60), y: R(94, 110)); m.kind = pickKind()
            m.throwT = m.kind == "boom" ? R(1.6, 2.6) : R(0.7, 1.8)
            monkeys.append(m)
        }
    }
    private func doJump() {
        guard st == .play || st == .boss, P.onGround, P.slipT <= 0 else { return }
        P.vy = JUMP; P.onGround = false
        audio.fart(freq: Double(R(200, 260)), dur: 0.15, flutter: 28, cutoff: 1700, gain: 0.28, square: true)
        for _ in 0..<7 { particles.append(puff(P.x + R(-8, 8), PLAYER_GY + 20, R(-40, 40), R(20, 90))) }
        clouds.append(Cloud(x: P.x, y: PLAYER_GY + 22, r: 12, life: 0.7))
    }
    private func doBlast() {
        guard st == .play || st == .boss, P.slipT <= 0 else { return }
        let free = P.freeFartT > 0
        if !free && P.gas < BLAST_COST { return }
        if !free { P.gas -= BLAST_COST }
        P.blastFlash = 0.22; P.face = 2; P.faceT = 0.4; P.barrierT = BARRIER_T; addShake(7, 0.18)
        audio.fart(freq: Double(R(70, 92)), dur: 0.42, flutter: 14, cutoff: 1200, gain: 0.5)
        clouds.append(Cloud(x: P.x, y: P.y + 22, r: 20, life: 0.9))
        for _ in 0..<14 { let a = R(2.3, 4.0); particles.append(puff(P.x, P.y + 18, cos(a)*R(60, 150), sin(a)*R(30, 120)+40)) }
        // shoot a banana up at nearest monkey
        let tg = nearestMonkey(P.x, P.y - 40)
        let tf: CGFloat = 0.6; var vx = R(-30, 30), vy: CGFloat = -720
        if let m = tg { vx = (m.bx - P.x)/tf; vy = (m.by - (P.y - 28) - 0.5*GRAV*tf*tf)/tf }
        bananas.append(Banana(x: P.x, y: P.y - 22, vx: vx, vy: vy, rotV: R(-16, 16), friendly: true, type: "shot"))
        // instant barrier
        var blocked = 0
        bananas = bananas.filter { b in
            if b.friendly { return true }
            let dx = b.x - P.x, dy = b.y - P.y
            if abs(dx) < 64 && dy > -74 && dy < 14 { burstFx(b.x, b.y, 5); blocked += 1; return false }
            return true
        }
        if blocked > 0 { addFloat(P.x, P.y - 56, "BLOCK!", cFart, 15); score += CGFloat(blocked) * 10; audio.tone(f0: 320, f1: 760, dur: 0.14, gain: 0.22) }
    }
    private func nearestMonkey(_ x: CGFloat, _ y: CGFloat) -> Monkey? {
        var best: Monkey? = nil; var bd: CGFloat = 1e9
        for m in monkeys where m.stun <= 0 { let d = (m.bx-x)*(m.bx-x)+(m.by-y)*(m.by-y); if d < bd { bd = d; best = m } }
        return best
    }
    private func throwBanana(_ fx: CGFloat, _ fy: CGFloat, _ tx: CGFloat, _ tf: CGFloat, _ count: Int, _ spread: CGFloat, _ type: String) {
        for _ in 0..<count {
            let rx = tx + (CGFloat.random(in: 0...1) - 0.5) * 150 * spread
            let vx = (rx - fx)/tf, vy = (PLAYER_GY - fy - 0.5*GRAV*tf*tf)/tf
            bananas.append(Banana(x: fx, y: fy, vx: vx, vy: vy, rotV: (CGFloat.random(in: 0...1)-0.5)*10, friendly: false, type: type))
        }
    }
    private func puff(_ x: CGFloat, _ y: CGFloat, _ vx: CGFloat, _ vy: CGFloat) -> Particle {
        Particle(x: x, y: y, vx: vx, vy: vy, life: R(0.4, 0.8), size: R(4, 9), kind: "puff")
    }
    private func burstFx(_ x: CGFloat, _ y: CGFloat, _ n: Int) {
        for _ in 0..<n { let a = R(0, 6.28), spd = R(90, 300)
            particles.append(Particle(x: x, y: y, vx: cos(a)*spd, vy: sin(a)*spd-90, life: R(0.6, 1.2), size: R(5, 11), kind: "star")) }
    }
    private func addFloat(_ x: CGFloat, _ y: CGFloat, _ t: String, _ c: UIColor, _ sz: CGFloat) { floaters.append(Floater(x: x, y: y, text: t, color: c, size: sz)) }
    private func addShake(_ m: CGFloat, _ d: CGFloat) { shakeMag = max(shakeMag, m); shakeT = max(shakeT, d) }
    private func addPop(_ x: CGFloat, _ y: CGFloat, _ t: String, _ c: UIColor) { pops.append(Pop(x: x, y: y, text: t, color: c, rot: R(-0.18, 0.18))) }
    private func doFlash(_ c: UIColor, _ amt: CGFloat) { flashT = max(flashT, amt); flashCol = c }
    private func pickKind() -> String {
        if level < 5 { return "reg" }
        let r = CGFloat.random(in: 0...1)
        if level >= 7 && r < 0.16 { return "boom" }
        return r < 0.70 ? "reg" : "gun"
    }
    private func groundSplat(_ b: Banana) {
        burstFx(b.x, GROUND_Y-2, 4)
        for _ in 0..<4 { particles.append(puff(b.x, GROUND_Y-2, R(-40, 40), R(-30, -5))) }
        if b.type != "black" && !b.small && peels.count < 7 && CGFloat.random(in: 0...1) < 0.5 {
            peels.append(Peel(x: max(24, min(LW-24, b.x)), life: PEEL_LIFE, kind: b.type))
        }
    }
    private func slip(_ p: Peel) {
        P.slipT = SLIP_T; P.onGround = true; P.vy = 0; combo = 0; p.life = 0
        audio.fart(freq: 270, dur: 0.5, flutter: 22, cutoff: 1300, gain: 0.35); addShake(8, 0.2)
        addFloat(P.x, P.y-40, "WHOOPS!", cAccent, 17)
        for _ in 0..<8 { particles.append(puff(P.x + R(-14, 14), PLAYER_GY+18, R(-80, 80), R(-20, 20))) }
    }
    private func spawnPU(_ x: CGFloat, _ y: CGFloat) {
        let r = CGFloat.random(in: 0...1)
        let kind = r < 0.22 ? "mask" : (r < 0.42 ? "gold" : (r < 0.57 ? "plug" : (r < 0.70 ? "beano" : (r < 0.90 ? "bean" : "mega"))))
        powerups.append(PowerUp(x: max(24, min(LW-24, x)), y: y, vy: R(10, 50), kind: kind))
    }
    private func collectPU(_ pu: PowerUp) {
        audio.tone(f0: 400, f1: 1100, dur: 0.16, gain: 0.24); addShake(5, 0.12); burstFx(P.x, P.y-16, 9)
        switch pu.kind {
        case "mask": P.shieldT = PU_SHIELD; addPop(P.x, P.y-52, "SHIELD!", cMask)
        case "gold": P.x2T = PU_X2; addPop(P.x, P.y-52, "SCORE x2!", cGold)
        case "plug": P.slowT = PU_SLOW; addPop(P.x, P.y-52, "SLO-MO!", cPlug)
        case "beano": clouds.removeAll(); peels.removeAll(); addPop(P.x, P.y-52, "FRESH AIR!", cBeano); doFlash(cFart, 0.2)
        case "bean": P.gas = GAS_MAX; P.freeFartT = PU_FREE; addPop(P.x, P.y-52, "RAPID FIRE!", cBean); doFlash(cBean, 0.2)
        default: megaFart()
        }
    }
    private func megaFart() {
        doFlash(cFart, 0.6); addShake(16, 0.5); hitstop = max(hitstop, 0.06); audio.fart(freq: 80, dur: 0.4, flutter: 12, cutoff: 900, gain: 0.5); megaRingT = 0.6
        addPop(P.x, P.y-52, "MEGA FART!!", cMega)
        bananas = bananas.filter { b in if !b.friendly { burstFx(b.x, b.y, 3); return false }; return true }
        for m in monkeys where m.stun <= 0 { m.stun = 3; m.wob = 0; m.angryT = 0; burstFx(m.bx, m.by, 8) }
        if let b = boss, b.hp > 0, b.deathT <= 0 { let d: CGFloat = 25; b.hp = max(0, b.hp - d); b.hitFlash = 0.3; addFloat(b.bx, b.by-30, "-\(Int(d))", cMega, 20); if b.hp <= 0 { killBoss() } }
        for _ in 0..<44 { let a = R(0, 6.28); particles.append(puff(P.x, P.y, cos(a)*R(120, 340), sin(a)*R(120, 340))) }
    }
    private func puColor(_ k: String) -> UIColor { k == "mask" ? cMask : (k == "gold" ? cGold : (k == "plug" ? cPlug : (k == "bean" ? cBean : (k == "mega" ? cMega : cBeano)))) }

    private func hitPlayer(_ bx: CGFloat, _ by: CGFloat, _ type: String) {
        if P.shieldT > 0 { burstFx(bx, by, 5); addPop(P.x, P.y-46, "SAFE!", cMask); addShake(3, 0.08); return }
        if type == "brown" { P.mushT = 1.2; combo = 0; P.face = 1; P.faceT = 1; P.inv = true; P.invT = 0.7; P.blinkT = 0
            burstFx(bx, by, 6); addShake(6, 0.18); doFlash(hex("b07a44"), 0.14); addFloat(P.x, P.y-44, "SPLAT!", hex("b07a44"), 18); return }
        lives -= 1; combo = 0; P.inv = true; P.invT = 1.8; P.blinkT = 0; P.face = 1; P.faceT = 1
        burstFx(bx, by, 10); addShake(type == "black" ? 14 : 12, 0.3); doFlash(hex("ff5a5a"), 0.32); hitstop = max(hitstop, 0.08)
        audio.fart(freq: 270, dur: 0.5, flutter: 22, cutoff: 1300, gain: 0.4)
        addPop(P.x, P.y-46, type == "black" ? "BLECH!" : "OUCH!", hex("ff5a5a"))
        if lives <= 0 { gameOver() }
    }
    private func gameOver() {
        st = .over; burstFx(P.x, P.y, 16); addShake(14, 0.4)
        audio.fart(freq: 150, dur: 0.7, flutter: 10, cutoff: 900, gain: 0.5)
        let fs = Int(score); if fs > best { best = fs; UserDefaults.standard.set(best, forKey: "fartback_best") }
    }
    private func killBoss() {
        guard let b = boss, b.deathT <= 0 else { return }
        b.deathT = 1.3; b.weakT = 0; b.chargeT = 0; b.slamT = 0
        bananas = bananas.filter { $0.friendly }; addShake(16, 0.6); doFlash(.white, 0.4); audio.tone(f0: 520, f1: 120, dur: 0.3, gain: 0.24)
    }
    private func spawnMinions(_ n: Int) {
        for i in 0..<n {
            let side: CGFloat = i % 2 == 0 ? 1 : -1
            let m = Monkey(x: LW/2 + side*R(120, 180), y: R(96, 116)); m.kind = "gun"; m.vx = side*R(40, 80); m.throwT = R(0.7, 1.4)
            monkeys.append(m)
        }
        addPop(LW/2, 150, "MINIONS!", cAccent); doFlash(cFart, 0.2)
    }
    private func bossReleaseCharge(_ b: Boss) {
        b.atkT = 1.4; audio.fart(freq: 80, dur: 0.4, flutter: 13, cutoff: 900, gain: 0.5); addShake(7, 0.2)
        if b.tell == "fan" { for i in 0..<7 { let tx = 60 + CGFloat(i)*(LW-120)/6; throwBanana(b.bx, b.by+46, tx, 0.62, 1, 0.04, "black") } }
        else if b.tell == "rain" { for i in 0..<6 { let x = 45 + CGFloat(i)*(LW-90)/5; bananas.append(Banana(x: x, y: -20, vx: R(-8, 8), vy: R(130, 180), rotV: R(-8, 8), friendly: false, type: CGFloat.random(in: 0...1) < 0.4 ? "black" : "yellow")) } }
        else { throwBanana(b.bx, b.by+46, P.x, 0.6, 5, 0.78, "black") }
        for _ in 0..<12 { let a = R(1.2, 3.2); particles.append(puff(b.bx + R(-10, 10), b.by+48, cos(a)*R(50, 130), sin(a)*R(50, 130)+30)) }
        b.tell = ""
    }
    private func bossSlam(_ b: Boss) {
        b.atkT = 1.6; b.slamHit = 0.28; addShake(18, 0.5); doFlash(.white, 0.24); hitstop = max(hitstop, 0.06); audio.fart(freq: 80, dur: 0.5, flutter: 10, cutoff: 800, gain: 0.5)
        throwBanana(b.bx, b.by+50, P.x, 0.5, 4, 0.72, "black")
        for _ in 0..<22 { particles.append(puff(b.bx + R(-50, 50), b.by+54, R(-180, 180), R(-40, 70))) }
    }
    private func updateBoss(_ b: Boss, _ dt: CGFloat) {
        b.bobT += dt; b.swingT += dt*1.5; if b.hitFlash > 0 { b.hitFlash -= dt }; if b.slamHit > 0 { b.slamHit -= dt }
        if b.deathT > 0 { b.deathT -= dt; b.by += dt*70; b.wob += dt*14; if b.deathT <= 0 { winGame() }; return }
        if b.roarT > 0 { b.roarT -= dt; return }
        let np = b.hp > 66 ? 1 : (b.hp > 33 ? 2 : 3)
        if np > b.lastPhase { b.lastPhase = np; b.weakT = 2.6; b.wob = 0; b.chargeT = 0; b.slamT = 0; addPop(b.bx, b.by-26, "DIZZY!", cAccent); doFlash(cFart, 0.3); addShake(8, 0.3); audio.tone(f0: 520, f1: 120, dur: 0.3, gain: 0.24) }
        b.phase = np
        if b.weakT > 0 { b.weakT -= dt; b.wob += dt*16; if b.weakT <= 0 && b.phase == 3 && !b.minionsSpawned { b.minionsSpawned = true; spawnMinions(2) }; return }
        b.x += b.vx*dt; if b.x < 80 { b.x = 80; b.vx = abs(b.vx) } else if b.x > LW-80 { b.x = LW-80; b.vx = -abs(b.vx) }
        b.bx = b.x + sin(b.swingT)*8; b.by = 98 + (1 - cos(b.swingT))*4
        if b.angryT > 0 { b.angryT -= dt }
        if b.slamT > 0 { b.slamT -= dt; if b.slamT <= 0 { bossSlam(b) }; return }
        if b.chargeT > 0 { b.chargeT -= dt; if b.chargeT <= 0 { bossReleaseCharge(b) }; return }
        b.atkT -= dt; if b.atkT > 0 { return }
        if b.phase == 1 { b.atkT = R(1.0, 1.4); b.angryT = 0.35; throwBanana(b.bx, b.by+46, P.x, 0.68, 1, 0.08, "yellow"); audio.fart(freq: 130, dur: 0.2, flutter: 20, cutoff: 1000, gain: 0.3) }
        else if b.phase == 2 {
            let r = CGFloat.random(in: 0...1)
            if r < 0.4 { b.chargeT = 0.75; b.atkT = 2.0; b.tell = "fan" }
            else if r < 0.6 { b.slamT = 0.75; b.atkT = 2.2 }
            else { b.atkT = R(0.9, 1.3); throwBanana(b.bx, b.by+46, P.x, 0.6, 2, 0.5, CGFloat.random(in: 0...1) < 0.4 ? "black" : "yellow"); audio.fart(freq: 130, dur: 0.2, flutter: 20, cutoff: 1000, gain: 0.3) }
        } else {
            let r = CGFloat.random(in: 0...1)
            if r < 0.42 { b.chargeT = 0.6; b.atkT = 1.7; b.tell = "rain" }
            else if r < 0.62 { b.slamT = 0.65; b.atkT = 1.8 }
            else { b.atkT = R(0.55, 0.85); throwBanana(b.bx, b.by+46, P.x, 0.52, 3, 0.6, CGFloat.random(in: 0...1) < 0.5 ? "black" : "yellow"); audio.fart(freq: 130, dur: 0.2, flutter: 20, cutoff: 1000, gain: 0.3) }
        }
    }
    private func bossHit(_ bx: CGFloat, _ by: CGFloat) {
        guard let b = boss, b.hp > 0, b.roarT <= 0, b.deathT <= 0 else { return }
        let weak = b.weakT > 0; let dmg: CGFloat = weak ? 16 : 8
        b.hp = max(0, b.hp - dmg); b.hitFlash = 0.24; combo += 1
        let pts = (weak ? 300 : 150) * combo * (P.x2T > 0 ? 2 : 1); score += CGFloat(pts)
        addFloat(bx, by-20, "+\(pts)", weak ? cFart : cAccent, weak ? 22 : 18); burstFx(bx, by, weak ? 16 : 10)
        addPop(bx, by-6, weak ? "WEAK POINT!" : (combo >= 4 ? "CRUNCH!" : "BONK!"), weak ? cFart : cAccent)
        doFlash(cFart, weak ? 0.35 : 0.2); hitstop = max(hitstop, weak ? 0.08 : 0.05); addShake(weak ? 11 : 7, 0.18)
        audio.tone(f0: 520, f1: 120, dur: 0.3, gain: 0.24)
        if b.hp <= 0 { killBoss() }
    }

    // MARK: - Update
    private func update(_ dt: CGFloat) {
        particles = particles.filter { p in p.x += p.vx*dt; p.y += p.vy*dt; p.vy += (p.kind == "star" ? 520 : 40)*dt; p.life -= dt; return p.life > 0 }
        clouds = clouds.filter { c in c.r += dt*26; c.life -= dt; c.x += sin(c.life*6)*8*dt; return c.life > 0 }
        floaters = floaters.filter { f in f.y += f.vy*dt; f.vy += 60*dt; f.life -= dt; return f.life > 0 }
        pops = pops.filter { p in p.life -= dt; p.y -= 12*dt; return p.life > 0 }
        if flashT > 0 { flashT -= dt*2.6 }
        if shakeT > 0 { shakeT -= dt }; if megaRingT > 0 { megaRingT -= dt }
        if st == .win && CGFloat.random(in: 0...1) < 0.5 { particles.append(Particle(x: R(0, LW), y: -20, vx: R(-30, 30), vy: R(80, 160), life: R(2, 3.4), size: R(6, 13), kind: "star")) }
        guard st == .play || st == .boss else { return }
        gameT += dt; if tipT > 0 { tipT -= dt }; score += dt*8*(P.x2T > 0 ? 2 : 1)
        if st == .play { levelT += dt; let cfg = LEVELS[level-1]; if monkeys.count < cfg.monkeys { setMonkeyCount(cfg.monkeys) }; if levelT >= cfg.secs { completeLevel(); return } }

        // player
        if P.slipT <= 0 {
            if leftHeld() { P.x -= PSPEED*(P.mushT > 0 ? 0.45 : 1)*dt }
            if rightHeld() { P.x += PSPEED*(P.mushT > 0 ? 0.45 : 1)*dt }
        }
        P.x = max(24, min(LW-24, P.x))
        if !P.onGround { P.vy += GRAV*dt; P.y += P.vy*dt
            if P.y >= PLAYER_GY { P.y = PLAYER_GY; P.vy = 0; P.onGround = true; P.squashT = 0.18
                for _ in 0..<5 { particles.append(puff(P.x + R(-10, 10), PLAYER_GY+20, R(-60, 60), R(-10, 30))) } } }
        if P.squashT > 0 { P.squashT -= dt }
        if P.inv { P.invT -= dt; P.blinkT += dt; if P.invT <= 0 { P.inv = false } }
        if P.faceT > 0 { P.faceT -= dt; if P.faceT <= 0 { P.face = 0 } }
        if P.blastFlash > 0 { P.blastFlash -= dt }; if P.barrierT > 0 { P.barrierT -= dt }; if P.mushT > 0 { P.mushT -= dt }
        if P.slipT > 0 { P.slipT -= dt }; if P.shieldT > 0 { P.shieldT -= dt }; if P.x2T > 0 { P.x2T -= dt }; if P.slowT > 0 { P.slowT -= dt }; if P.freeFartT > 0 { P.freeFartT -= dt }
        P.gas = min(GAS_MAX, P.gas + GAS_RECHARGE*dt)

        // monkeys
        for m in monkeys {
            m.swingT += dt*2.6; if m.gust > 0 { m.gust -= dt }
            if m.stun > 0 { m.stun -= dt; m.wob += dt*20; m.bx = m.x + sin(m.wob)*4; m.by = m.y + 6; continue }
            m.retargetT -= dt; if m.retargetT <= 0 { m.retargetT = R(1.6, 3.6); m.vx = (Bool.random() ? -1 : 1) * R(30, 72) }
            m.x += m.vx*dt; if m.x < 52 { m.x = 52; m.vx = abs(m.vx) } else if m.x > LW-52 { m.x = LW-52; m.vx = -abs(m.vx) }
            m.bx = m.x + sin(m.swingT)*m.swayX; m.by = m.y + (1 - cos(m.swingT))*3
            if m.angryT > 0 { m.angryT -= dt }
            m.throwT -= dt
            // difficulty driven by LEVEL (not cumulative time) + crowd-compensated per-monkey rate
            let L = CGFloat(level), nMon = CGFloat(max(1, monkeys.count)), crowd = 1 + 0.36*(nMon-1)
            let flight = max(0.62, 1.05 - (L-1)*0.035), spread = min(0.42, 0.05 + (L-1)*0.038), baseIv = (2.9 - (L-1)*0.13)*crowd
            if m.charge > 0 {
                m.charge -= dt; m.gust = max(m.gust, 0.32)
                if m.charge <= 0 {
                    throwBanana(m.bx, m.by+26, P.x, flight+0.05, 3, 0.55, "black"); m.gust = 0.55
                    audio.fart(freq: Double(R(70, 92)), dur: 0.4, flutter: 13, cutoff: 900, gain: 0.46)
                    for _ in 0..<12 { let a = R(1.3, 3.1); particles.append(puff(m.bx + R(-8, 8), m.by+28, cos(a)*R(40, 110), sin(a)*R(40, 110)+30)) }
                }
            } else if m.throwT <= 0 {
                if m.kind == "gun" {
                    m.throwT = baseIv * R(0.72, 1.0); m.angryT = 0.22; m.gust = 0.28
                    for _ in 0..<2 {
                        let tf: CGFloat = max(0.5, flight*0.72), fx = m.bx + R(-4, 4), fy = m.by+22, rx = P.x + R(-30, 30)
                        let b = Banana(x: fx, y: fy, vx: (rx-fx)/tf, vy: (PLAYER_GY-fy-0.5*GRAV*tf*tf)/tf, rotV: R(-14, 14), friendly: false, type: "yellow")
                        b.small = true; bananas.append(b)
                    }
                    audio.fart(freq: Double(R(115, 155)), dur: 0.16, flutter: 24, cutoff: 1400, gain: 0.26)
                } else if m.kind == "boom" {
                    m.throwT = baseIv * R(1.5, 2.1); m.charge = 0.9; m.angryT = 0.9
                } else {
                    m.throwT = baseIv * R(0.8, 1.25); m.angryT = 0.4; m.gust = 0.4
                    let count = level >= 7 ? 2 : 1
                    let roll = CGFloat.random(in: 0...1); let bt = roll < 0.22 ? "black" : (roll < 0.46 ? "brown" : "yellow")
                    throwBanana(m.bx, m.by+24, P.x, flight, count, spread, bt)
                    audio.fart(freq: Double(R(115, 155)), dur: 0.2, flutter: 20, cutoff: 1000, gain: 0.3)
                    if bt == "black" { for _ in 0..<8 { let a = R(1.5, 3.0); particles.append(puff(m.bx + R(-6, 6), m.by+26, cos(a)*R(30, 90), sin(a)*R(30, 90)+30)) } }
                }
            }
        }
        // separation
        for i in 0..<monkeys.count { for j in (i+1)..<monkeys.count {
            let a = monkeys[i], b = monkeys[j]; if a.stun > 0 || b.stun > 0 { continue }
            let d = b.x - a.x; let dir: CGFloat = d == 0 ? (i % 2 == 1 ? 1 : -1) : (d < 0 ? -1 : 1)
            if abs(d) < 48 { a.x -= dir*1.6; b.x += dir*1.6; a.vx = -dir*abs(a.vx); b.vx = dir*abs(b.vx) }
        } }
        for m in monkeys { m.x = max(52, min(LW-52, m.x)) }
        if st == .boss, let b = boss { updateBoss(b, dt) }

        // bananas
        let wdt = dt * (P.slowT > 0 ? 0.45 : 1)
        bananas = bananas.filter { b in
            b.vy += GRAV*wdt; b.x += b.vx*wdt; b.y += b.vy*wdt; b.rot += b.rotV*wdt
            if b.type == "black" && !b.friendly && CGFloat.random(in: 0...1) < 0.35 { particles.append(puff(b.x, b.y, R(-20, 20), R(-10, 20))) }
            if b.x < -60 || b.x > LW+60 || b.y > LH+80 { return false }
            if b.friendly {
                if b.y < -60 { return false }
                if st == .boss, let bs = boss { let bdx = b.x - bs.bx, bdy = b.y - bs.by; if bdx*bdx + bdy*bdy < 46*46 { bossHit(b.x, b.y); return false } }
                for m in monkeys where m.stun <= 0 {
                    let dx = b.x - m.bx, dy = b.y - m.by
                    if dx*dx + dy*dy < 30*30 {
                        m.stun = 3; m.wob = 0; m.angryT = 0; combo += 1
                        let pts = 100 * combo * (P.x2T > 0 ? 2 : 1); score += CGFloat(pts)
                        addFloat(m.bx, m.by-38, "+\(pts)" + (combo > 1 ? "  x\(combo)" : ""), cAccent, combo > 2 ? 22 : 17)
                        burstFx(m.bx, m.by, 12); addShake(combo >= 3 ? 9 : 6, 0.16)
                        addPop(m.bx, m.by-8, combo >= 6 ? "MEGA!" : (combo >= 3 ? "BONK!" : "POW!"), cAccent)
                        doFlash(cFart, combo >= 3 ? 0.3 : 0.15); hitstop = max(hitstop, 0.05)
                        audio.tone(f0: 520, f1: 120, dur: 0.3, gain: 0.24)
                        if CGFloat.random(in: 0...1) < 0.32 { spawnPU(m.bx, m.by) }
                        return false
                    }
                }
                return true
            }
            if P.barrierT > 0 { let dx = b.x - P.x, dy = b.y - P.y; if abs(dx) < 64 && dy > -74 && dy < 14 { burstFx(b.x, b.y, 4); score += 8; return false } }
            if b.vy > 0 && b.y >= GROUND_Y-6 { groundSplat(b); return false }
            if !P.inv && P.slipT <= 0 { let dx = abs(b.x - P.x), dy = abs(b.y - P.y); if dx < 22 && dy < 26 { hitPlayer(b.x, b.y, b.type); return false } }
            return true
        }
        // peels, slip, power-ups
        peels = peels.filter { p in p.life -= dt; return p.life > 0 }
        if P.onGround && P.slipT <= 0 && !P.inv { for p in peels where abs(p.x - P.x) < PEEL_R { slip(p); break } }
        powerups = powerups.filter { pu in
            if !pu.landed { pu.vy += GRAV*0.5*dt; pu.y += pu.vy*dt; if pu.y >= GROUND_Y-12 { pu.y = GROUND_Y-12; pu.landed = true; pu.vy = 0 } }
            pu.life -= dt
            if abs(pu.x - P.x) < 26 && abs(pu.y - P.y) < 32 { collectPU(pu); return false }
            return pu.life > 0
        }
    }

    private func leftHeld() -> Bool { touchBtn.values.contains("L") }
    private func rightHeld() -> Bool { touchBtn.values.contains("R") }

    // MARK: - Touch
    private func toLogical(_ p: CGPoint) -> CGPoint { CGPoint(x: (p.x - tx)/s, y: (p.y - ty)/s) }
    private func btnAt(_ x: CGFloat, _ y: CGFloat) -> String? {
        for b in buttons { let dx = x - b.cx, dy = y - b.cy; if dx*dx + dy*dy <= (b.r+8)*(b.r+8) { return b.id } }
        return nil
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let p = toLogical(t.location(in: self))
            if st == .leveldone { nextLevel(); return }
            if st != .play && st != .boss { startGame(); return }
            if let id = btnAt(p.x, p.y) {
                touchBtn[ObjectIdentifier(t)] = id
                if id == "JUMP" { doJump() } else if id == "FART" { doBlast() }
            }
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let key = ObjectIdentifier(t); guard let cur = touchBtn[key], cur == "L" || cur == "R" else { continue }
            let p = toLogical(t.location(in: self)); if let id = btnAt(p.x, p.y), id == "L" || id == "R" { touchBtn[key] = id }
        }
    }
    private func endTouch(_ touches: Set<UITouch>) { for t in touches { touchBtn[ObjectIdentifier(t)] = nil } }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { endTouch(touches) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { endTouch(touches) }

    // MARK: - Draw helpers
    private func fillEllipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ c: UIColor, outline: Bool = true) {
        cg.setFillColor(c.cgColor)
        cg.fillEllipse(in: CGRect(x: cx-rx, y: cy-ry, width: rx*2, height: ry*2))
        if outline { cg.setStrokeColor(cOutline.cgColor); cg.setLineWidth(5); cg.strokeEllipse(in: CGRect(x: cx-rx, y: cy-ry, width: rx*2, height: ry*2)) }
    }
    private func fillCircle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ c: UIColor) {
        cg.setFillColor(c.cgColor); cg.fillEllipse(in: CGRect(x: cx-r, y: cy-r, width: r*2, height: r*2))
    }
    private func roundRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat, _ c: UIColor, fill: Bool = true, stroke: UIColor? = nil, lw: CGFloat = 2) {
        let p = UIBezierPath(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: r)
        if fill { c.setFill(); p.fill() }
        if let sc = stroke { sc.setStroke(); p.lineWidth = lw; p.stroke() }
    }
    private func text(_ s: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, _ color: UIColor, align: NSTextAlignment = .center, weight: UIFont.Weight = .heavy) {
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        let para = NSMutableParagraphStyle(); para.alignment = align
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: para]
        let str = NSAttributedString(string: s, attributes: attrs)
        let h = str.size().height, boxW: CGFloat = 3000
        let ox = align == .center ? x - boxW/2 : (align == .right ? x - boxW : x)
        str.draw(in: CGRect(x: ox, y: y - h/2, width: boxW, height: h*1.3))
    }

    // MARK: - Draw
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        cg = ctx
        // edge-to-edge: fill the whole view so there are no black letterbox bars
        cBgBase.setFill(); ctx.fill(bounds)
        s = min(bounds.width/LW, bounds.height/LH)
        tx = (bounds.width - LW*s)/2; ty = (bounds.height - LH*s)/2
        // extend the control-bar dark strip to the bottom edge
        UIColor(white: 0, alpha: 0.32).setFill()
        ctx.fill(CGRect(x: 0, y: ty + CTRL_TOP*s, width: bounds.width, height: bounds.height - (ty + CTRL_TOP*s)))
        ctx.saveGState()
        ctx.translateBy(x: tx, y: ty); ctx.scaleBy(x: s, y: s)

        if st == .start { drawStart(); ctx.restoreGState(); return }
        if st == .over { drawOver(); ctx.restoreGState(); return }
        if st == .win { drawWin(); ctx.restoreGState(); return }

        ctx.saveGState()
        if shakeT > 0 { ctx.translateBy(x: R(-1, 1)*shakeMag*shakeT, y: R(-1, 1)*shakeMag*shakeT) }
        drawBg()
        for c in clouds { drawCloud(c) }
        for m in monkeys { drawMonkey(m) }
        if st == .boss, let b = boss { drawBoss(b) }
        for pe in peels { drawPeel(pe) }
        for pu in powerups { drawPowerup(pu) }
        for b in bananas { drawBanana(b) }
        drawPlayer()
        for p in particles { drawParticle(p) }
        for f in floaters { drawFloater(f) }
        drawPops()
        ctx.restoreGState()

        if P.slowT > 0 { cg.setAlpha(0.1); cPlug.setFill(); cg.fill(CGRect(x: 0, y: 0, width: LW, height: CTRL_TOP)); cg.setAlpha(1) }
        drawHUD(); drawEffectPips(); drawControls()
        if st == .leveldone { drawLevelDone() }
        if flashT > 0 { cg.setAlpha(min(0.28, flashT)); flashCol.setFill(); cg.fill(CGRect(x: 0, y: 0, width: LW, height: LH)); cg.setAlpha(1) }
        ctx.restoreGState()
    }

    private func drawBg() {
        cBgBase.setFill(); cg.fill(CGRect(x: 0, y: 0, width: LW, height: GROUND_Y))
        cg.setFillColor(cBgDot.cgColor)
        var y: CGFloat = 8
        while y < GROUND_Y { var x: CGFloat = 8; while x < LW { cg.fillEllipse(in: CGRect(x: x-1.6, y: y-1.6, width: 3.2, height: 3.2)); x += 16 }; y += 16 }
        // ground
        cGround.setFill(); cg.fill(CGRect(x: 0, y: GROUND_Y, width: LW, height: CTRL_TOP - GROUND_Y))
        cGroundEdge.setFill(); cg.fill(CGRect(x: 0, y: GROUND_Y, width: LW, height: 6))
        drawBranch()
    }
    private func drawBranch() {
        cg.setFillColor(cLeaf.cgColor)
        for lx in [CGFloat(28), 108, LW-32, LW-112] { for k in 0..<3 {
            cg.saveGState(); cg.translateBy(x: lx + CGFloat(k)*11 - 10, y: BRANCH_Y - 13 - CGFloat(k % 2)*5)
            cg.scaleBy(x: 11, y: 7); cg.fillEllipse(in: CGRect(x: -1, y: -1, width: 2, height: 2)); cg.restoreGState() } }
        roundRect(-12, BRANCH_Y-8, LW+24, 15, 7, cWood, stroke: cOutline, lw: 3)
        cg.setStrokeColor(UIColor(white: 0, alpha: 0.2).cgColor); cg.setLineWidth(2); cg.setLineCap(.round)
        var x: CGFloat = 18; while x < LW { cg.move(to: CGPoint(x: x, y: BRANCH_Y-4)); cg.addLine(to: CGPoint(x: x+15, y: BRANCH_Y+3)); cg.strokePath(); x += 44 }
    }
    private func bananaPath() -> CGMutablePath {
        let p = CGMutablePath(); p.move(to: CGPoint(x: 0, y: 0))
        p.addCurve(to: CGPoint(x: 21, y: 17), control1: CGPoint(x: 10, y: -2), control2: CGPoint(x: 20, y: 5))
        p.addCurve(to: CGPoint(x: 3, y: 35), control1: CGPoint(x: 22, y: 29), control2: CGPoint(x: 14, y: 36))
        p.addCurve(to: CGPoint(x: 11, y: 12), control1: CGPoint(x: 13, y: 29), control2: CGPoint(x: 15, y: 20))
        p.addCurve(to: CGPoint(x: 0, y: 0), control1: CGPoint(x: 8, y: 6), control2: CGPoint(x: 4, y: 2))
        p.closeSubpath(); return p
    }
    private func drawBanana(_ b: Banana) {
        cg.saveGState(); cg.translateBy(x: b.x, y: b.y); cg.rotate(by: b.rot); if b.small { cg.scaleBy(x: 0.66, y: 0.66) }; cg.translateBy(x: -10, y: -17)
        var fill = cBanana, tip = cBananaTip
        if b.type == "brown" { fill = hex("9a6a34"); tip = hex("6a4520") } else if b.type == "black" { fill = hex("2c2824"); tip = hex("141210") }
        if b.friendly || b.type == "black" { cg.setShadow(offset: .zero, blur: b.friendly ? 16 : 11, color: cFart.cgColor) }
        cg.addPath(bananaPath()); cg.setFillColor(fill.cgColor); cg.fillPath()
        cg.setShadow(offset: .zero, blur: 0, color: nil)
        cg.addPath(bananaPath()); cg.setStrokeColor(cOutline.cgColor); cg.setLineWidth(3.5); cg.setLineJoin(.round); cg.strokePath()
        cg.setFillColor(tip.cgColor); cg.fillEllipse(in: CGRect(x: 0, y: -1, width: 6, height: 4))
        cg.restoreGState()
    }
    private func drawEyes(_ lx: CGFloat, _ ly: CGFloat, _ rx: CGFloat, _ ry: CGFloat, dead: Bool) {
        if dead {
            cg.setStrokeColor(UIColor(white: 0.13, alpha: 1).cgColor); cg.setLineWidth(2.5); cg.setLineCap(.round)
            for (x, y) in [(lx, ly), (rx, ry)] {
                cg.move(to: CGPoint(x: x-3, y: y-3)); cg.addLine(to: CGPoint(x: x+3, y: y+3))
                cg.move(to: CGPoint(x: x+3, y: y-3)); cg.addLine(to: CGPoint(x: x-3, y: y+3)); cg.strokePath()
            }
            return
        }
        for (x, y) in [(lx, ly), (rx, ry)] { fillCircle(x, y, 3.6, .black) }
    }
    private func drawMonkey(_ m: Monkey) {
        let x = m.bx, y = m.by, sc: CGFloat = m.kind == "boom" ? 1.26 : (m.kind == "gun" ? 0.82 : 1)
        cg.setStrokeColor(cMonkeyBody.cgColor); cg.setLineWidth(8*sc); cg.setLineCap(.round)
        cg.move(to: CGPoint(x: m.x, y: BRANCH_Y+2)); cg.addLine(to: CGPoint(x: x-4*sc, y: y-15*sc)); cg.strokePath()
        fillCircle(m.x, BRANCH_Y+1, 5, cMonkeyBody)
        cg.saveGState(); cg.translateBy(x: x, y: y)
        cg.rotate(by: sin(m.swingT)*0.10 + (m.stun > 0 ? sin(m.wob)*0.2 : 0)); cg.scaleBy(x: sc, y: sc)
        cg.setStrokeColor(cEar.cgColor); cg.setLineWidth(6); cg.setLineCap(.round)
        cg.move(to: CGPoint(x: 15, y: 7)); cg.addQuadCurve(to: CGPoint(x: 29, y: -11), control: CGPoint(x: 33, y: 11)); cg.strokePath()
        cg.setStrokeColor(cMonkeyBody.cgColor); cg.setLineWidth(7)
        cg.move(to: CGPoint(x: 13, y: -6)); cg.addQuadCurve(to: CGPoint(x: 21, y: 17), control: CGPoint(x: 25, y: 4)); cg.strokePath()
        fillEllipse(-17, -18, 7, 7, cEar); fillEllipse(17, -18, 7, 7, cEar)
        fillEllipse(0, -16, 18, 15, cMonkeyBody)
        fillEllipse(0, -13, 11, 10, cMonkeyFace)
        drawEyes(-6, -14, 6, -14, dead: m.stun > 0)
        fillEllipse(-11, 14, 14, 13, cMonkeyBody); fillEllipse(11, 14, 14, 13, cMonkeyBody)
        cg.setStrokeColor(cOutline.cgColor); cg.setLineWidth(5); cg.setLineCap(.round)
        cg.move(to: CGPoint(x: 0, y: 3)); cg.addLine(to: CGPoint(x: 0, y: 25)); cg.strokePath()
        fillEllipse(-8, 27, 5, 4, cMonkeyBody); fillEllipse(8, 27, 5, 4, cMonkeyBody)
        cg.restoreGState()
        if m.gust > 0 {
            let a = max(0, m.gust/0.4); cg.setAlpha(a*0.75); cg.setFillColor(cFart.cgColor)
            for k in 0..<5 { fillCircle(x + sin(CGFloat(k)*1.6 + m.swingT)*11, y + 30 + CGFloat(k)*4, 10 - CGFloat(k)*1.2, cFart) }
            cg.setAlpha(a); text("PBBT!", x + 24, y + 30, 12, cAccent); cg.setAlpha(1)
        }
        if m.charge > 0 { text("!!", x, y - 34*sc, 16, hex("ff5a5a")) }
    }
    private func drawPlayer() {
        if P.inv && Int(P.blinkT*8) % 2 == 0 { return }
        let slipping = P.slipT > 0
        var sx: CGFloat = 1, sy: CGFloat = 1
        if P.squashT > 0 { let k = P.squashT/0.18; sx = 1 + 0.32*k; sy = 1 - 0.32*k } else if !P.onGround { sy = 1.1; sx = 0.92 }
        cg.saveGState(); cg.translateBy(x: P.x, y: P.y)
        if slipping { cg.rotate(by: 1.35) } else { cg.scaleBy(x: sx, y: sy) }
        if P.blastFlash > 0 { cg.setAlpha(0.7); for k in 0..<4 { fillCircle(-3 + CGFloat(k)*2, 26 + CGFloat(k)*4, 10 - CGFloat(k)*1.5, cFart) }; cg.setAlpha(1) }
        roundRect(-15, 4, 30, 26, 9, cPlayerBody, stroke: cOutline, lw: 5)
        fillEllipse(0, -8, 14, 14, cPlayerSkin)
        drawEyes(-5, -8, 5, -8, dead: slipping)
        cg.restoreGState()
        if P.shieldT > 0 && !(P.shieldT < 1.2 && Int(P.shieldT*8) % 2 == 0) {
            cg.setAlpha(0.14); cMask.setFill(); cg.fillEllipse(in: CGRect(x: P.x-27, y: P.y-27, width: 54, height: 54))
            cg.setAlpha(0.5); cg.setStrokeColor(cMask.cgColor); cg.setLineWidth(2.5); cg.strokeEllipse(in: CGRect(x: P.x-27, y: P.y-27, width: 54, height: 54)); cg.setAlpha(1)
        }
        if P.x2T > 0 { text("x2", P.x+22, P.y-22, 13, cGold) }
        if P.freeFartT > 0 {
            cg.setAlpha(0.5 + 0.3*sin(P.freeFartT*22)); cg.setStrokeColor(cBean.cgColor); cg.setLineWidth(3); cg.strokeEllipse(in: CGRect(x: P.x-28, y: P.y-22, width: 56, height: 56))
            cg.setAlpha(0.5); for k in 0..<3 { let a = P.freeFartT*10 + CGFloat(k)*2.1; fillCircle(P.x + cos(a)*26, P.y+6 + sin(a)*26, 4, cBean) }; cg.setAlpha(1)
        }
        if megaRingT > 0 {
            let a = megaRingT/0.6; let rr = (1-a)*300 + 20
            cg.setAlpha(a*0.7); cg.setStrokeColor(cFart.cgColor); cg.setLineWidth(10*a + 2); cg.strokeEllipse(in: CGRect(x: P.x-rr, y: P.y-rr, width: rr*2, height: rr*2)); cg.setAlpha(1)
        }
        if P.barrierT > 0 {
            let a = P.barrierT/BARRIER_T; cg.setAlpha(a*0.6); cg.setStrokeColor(cFart.cgColor); cg.setLineWidth(6); cg.setLineCap(.round)
            cg.addArc(center: CGPoint(x: P.x, y: P.y-6), radius: 58, startAngle: .pi*1.12, endAngle: .pi*1.88, clockwise: false); cg.strokePath()
            cg.setAlpha(1)
        }
    }
    private func drawCloud(_ c: Cloud) {
        let a = max(0, c.life/c.maxLife); cg.setAlpha(a*0.6)
        for k in 0..<4 { fillCircle(c.x + sin(CGFloat(k)*1.7)*c.r*0.5, c.y + cos(CGFloat(k)*1.3)*c.r*0.4, max(1, c.r*0.7 - CGFloat(k)*4), cFart) }
        cg.setAlpha(1)
    }
    private func drawParticle(_ p: Particle) {
        let a = max(0, p.life/p.maxLife); cg.setAlpha(a * (p.kind == "puff" ? 0.55 : 1))
        if p.kind == "puff" { fillCircle(p.x, p.y, p.size, cFart) }
        else { cg.setFillColor(cAccent.cgColor); star(p.x, p.y, p.size, 5) }
        cg.setAlpha(1)
    }
    private func star(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ n: Int) {
        let path = CGMutablePath()
        for i in 0..<(n*2) { let ang = CGFloat(i)*CGFloat.pi/CGFloat(n) - .pi/2; let rr = i % 2 == 1 ? r*0.45 : r
            let pt = CGPoint(x: x + cos(ang)*rr, y: y + sin(ang)*rr); if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) } }
        path.closeSubpath(); cg.addPath(path); cg.fillPath()
    }
    private func drawFloater(_ f: Floater) {
        cg.setAlpha(max(0, f.life/f.maxLife)); text(f.text, f.x, f.y, f.size, f.color); cg.setAlpha(1)
    }
    private func burst(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) {
        let n = 11; let path = CGMutablePath()
        for i in 0..<(n*2) { let a = CGFloat(i)*CGFloat.pi/CGFloat(n); let rr = i % 2 == 1 ? r*0.55 : r
            let pt = CGPoint(x: cx + cos(a)*rr, y: cy + sin(a)*rr); if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) } }
        path.closeSubpath(); cg.addPath(path); cg.fillPath()
    }
    private func drawPops() {
        for p in pops {
            let el = p.maxLife - p.life; let sc = el < 0.11 ? el/0.11*1.15 : 1.05; let a = min(1, p.life/0.28)
            cg.saveGState(); cg.translateBy(x: p.x, y: p.y); cg.rotate(by: p.rot); cg.scaleBy(x: sc, y: sc); cg.setAlpha(a)
            cg.setFillColor(UIColor.black.cgColor); burst(0, 0, 25)
            cg.setFillColor(p.color.cgColor); burst(0, 0, 21)
            text(p.text, 0, 1, 14, .black)
            cg.restoreGState(); cg.setAlpha(1)
        }
    }
    private func drawPeel(_ p: Peel) {
        cg.saveGState(); cg.translateBy(x: p.x, y: GROUND_Y-2); cg.setAlpha(min(1, p.life*2))
        let col = p.kind == "brown" ? hex("9a6a34") : cBanana
        for d in [CGFloat(-1), 0, 1] {
            let path = CGMutablePath(); path.move(to: CGPoint(x: 0, y: 0))
            path.addQuadCurve(to: CGPoint(x: d*17, y: -1), control: CGPoint(x: d*11, y: -11))
            path.addQuadCurve(to: CGPoint(x: 0, y: 3), control: CGPoint(x: d*10, y: 3))
            path.closeSubpath()
            cg.addPath(path); cg.setFillColor(col.cgColor); cg.fillPath()
            cg.addPath(path); cg.setStrokeColor(cOutline.cgColor); cg.setLineWidth(2); cg.strokePath()
        }
        cg.setFillColor(col.cgColor); cg.fillEllipse(in: CGRect(x: -5, y: -3, width: 10, height: 6))
        cg.restoreGState(); cg.setAlpha(1)
    }
    private func drawPowerup(_ pu: PowerUp) {
        if pu.life < 1.4 && Int(pu.life*8) % 2 == 0 { return }
        let col = puColor(pu.kind); let yy = pu.y + sin(pu.life*5)*2; let big = pu.kind == "mega"
        cg.saveGState(); cg.translateBy(x: pu.x, y: yy)
        if big { cg.setAlpha(0.4 + 0.35*sin(pu.life*8)); cg.setStrokeColor(col.cgColor); cg.setLineWidth(3); cg.strokeEllipse(in: CGRect(x: -22, y: -22, width: 44, height: 44)); cg.setAlpha(1) }
        let rr: CGFloat = big ? 17 : 15
        cg.setShadow(offset: .zero, blur: big ? 18 : 12, color: col.cgColor); fillCircle(0, 0, rr, col); cg.setShadow(offset: .zero, blur: 0, color: nil)
        switch pu.kind {
        case "gold": cg.setFillColor(hex("7a5a10").cgColor); star(0, 0, 8, 5)
        case "mask":
            cg.setFillColor(hex("0a3a44").cgColor); let p = CGMutablePath()
            p.move(to: CGPoint(x: 0, y: -8)); p.addLine(to: CGPoint(x: 8, y: -3)); p.addLine(to: CGPoint(x: 6, y: 7))
            p.addLine(to: CGPoint(x: 0, y: 10)); p.addLine(to: CGPoint(x: -6, y: 7)); p.addLine(to: CGPoint(x: -8, y: -3)); p.closeSubpath()
            cg.addPath(p); cg.fillPath()
        case "plug":
            cg.setStrokeColor(hex("2a1050").cgColor); cg.setLineWidth(2); cg.strokeEllipse(in: CGRect(x: -7, y: -7, width: 14, height: 14))
            cg.move(to: CGPoint(x: 0, y: 0)); cg.addLine(to: CGPoint(x: 0, y: -5)); cg.move(to: CGPoint(x: 0, y: 0)); cg.addLine(to: CGPoint(x: 4, y: 1)); cg.strokePath()
        case "beano":
            for (bx, by, br) in [(-4.0, 2.0, 4.0), (3.0, -1.0, 5.0), (1.0, 6.0, 3.0)] { fillCircle(CGFloat(bx), CGFloat(by), CGFloat(br), hex("0c3a10")) }
        case "bean":
            cg.setFillColor(hex("5a2e00").cgColor); let p = CGMutablePath()
            p.move(to: CGPoint(x: 2, y: -9)); p.addLine(to: CGPoint(x: -5, y: 1)); p.addLine(to: CGPoint(x: 0, y: 1))
            p.addLine(to: CGPoint(x: -3, y: 9)); p.addLine(to: CGPoint(x: 6, y: -2)); p.addLine(to: CGPoint(x: 0, y: -2)); p.closeSubpath()
            cg.addPath(p); cg.fillPath()
        default:
            cg.setFillColor(hex("5a0033").cgColor); star(0, 0, 9, 7)
        }
        cg.restoreGState()
    }
    private func drawEffectPips() {
        var list: [(CGFloat, UIColor, String)] = []
        if P.shieldT > 0 { list.append((P.shieldT/PU_SHIELD, cMask, "SHIELD")) }
        if P.x2T > 0 { list.append((P.x2T/PU_X2, cGold, "x2")) }
        if P.slowT > 0 { list.append((P.slowT/PU_SLOW, cPlug, "SLO-MO")) }
        if P.freeFartT > 0 { list.append((P.freeFartT/PU_FREE, cBean, "RAPID")) }
        if list.isEmpty { return }
        let pw: CGFloat = 66, ph: CGFloat = 13, gap: CGFloat = 6
        let tot = CGFloat(list.count)*pw + CGFloat(list.count-1)*gap; let x0 = LW/2 - tot/2; let y: CGFloat = 52
        for (i, e) in list.enumerated() {
            let x = x0 + CGFloat(i)*(pw+gap)
            roundRect(x-1, y-1, pw+2, ph+2, 5, UIColor(white: 0, alpha: 0.45))
            roundRect(x, y, pw*max(0, e.0), ph, 4, e.1)
            text(e.2, x + pw/2, y + ph/2, 9, .black)
        }
    }

    private func drawHUD() {
        for i in 0..<LIVES_MAX { cg.setAlpha(i < lives ? 1 : 0.22); drawHeart(24 + CGFloat(i)*26, 22, 9) }
        cg.setAlpha(1)
        text("\(Int(score))", LW-12, 20, 22, cAccent, align: .right)
        cg.setAlpha(0.6); text("BEST \(best)", LW-12, 40, 11, cText, align: .right); cg.setAlpha(1)
        if combo > 1 { text("COMBO x\(combo)", LW/2, 16, 18, cFart) }
        if st == .play {
            text("LEVEL \(level) / 10", LW/2, 64, 13, cAccent)
            let cfg = LEVELS[level-1]; let prog = min(1, levelT/cfg.secs); let bw: CGFloat = 190, bx = LW/2 - bw/2, by = CTRL_TOP - 40
            roundRect(bx-1, by-1, bw+2, 10, 4, UIColor(white: 0, alpha: 0.4))
            roundRect(bx, by, bw*prog, 8, 3, UIColor(hue: prog*120/360, saturation: 0.8, brightness: 0.55, alpha: 1))
            cg.setAlpha(0.7); text("SURVIVE!", LW/2, by-7, 9, cText); cg.setAlpha(1)
        }
        if st == .boss, let b = boss {
            let bw: CGFloat = 264, bx = LW/2 - bw/2, by: CGFloat = 60, frac = max(0, b.hp/b.maxHp)
            roundRect(bx-2, by-2, bw+4, 16, 5, UIColor(white: 0, alpha: 0.55))
            roundRect(bx, by, bw*frac, 12, 4, hex("aa0000"))
            roundRect(bx, by, bw*frac, 5, 3, hex("ff4444"))
            roundRect(bx, by, bw, 12, 4, .clear, fill: false, stroke: cAccent, lw: 2)
            text("KING KONG-A-TOOT - PHASE \(b.phase)", LW/2, by-7, 11, cAccent)
        }
        let gw: CGFloat = 150, gh: CGFloat = 13, gx = LW/2 - gw/2, gy = CTRL_TOP - 24
        let ready = P.gas >= BLAST_COST
        roundRect(gx-2, gy-2, gw+4, gh+4, 5, UIColor(white: 0, alpha: 0.4))
        roundRect(gx, gy, gw*(P.gas/GAS_MAX), gh, 4, ready ? cFart : UIColor(white: 0.5, alpha: 0.6))
        roundRect(gx, gy, gw, gh, 4, .clear, fill: false, stroke: UIColor(white: 1, alpha: 0.4), lw: 1)
        text("GAS", LW/2, gy + gh/2, 9, .white)
        if tipT > 0 { cg.setAlpha(min(1, tipT)); text("\u{1F4A8} fart a banana BACK + shield!", LW/2, GROUND_Y-44, 14, cText); cg.setAlpha(1) }
    }
    private func drawHeart(_ x: CGFloat, _ y: CGFloat, _ sz: CGFloat) {
        cg.setFillColor(hex("ff4d6d").cgColor)
        cg.move(to: CGPoint(x: x, y: y + sz*0.4))
        cg.addCurve(to: CGPoint(x: x, y: y + sz), control1: CGPoint(x: x - sz, y: y - sz*0.6), control2: CGPoint(x: x - sz*1.1, y: y + sz*0.3))
        cg.addCurve(to: CGPoint(x: x, y: y + sz*0.4), control1: CGPoint(x: x + sz*1.1, y: y + sz*0.3), control2: CGPoint(x: x + sz, y: y - sz*0.6))
        cg.fillPath()
    }
    private func drawControls() {
        UIColor(white: 0, alpha: 0.32).setFill(); cg.fill(CGRect(x: 0, y: CTRL_TOP, width: LW, height: LH - CTRL_TOP))
        for b in buttons {
            let pressed = touchBtn.values.contains(b.id), isFart = b.id == "FART", ready = isFart ? P.gas >= BLAST_COST : true
            cg.setAlpha(pressed ? 0.95 : 0.6)
            (isFart ? (ready ? cBorder : UIColor(white: 0.33, alpha: 1)) : UIColor(white: 1, alpha: 0.12)).setFill()
            fillCircle(b.cx, b.cy, b.r, isFart ? (ready ? cBorder : UIColor(white: 0.33, alpha: 1)) : UIColor(white: 1, alpha: 0.12))
            cg.setAlpha(pressed ? 1 : 0.85)
            cg.setStrokeColor((isFart ? (ready ? cAccent : UIColor(white: 0.53, alpha: 1)) : UIColor(white: 1, alpha: 0.5)).cgColor)
            cg.setLineWidth(2.5); cg.strokeEllipse(in: CGRect(x: b.cx-b.r, y: b.cy-b.r, width: b.r*2, height: b.r*2))
            cg.setAlpha(1)
            text(b.glyph, b.cx, b.cy, isFart ? 30 : 24, .white, weight: .regular)
        }
    }

    // MARK: - Screens
    private func panel(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
        roundRect(x, y, w, h, 16, cPanel, stroke: cOutline, lw: 6)
        roundRect(x+6, y+6, w-12, h-12, 11, .clear, fill: false, stroke: cAccent, lw: 2.5)
    }
    private func drawStart() {
        drawBg()
        panel(LW/2-205, 120, 410, 400)
        text("FART BACK!", LW/2, 190, 40, cAccent)
        text("Monkey Madness", LW/2, 230, 15, cText)
        text("Monkeys fart bananas at you.", LW/2, 290, 16, cText, weight: .semibold)
        text("Dodge them, then fart them RIGHT BACK", LW/2, 316, 15, cText, weight: .semibold)
        text("to stun the monkeys!", LW/2, 340, 15, cText, weight: .semibold)
        text("\u{25C0} \u{25B6} move    \u{2912} jump    \u{1F4A8} FART", LW/2, 392, 15, cAccent)
        if Int(Date().timeIntervalSince1970*2) % 2 == 0 { text("TAP TO START", LW/2, 460, 22, cAccent) }
        if best > 0 { cg.setAlpha(0.6); text("Best: \(best)", LW/2, 496, 12, cText); cg.setAlpha(1) }
    }
    private func drawOver() {
        drawBg()
        for p in particles { drawParticle(p) }
        panel(LW/2-190, LH/2-150, 380, 260)
        text("GAME OVER", LW/2, LH/2-96, 36, hex("ff5a5a"))
        text("Score \(Int(score))", LW/2, LH/2-44, 28, cAccent)
        cg.setAlpha(0.7); text("Best \(best)", LW/2, LH/2-8, 15, cText); cg.setAlpha(1)
        if Int(Date().timeIntervalSince1970*2) % 2 == 0 { text("Tap to fart again!", LW/2, LH/2+52, 18, cText) }
    }
    private func drawBoss(_ b: Boss) {
        let x = b.bx, y = b.by; let col = b.hitFlash > 0 ? UIColor.white : cMonkeyBody
        let roar = b.roarT > 0, weak = b.weakT > 0, dying = b.deathT > 0
        let sc: CGFloat = roar ? 1.16 : 1, yOff: CGFloat = b.slamHit > 0 ? 18*(b.slamHit/0.28) : 0
        if weak { cg.saveGState(); cg.setAlpha(0.32 + 0.3*abs(sin(b.wob))); fillCircle(x, y, 74, cFart); cg.setAlpha(1); cg.restoreGState() }
        cg.saveGState(); cg.translateBy(x: x, y: y+yOff); if dying { cg.rotate(by: b.wob*0.5) }; cg.scaleBy(x: sc, y: sc); cg.translateBy(x: -x, y: -y)
        if !dying {
            cg.setStrokeColor(col.cgColor); cg.setLineWidth(13); cg.setLineCap(.round)
            cg.move(to: CGPoint(x: x-48, y: BRANCH_Y+2)); cg.addLine(to: CGPoint(x: x-26, y: y-28))
            cg.move(to: CGPoint(x: x+48, y: BRANCH_Y+2)); cg.addLine(to: CGPoint(x: x+26, y: y-28)); cg.strokePath()
        }
        fillEllipse(x-30, y-30, 15, 15, cEar); fillEllipse(x+30, y-30, 15, 15, cEar)
        fillEllipse(x, y+28, 44, 32, col); fillEllipse(x, y-24, 36, 30, col); fillEllipse(x, y-19, 23, 19, cMonkeyFace)
        drawEyes(x-12, y-22, x+12, y-22, dead: weak || dying)
        cg.setStrokeColor(cOutline.cgColor); cg.setLineWidth(4); cg.setLineCap(.round)
        cg.move(to: CGPoint(x: x-20, y: y-32)); cg.addLine(to: CGPoint(x: x-6, y: y-27))
        cg.move(to: CGPoint(x: x+20, y: y-32)); cg.addLine(to: CGPoint(x: x+6, y: y-27)); cg.strokePath()
        if roar || weak {
            cg.setFillColor(hex("3a0f12").cgColor); cg.fillEllipse(in: CGRect(x: x-15, y: y-18, width: 30, height: 26))
            cg.setFillColor(hex("ff6b9a").cgColor); cg.fillEllipse(in: CGRect(x: x-8, y: y-6, width: 16, height: 12))
        }
        fillEllipse(x-22, y+42, 20, 17, col); fillEllipse(x+22, y+42, 20, 17, col)
        cg.setStrokeColor(cOutline.cgColor); cg.setLineWidth(3); cg.move(to: CGPoint(x: x, y: y+26)); cg.addLine(to: CGPoint(x: x, y: y+58)); cg.strokePath()
        let cw: CGFloat = 54, cx = x - cw/2, cy = y - 58
        cg.setFillColor(hex("ffd700").cgColor); cg.setStrokeColor(hex("b8860b").cgColor); cg.setLineWidth(2)
        let cp = CGMutablePath()
        cp.move(to: CGPoint(x: cx, y: cy+18)); cp.addLine(to: CGPoint(x: cx, y: cy+2)); cp.addLine(to: CGPoint(x: cx+cw*0.25, y: cy+12))
        cp.addLine(to: CGPoint(x: cx+cw*0.5, y: cy-6)); cp.addLine(to: CGPoint(x: cx+cw*0.75, y: cy+12)); cp.addLine(to: CGPoint(x: cx+cw, y: cy+2)); cp.addLine(to: CGPoint(x: cx+cw, y: cy+18)); cp.closeSubpath()
        cg.addPath(cp); cg.fillPath(); cg.addPath(cp); cg.strokePath()
        cg.restoreGState()
        if b.chargeT > 0 && !weak {
            cg.setAlpha(0.65); for k in 0..<6 { fillCircle(x + sin(CGFloat(k)*1.5)*18, y + 62 + CGFloat(k)*5, 15 - CGFloat(k)*1.6, cFart) }; cg.setAlpha(1)
            text("!!", x, y - 78, 22, hex("ff5a5a"))
        }
        if b.slamT > 0 { text("SLAM!", x, y - 78, 20, hex("ff5a5a")) }
        if roar { text("ROAAR!", x, y - 84, 22, hex("ff5a5a")) }
        if weak {
            for k in 0..<3 { let a = b.wob + CGFloat(k)*2.1; text("✦", x + cos(a)*42, y - 42 + sin(a)*10, 11, cAccent) }
            text("HIT THE WEAK POINT!", x, y - 84, 13, cAccent)
        }
    }
    private func drawLevelDone() {
        panel(LW/2-180, LH/2-120, 360, 240)
        text("LEVEL \(level)!", LW/2, LH/2-56, 34, cFart)
        text("Cleared!", LW/2, LH/2-16, 17, cText)
        text(level >= 9 ? "BOSS is next!" : "Get ready for Level \(level+1)", LW/2, LH/2+16, 15, cAccent)
        cg.setAlpha(0.85); text("Score \(Int(score))   Lives \(lives)", LW/2, LH/2+44, 13, cText); cg.setAlpha(1)
        if Int(Date().timeIntervalSince1970*2) % 2 == 0 { text("Tap to continue", LW/2, LH/2+88, 16, cText) }
    }
    private func drawWin() {
        drawBg(); for p in particles { drawParticle(p) }
        panel(LW/2-200, 100, 400, 480)
        text("YOU WIN!", LW/2, 170, 40, cBanana)
        text("You defeated the", LW/2, 216, 18, cText)
        text("BOSS MONKEY!", LW/2, 242, 18, cText)
        text("$10 ADDED TO", LW/2, 318, 25, cFart)
        text("YOUR BANK!", LW/2, 352, 25, cFart)
        text("Amazing job!", LW/2, 410, 18, cAccent)
        text("Final score \(Int(score))", LW/2, 446, 15, cText)
        if Int(Date().timeIntervalSince1970*2) % 2 == 0 { text("Tap to play again", LW/2, 556, 14, cText) }
    }
}
