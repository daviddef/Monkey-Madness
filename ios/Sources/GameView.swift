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
    var face: Int = 0, faceT: CGFloat = 0, mushT: CGFloat = 0
}
private final class Monkey {
    var x: CGFloat, y: CGFloat, bx: CGFloat, by: CGFloat
    var swingT: CGFloat, swayX: CGFloat, vx: CGFloat, retargetT: CGFloat
    var throwT: CGFloat, angryT: CGFloat = 0, stun: CGFloat = 0, wob: CGFloat = 0, gust: CGFloat = 0
    init(x: CGFloat, y: CGFloat) {
        self.x = x; self.y = y; bx = x; by = y
        swingT = R(0, 6.28); swayX = R(7, 13)
        vx = (Bool.random() ? -1 : 1) * R(30, 68); retargetT = R(1.4, 3.4); throwT = R(0.7, 1.8)
    }
}
private final class Banana {
    var x: CGFloat, y: CGFloat, vx: CGFloat, vy: CGFloat, rot: CGFloat, rotV: CGFloat
    var friendly: Bool; var type: String
    init(x: CGFloat, y: CGFloat, vx: CGFloat, vy: CGFloat, rotV: CGFloat, friendly: Bool, type: String) {
        self.x = x; self.y = y; self.vx = vx; self.vy = vy; rot = 0; self.rotV = rotV; self.friendly = friendly; self.type = type
    }
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
    private let LIVES_MAX = 4

    // Loud theme palette
    private let cBgBase = hex("2a1857"), cBgDot = hex("ff3d7f"), cGround = hex("17d1e8"), cGroundEdge = hex("0fb0c6")
    private let cOutline = hex("000000"), cMonkeyBody = hex("8a4bd6"), cMonkeyFace = hex("ffe022"), cEar = hex("7a3ec6")
    private let cPlayerBody = hex("17d1e8"), cPlayerSkin = hex("ffb0c7"), cBanana = hex("ffe234"), cBananaTip = hex("e0b800")
    private let cFart = hex("7CFF5A"), cAccent = hex("ffe022"), cText = hex("ffffff"), cPanel = hex("2a1857", 0.92), cBorder = hex("ff3d7f")
    private let cWood = hex("3a2557"), cLeaf = hex("17d1e8")

    // state
    private enum St { case start, play, over }
    private var st: St = .start
    private var lives = 4
    private var score: CGFloat = 0
    private var best = UserDefaults.standard.integer(forKey: "fartback_best")
    private var combo = 0
    private var gameT: CGFloat = 0, tipT: CGFloat = 3.5
    private var shakeT: CGFloat = 0, shakeMag: CGFloat = 0

    private let P = Player()
    private var monkeys: [Monkey] = []
    private var bananas: [Banana] = []
    private var particles: [Particle] = []
    private var clouds: [Cloud] = []
    private var floaters: [Floater] = []

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
    }
    func stop() { link?.invalidate(); link = nil }

    @objc private func tick(_ dl: CADisplayLink) {
        if lastTs == 0 { lastTs = dl.timestamp; return }
        let dt = min(CGFloat(dl.timestamp - lastTs), 0.05)
        lastTs = dl.timestamp
        update(dt)
        setNeedsDisplay()
    }

    // MARK: - Flow
    private func startGame() {
        st = .play; lives = LIVES_MAX; score = 0; combo = 0; gameT = 0; tipT = 3.5
        bananas.removeAll(); particles.removeAll(); clouds.removeAll(); floaters.removeAll()
        P.x = LW/2; P.y = PLAYER_GY; P.vy = 0; P.onGround = true; P.inv = true; P.invT = 1.2; P.blinkT = 0
        P.gas = GAS_MAX; P.squashT = 0; P.blastFlash = 0; P.barrierT = 0; P.face = 0; P.faceT = 0; P.mushT = 0
        monkeys.removeAll(); setMonkeyCount(1)
    }
    private func setMonkeyCount(_ n: Int) {
        while monkeys.count < n { monkeys.append(Monkey(x: R(60, LW-60), y: R(94, 110))) }
    }
    private func doJump() {
        guard st == .play, P.onGround else { return }
        P.vy = JUMP; P.onGround = false
        audio.fart(freq: Double(R(200, 260)), dur: 0.15, flutter: 28, cutoff: 1700, gain: 0.28, square: true)
        for _ in 0..<7 { particles.append(puff(P.x + R(-8, 8), PLAYER_GY + 20, R(-40, 40), R(20, 90))) }
        clouds.append(Cloud(x: P.x, y: PLAYER_GY + 22, r: 12, life: 0.7))
    }
    private func doBlast() {
        guard st == .play else { return }
        if P.gas < BLAST_COST { return }
        P.gas -= BLAST_COST; P.blastFlash = 0.22; P.face = 2; P.faceT = 0.4; P.barrierT = BARRIER_T; addShake(7, 0.18)
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

    private func hitPlayer(_ bx: CGFloat, _ by: CGFloat, _ type: String) {
        if type == "brown" { P.mushT = 1.2; combo = 0; P.face = 1; P.faceT = 1; P.inv = true; P.invT = 0.7; P.blinkT = 0
            burstFx(bx, by, 6); addShake(6, 0.18); addFloat(P.x, P.y-44, "SPLAT!", hex("b07a44"), 18); return }
        lives -= 1; combo = 0; P.inv = true; P.invT = 1.8; P.blinkT = 0; P.face = 1; P.faceT = 1
        burstFx(bx, by, 10); addShake(type == "black" ? 14 : 12, 0.3)
        audio.fart(freq: 270, dur: 0.5, flutter: 22, cutoff: 1300, gain: 0.4)
        addFloat(P.x, P.y-44, type == "black" ? "BLECH!" : "OUCH!", hex("ff5a5a"), 20)
        if lives <= 0 { gameOver() }
    }
    private func gameOver() {
        st = .over; burstFx(P.x, P.y, 16); addShake(14, 0.4)
        audio.fart(freq: 150, dur: 0.7, flutter: 10, cutoff: 900, gain: 0.5)
        let fs = Int(score); if fs > best { best = fs; UserDefaults.standard.set(best, forKey: "fartback_best") }
    }

    // MARK: - Update
    private func update(_ dt: CGFloat) {
        particles = particles.filter { p in p.x += p.vx*dt; p.y += p.vy*dt; p.vy += (p.kind == "star" ? 520 : 40)*dt; p.life -= dt; return p.life > 0 }
        clouds = clouds.filter { c in c.r += dt*26; c.life -= dt; c.x += sin(c.life*6)*8*dt; return c.life > 0 }
        floaters = floaters.filter { f in f.y += f.vy*dt; f.vy += 60*dt; f.life -= dt; return f.life > 0 }
        if shakeT > 0 { shakeT -= dt }
        guard st == .play else { return }
        gameT += dt; if tipT > 0 { tipT -= dt }; score += dt*8
        let want = min(5, 1 + Int(gameT/16)); if monkeys.count < want { setMonkeyCount(want) }

        // player
        if leftHeld() { P.x -= PSPEED*(P.mushT > 0 ? 0.45 : 1)*dt }
        if rightHeld() { P.x += PSPEED*(P.mushT > 0 ? 0.45 : 1)*dt }
        P.x = max(24, min(LW-24, P.x))
        if !P.onGround { P.vy += GRAV*dt; P.y += P.vy*dt
            if P.y >= PLAYER_GY { P.y = PLAYER_GY; P.vy = 0; P.onGround = true; P.squashT = 0.18
                for _ in 0..<5 { particles.append(puff(P.x + R(-10, 10), PLAYER_GY+20, R(-60, 60), R(-10, 30))) } } }
        if P.squashT > 0 { P.squashT -= dt }
        if P.inv { P.invT -= dt; P.blinkT += dt; if P.invT <= 0 { P.inv = false } }
        if P.faceT > 0 { P.faceT -= dt; if P.faceT <= 0 { P.face = 0 } }
        if P.blastFlash > 0 { P.blastFlash -= dt }; if P.barrierT > 0 { P.barrierT -= dt }; if P.mushT > 0 { P.mushT -= dt }
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
            if m.throwT <= 0 {
                m.throwT = max(0.7, 1.9 - gameT*0.02) * R(0.7, 1.35); m.angryT = 0.4; m.gust = 0.4
                let flight = max(0.5, 0.95 - gameT*0.006), spread = min(0.5, 0.1 + gameT*0.006)
                let count = gameT > 50 ? 3 : (gameT > 24 ? 2 : 1)
                let roll = CGFloat.random(in: 0...1); let bt = roll < 0.26 ? "black" : (roll < 0.48 ? "brown" : "yellow")
                throwBanana(m.bx, m.by+24, P.x, flight, count, spread, bt)
                audio.fart(freq: Double(R(115, 155)), dur: 0.2, flutter: 20, cutoff: 1000, gain: 0.3)
                if bt == "black" { for _ in 0..<8 { let a = R(1.5, 3.0); particles.append(puff(m.bx + R(-6, 6), m.by+26, cos(a)*R(30, 90), sin(a)*R(30, 90)+30)) } }
            }
        }
        // separation
        for i in 0..<monkeys.count { for j in (i+1)..<monkeys.count {
            let a = monkeys[i], b = monkeys[j]; if a.stun > 0 || b.stun > 0 { continue }
            let d = b.x - a.x; let dir: CGFloat = d == 0 ? (i % 2 == 1 ? 1 : -1) : (d < 0 ? -1 : 1)
            if abs(d) < 48 { a.x -= dir*1.6; b.x += dir*1.6; a.vx = -dir*abs(a.vx); b.vx = dir*abs(b.vx) }
        } }
        for m in monkeys { m.x = max(52, min(LW-52, m.x)) }

        // bananas
        bananas = bananas.filter { b in
            b.vy += GRAV*dt; b.x += b.vx*dt; b.y += b.vy*dt; b.rot += b.rotV*dt
            if b.type == "black" && !b.friendly && CGFloat.random(in: 0...1) < 0.35 { particles.append(puff(b.x, b.y, R(-20, 20), R(-10, 20))) }
            if b.x < -60 || b.x > LW+60 || b.y > LH+80 { return false }
            if b.friendly {
                if b.y < -60 { return false }
                for m in monkeys where m.stun <= 0 {
                    let dx = b.x - m.bx, dy = b.y - m.by
                    if dx*dx + dy*dy < 30*30 {
                        m.stun = 3; m.wob = 0; m.angryT = 0; combo += 1
                        let pts = 100 * combo; score += CGFloat(pts)
                        addFloat(m.bx, m.by-38, "+\(pts)" + (combo > 1 ? "  x\(combo)" : ""), cAccent, combo > 2 ? 22 : 17)
                        burstFx(m.bx, m.by, 12); addShake(combo >= 3 ? 9 : 6, 0.16); audio.tone(f0: 520, f1: 120, dur: 0.3, gain: 0.24); return false
                    }
                }
                return true
            }
            if P.barrierT > 0 { let dx = b.x - P.x, dy = b.y - P.y; if abs(dx) < 64 && dy > -74 && dy < 14 { burstFx(b.x, b.y, 4); score += 8; return false } }
            if !P.inv { let dx = abs(b.x - P.x), dy = abs(b.y - P.y); if dx < 22 && dy < 26 { hitPlayer(b.x, b.y, b.type); return false } }
            return true
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
            if st != .play { startGame(); return }
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

        ctx.saveGState()
        if shakeT > 0 { ctx.translateBy(x: R(-1, 1)*shakeMag*shakeT, y: R(-1, 1)*shakeMag*shakeT) }
        drawBg()
        for c in clouds { drawCloud(c) }
        for m in monkeys { drawMonkey(m) }
        for b in bananas { drawBanana(b) }
        drawPlayer()
        for p in particles { drawParticle(p) }
        for f in floaters { drawFloater(f) }
        ctx.restoreGState()

        drawHUD(); drawControls()
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
        cg.saveGState(); cg.translateBy(x: b.x, y: b.y); cg.rotate(by: b.rot); cg.translateBy(x: -10, y: -17)
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
        let x = m.bx, y = m.by
        cg.setStrokeColor(cMonkeyBody.cgColor); cg.setLineWidth(8); cg.setLineCap(.round)
        cg.move(to: CGPoint(x: m.x, y: BRANCH_Y+2)); cg.addLine(to: CGPoint(x: x-4, y: y-15)); cg.strokePath()
        fillCircle(m.x, BRANCH_Y+1, 5, cMonkeyBody)
        cg.saveGState(); cg.translateBy(x: x, y: y)
        cg.rotate(by: sin(m.swingT)*0.10 + (m.stun > 0 ? sin(m.wob)*0.2 : 0))
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
    }
    private func drawPlayer() {
        if P.inv && Int(P.blinkT*8) % 2 == 0 { return }
        var sx: CGFloat = 1, sy: CGFloat = 1
        if P.squashT > 0 { let k = P.squashT/0.18; sx = 1 + 0.32*k; sy = 1 - 0.32*k } else if !P.onGround { sy = 1.1; sx = 0.92 }
        cg.saveGState(); cg.translateBy(x: P.x, y: P.y); cg.scaleBy(x: sx, y: sy)
        if P.blastFlash > 0 { cg.setAlpha(0.7); for k in 0..<4 { fillCircle(-3 + CGFloat(k)*2, 26 + CGFloat(k)*4, 10 - CGFloat(k)*1.5, cFart) }; cg.setAlpha(1) }
        roundRect(-15, 4, 30, 26, 9, cPlayerBody, stroke: cOutline, lw: 5)
        fillEllipse(0, -8, 14, 14, cPlayerSkin)
        drawEyes(-5, -8, 5, -8, dead: false)
        cg.restoreGState()
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

    private func drawHUD() {
        for i in 0..<LIVES_MAX { cg.setAlpha(i < lives ? 1 : 0.22); drawHeart(24 + CGFloat(i)*26, 22, 9) }
        cg.setAlpha(1)
        text("\(Int(score))", LW-12, 20, 22, cAccent, align: .right)
        cg.setAlpha(0.6); text("BEST \(best)", LW-12, 40, 11, cText, align: .right); cg.setAlpha(1)
        if combo > 1 { text("COMBO x\(combo)", LW/2, 16, 18, cFart) }
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
}
