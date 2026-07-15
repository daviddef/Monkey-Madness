import AVFoundation

/// Procedural fart synth — mirrors the HTML Web Audio synth.
/// Generates short PCM buffers on the fly and plays them through a small pool
/// of player nodes so sounds can overlap.
final class FartAudio {
    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
    private var players: [AVAudioPlayerNode] = []
    private var idx = 0
    private let sr: Double = 44100
    private var ok = false

    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { }
        let mixer = engine.mainMixerNode
        mixer.outputVolume = 0.7
        for _ in 0..<12 {
            let p = AVAudioPlayerNode()
            engine.attach(p)
            engine.connect(p, to: mixer, format: format)
            players.append(p)
        }
        do { try engine.start(); ok = true } catch { ok = false }
        for p in players { p.play() }
    }

    private func nextPlayer() -> AVAudioPlayerNode { let p = players[idx]; idx = (idx + 1) % players.count; return p }

    /// A raspberry fart: gliding, warbling oscillator through a one-pole lowpass.
    func fart(freq: Double, dur: Double, flutter: Double, cutoff: Double, gain: Double, square: Bool = false) {
        guard ok else { return }
        let n = max(1, Int(sr * dur))
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(n)) else { return }
        buf.frameLength = AVAudioFrameCount(n)
        guard let out = buf.floatChannelData?[0] else { return }
        let fStart = freq * 1.35, fEnd = max(28, freq * 0.55)
        let alpha = 1.0 / (1.0 + sr / (2.0 * Double.pi * cutoff))
        var phase = 0.0, lp = 0.0
        for i in 0..<n {
            let t = Double(i) / sr, frac = t / dur
            let f = fStart * pow(fEnd / fStart, frac)
            let warble = 1.0 + 0.4 * sin(2 * Double.pi * flutter * t)
            phase += 2 * Double.pi * f * warble / sr
            let p = phase.truncatingRemainder(dividingBy: 2 * Double.pi)
            let raw = square ? (sin(phase) >= 0 ? 1.0 : -1.0) : (p / Double.pi - 1.0)
            let trem = 0.6 + 0.4 * ((2 * Double.pi * flutter * 0.9 * t).truncatingRemainder(dividingBy: 2 * Double.pi) / Double.pi - 1.0)
            let attack = min(1.0, Double(i) / (sr * 0.02))
            let env = attack * exp(-3.0 * frac)
            let sample = raw * trem * env * gain
            lp += alpha * (sample - lp)
            out[i] = Float(lp)
        }
        let pl = nextPlayer()
        pl.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
    }

    /// A clean pitch-sweep tone (stun sparkle / deflect boing).
    func tone(f0: Double, f1: Double, dur: Double, gain: Double) {
        guard ok else { return }
        let n = max(1, Int(sr * dur))
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(n)) else { return }
        buf.frameLength = AVAudioFrameCount(n)
        guard let out = buf.floatChannelData?[0] else { return }
        var phase = 0.0
        for i in 0..<n {
            let frac = Double(i) / Double(n)
            let f = f0 * pow(max(30, f1) / f0, frac)
            phase += 2 * Double.pi * f / sr
            let env = exp(-3.5 * frac)
            out[i] = Float(sin(phase) * env * gain)
        }
        let pl = nextPlayer()
        pl.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
    }
}
