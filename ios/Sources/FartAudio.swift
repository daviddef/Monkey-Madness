import AVFoundation

/// Plays real fart samples (bundled WAVs) with pitch variation, falling back to a
/// procedural synth if the samples don't load. Mirrors the web build's audio layer.
final class FartAudio {
    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
    private var players: [AVAudioPlayerNode] = []
    private var varis: [AVAudioUnitVarispeed] = []
    private var samples: [AVAudioPCMBuffer] = []
    private var idx = 0
    private let sr: Double = 44100
    private var ok = false

    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { }
        let mixer = engine.mainMixerNode
        mixer.outputVolume = 0.8
        for _ in 0..<14 {
            let p = AVAudioPlayerNode(); let v = AVAudioUnitVarispeed()
            engine.attach(p); engine.attach(v)
            engine.connect(p, to: v, format: format)
            engine.connect(v, to: mixer, format: format)
            players.append(p); varis.append(v)
        }
        loadSamples()
        do { try engine.start(); ok = true } catch { ok = false }
        for p in players { p.play() }
    }

    private func loadSamples() {
        for i in 1...8 {
            let name = String(format: "fart_%02d", i)
            guard let url = Bundle.main.url(forResource: name, withExtension: "wav"),
                  let file = try? AVAudioFile(forReading: url) else { continue }
            let len = AVAudioFrameCount(file.length)
            guard len > 0, let buf = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: len) else { continue }
            do { try file.read(into: buf); samples.append(buf) } catch { }
        }
    }

    private func next() -> Int { let i = idx; idx = (idx + 1) % players.count; return i }

    /// Play a random real fart sample at a given playback rate (pitch/speed) and volume.
    private func playSample(rate: Float, gain: Float) {
        guard ok, !samples.isEmpty else { return }
        let i = next()
        varis[i].rate = max(0.5, min(2.0, rate))
        players[i].volume = gain
        let buf = samples[Int.random(in: 0..<samples.count)]
        players[i].scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
    }

    /// A fart — uses a real sample when available (pitch scaled from `freq`), else the synth.
    /// Master switch for fart/SFX noises only — music has its own toggle and its own player.
    var sfxEnabled = true
    func fart(freq: Double, dur: Double, flutter: Double, cutoff: Double, gain: Double, square: Bool = false) {
        guard ok, sfxEnabled else { return }
        if !samples.isEmpty {
            let rate = Float(min(1.7, max(0.6, freq / 150.0)))   // jump=high squeak, blast/boss=low & beefy
            playSample(rate: rate, gain: Float(min(1.0, gain * 1.5)))
            return
        }
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
        let i = next(); varis[i].rate = 1; players[i].volume = 1
        players[i].scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
    }

    // MARK: - Music
    // Synthesised, not sampled: no licensing, no download, and each world gets its own
    // key/tempo/voice for free. AVAudioEngine can't schedule oscillators the way Web Audio
    // can, so we RENDER one bar into a buffer and loop it — one node, no timer jitter.
    private var musicPlayer: AVAudioPlayerNode?
    private var musicMixer: AVAudioMixerNode?
    private var musicPlaying = false

    private func renderBar(root: Double, bpm: Double, scale: [Int], wave: String, lead: String) -> AVAudioPCMBuffer? {
        let beat = 60.0/bpm/2.0                 // eighth notes
        let steps = 16
        let n = Int(sr*beat*Double(steps))
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(n)) else { return nil }
        buf.frameLength = AVAudioFrameCount(n)
        guard let out = buf.floatChannelData?[0] else { return nil }
        for i in 0..<n { out[i] = 0 }

        func osc(_ type: String, _ phase: Double) -> Double {
            switch type {
            case "square":   return sin(phase) >= 0 ? 1 : -1
            case "sawtooth": return phase.truncatingRemainder(dividingBy: 2*Double.pi)/Double.pi - 1
            case "triangle": return 2*abs(phase.truncatingRemainder(dividingBy: 2*Double.pi)/Double.pi - 1) - 1
            default:         return sin(phase)
            }
        }
        func add(freq: Double, at: Double, dur: Double, type: String, gain: Double) {
            let start = Int(at*sr), len = Int(dur*sr)
            var phase = 0.0
            for k in 0..<len {
                let idx = start + k; if idx < 0 || idx >= n { continue }
                phase += 2*Double.pi*freq/sr
                let env = min(1.0, Double(k)/(sr*0.012)) * exp(-3.2*Double(k)/Double(len))
                out[idx] += Float(osc(type, phase) * env * gain)
            }
        }
        for st in 0..<steps {
            let t = Double(st)*beat
            if st % 4 == 0 { add(freq: root/2, at: t, dur: beat*1.7, type: wave, gain: 0.34) }          // bass
            if st % 2 == 0 { let d = scale[(st/2*3) % scale.count]                                       // arp
                add(freq: root*pow(2, Double(d)/12), at: t, dur: beat*0.8, type: lead, gain: 0.15) }
            if st % 8 == 6 { let d = scale[st % scale.count]                                             // turn-around
                add(freq: root*2*pow(2, Double(d)/12), at: t, dur: beat*0.6, type: lead, gain: 0.10) }
        }
        // guard against clipping where voices overlap
        var peak: Float = 0
        for i in 0..<n { peak = max(peak, abs(out[i])) }
        if peak > 0.9 { let k = 0.9/peak; for i in 0..<n { out[i] *= k } }
        return buf
    }

    /// Swap the loop to a theme's voice. Pass nil to stop.
    func setMusic(root: Double?, bpm: Double = 120, scale: [Int] = [0,3,5,7,10], wave: String = "square", lead: String = "sawtooth", gain: Double = 0.16) {
        guard ok else { return }
        guard let root else {
            musicPlayer?.stop(); musicPlaying = false; return
        }
        if musicMixer == nil {
            let mx = AVAudioMixerNode(); engine.attach(mx); engine.connect(mx, to: engine.mainMixerNode, format: format); musicMixer = mx
        }
        if musicPlayer == nil {
            let p = AVAudioPlayerNode(); engine.attach(p); engine.connect(p, to: musicMixer!, format: format); musicPlayer = p
        }
        guard let p = musicPlayer, let mx = musicMixer else { return }
        p.stop()
        mx.outputVolume = Float(gain)
        guard let bar = renderBar(root: root, bpm: bpm, scale: scale, wave: wave, lead: lead) else { return }
        p.scheduleBuffer(bar, at: nil, options: [.loops], completionHandler: nil)   // seamless, no timer
        p.play(); musicPlaying = true
    }
    func stopMusic() { musicPlayer?.stop(); musicPlaying = false }

    /// A clean pitch-sweep tone (stun sparkle / deflect boing / pickup) — always synth.
    func tone(f0: Double, f1: Double, dur: Double, gain: Double) {
        guard ok, sfxEnabled else { return }
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
        let i = next(); varis[i].rate = 1; players[i].volume = 1
        players[i].scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
    }
}
