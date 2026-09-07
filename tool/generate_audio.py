#!/usr/bin/env python3
"""
Procedural Audio & Music Generator for LIGHT vs SHADOW: Prism Defense
Author: GameAudioEngineer
Generates 8 SFX assets per docs/design.md §12.3 plus a seamless loopable BGM track.
Synthesizes 44.1kHz mono WAV and encodes to optimized MP3 via ffmpeg.
"""

import math
import os
import random
import struct
import subprocess
import sys
import wave

SAMPLE_RATE = 44100

def clamp(val, low=-1.0, high=1.0):
    return max(low, min(high, val))

def write_wav(filename, samples, sample_rate=SAMPLE_RATE):
    """Write float samples [-1.0, 1.0] to a 16-bit PCM mono WAV file."""
    with wave.open(filename, 'w') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        int_samples = [int(clamp(s) * 32767.0) for s in samples]
        raw_bytes = struct.pack(f'<{len(int_samples)}h', *int_samples)
        wf.writeframes(raw_bytes)

def encode_mp3(wav_file, mp3_file, bitrate="128k"):
    """Encode WAV to MP3 using ffmpeg with libmp3lame."""
    cmd = [
        "ffmpeg", "-y", "-i", wav_file,
        "-codec:a", "libmp3lame",
        "-b:a", bitrate,
        "-ar", str(SAMPLE_RATE),
        "-ac", "1",
        mp3_file
    ]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.remove(wav_file)

# -----------------------------------------------------------------------------
# 1. place.mp3: 120ms Plop (tactile popping drop onto grid)
# -----------------------------------------------------------------------------
def gen_place():
    duration = 0.120
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    phase = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        progress = t / duration
        # Fast pitch drop from 520Hz down to 140Hz
        freq = 140.0 + 380.0 * math.exp(-progress * 18.0)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        
        # Soft sine with light 2nd harmonic
        sig = 0.85 * math.sin(phase) + 0.15 * math.sin(phase * 2.0)
        
        # Envelope: 2ms linear attack, exponential decay
        if t < 0.002:
            env = t / 0.002
        else:
            env = math.exp(-(t - 0.002) * 28.0)
            
        samples.append(sig * env * 0.9)
    return samples

# -----------------------------------------------------------------------------
# 2. collect.mp3: 200ms Sparkle (bright crystalline chime sequence)
# -----------------------------------------------------------------------------
def gen_collect():
    duration = 0.200
    num_samples = int(duration * SAMPLE_RATE)
    samples = [0.0] * num_samples
    
    # 4 bell frequencies: C6, E6, G6, C7
    notes = [1046.5, 1318.5, 1568.0, 2093.0]
    note_times = [0.0, 0.035, 0.070, 0.105]
    
    for note_freq, start_t in zip(notes, note_times):
        start_idx = int(start_t * SAMPLE_RATE)
        phase = 0.0
        for i in range(start_idx, num_samples):
            t = (i - start_idx) / SAMPLE_RATE
            phase += 2.0 * math.pi * note_freq / SAMPLE_RATE
            
            # Glass bell FM synthesis (carrier + mod harmonic)
            mod = 0.3 * math.sin(2.0 * math.pi * (note_freq * 2.76) * t) * math.exp(-t * 30.0)
            sig = math.sin(phase + mod)
            
            # Envelope
            attack = min(1.0, t / 0.003)
            decay = math.exp(-t * 22.0)
            env = attack * decay
            
            samples[i] += sig * env * 0.28
            
    return samples

# -----------------------------------------------------------------------------
# 3. shoot.mp3: 150ms Zap (laser beam emission)
# -----------------------------------------------------------------------------
def gen_shoot():
    duration = 0.150
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    phase = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        progress = t / duration
        # Exponential chirp: 2400Hz -> 280Hz
        freq = 280.0 + 2120.0 * math.exp(-progress * 14.0)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        
        # Mix of sine + triangle
        norm_phase = (phase / (2.0 * math.pi)) % 1.0
        tri = 2.0 * abs(2.0 * norm_phase - 1.0) - 1.0
        sig = 0.65 * math.sin(phase) + 0.35 * tri
        
        # Attack 1ms, decay envelope
        if t < 0.001:
            env = t / 0.001
        else:
            env = math.exp(-(t - 0.001) * 16.0)
            
        samples.append(sig * env * 0.85)
    return samples

# -----------------------------------------------------------------------------
# 4. hit.mp3: 100ms Thud (punchy beam-on-shadow impact)
# -----------------------------------------------------------------------------
def gen_hit():
    duration = 0.100
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    phase = 0.0
    rng = random.Random(42)
    
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        progress = t / duration
        # Pitch: 220Hz -> 50Hz
        freq = 50.0 + 170.0 * math.exp(-progress * 30.0)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        
        # Low tone + noise transient
        tone = math.sin(phase)
        noise = (rng.random() * 2.0 - 1.0) * math.exp(-t * 80.0)
        sig = 0.75 * tone + 0.25 * noise
        
        env = math.exp(-t * 26.0)
        # Soft saturation
        val = math.tanh(sig * env * 1.5) * 0.85
        samples.append(val)
    return samples

# -----------------------------------------------------------------------------
# 5. explosion.mp3: 400ms Boom (flash bomb blast + deep sub rumble)
# -----------------------------------------------------------------------------
def gen_explosion():
    duration = 0.400
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    phase = 0.0
    rng = random.Random(1337)
    noise_filter = 0.0
    
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        progress = t / duration
        
        # Sub-bass: 100Hz -> 30Hz
        freq = 30.0 + 70.0 * math.exp(-progress * 8.0)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        sub = math.sin(phase)
        
        # Filtered noise burst
        raw_noise = rng.random() * 2.0 - 1.0
        # Dynamic low-pass coefficient dropping over time
        alpha = max(0.02, 0.45 * math.exp(-progress * 6.0))
        noise_filter += alpha * (raw_noise - noise_filter)
        
        # Envelope
        if t < 0.002:
            env = t / 0.002
        else:
            env = math.exp(-(t - 0.002) * 7.5)
            
        sig = 0.55 * sub + 0.45 * noise_filter
        val = math.tanh(sig * env * 1.8) * 0.9
        samples.append(val)
    return samples

# -----------------------------------------------------------------------------
# 6. win.mp3: 800ms Chime (glorious level-complete fanfare chimes)
# -----------------------------------------------------------------------------
def gen_win():
    duration = 0.800
    num_samples = int(duration * SAMPLE_RATE)
    samples = [0.0] * num_samples
    
    # 3-chord fanfare: C5, E5, G5, C6, E6
    events = [
        # (time, [frequencies], volume)
        (0.00, [523.25, 659.25], 0.35),
        (0.14, [659.25, 783.99], 0.40),
        (0.28, [783.99, 1046.50, 1318.51], 0.50),
    ]
    
    for start_t, chord, vol in events:
        start_idx = int(start_t * SAMPLE_RATE)
        for freq in chord:
            phase = 0.0
            for i in range(start_idx, num_samples):
                t = (i - start_idx) / SAMPLE_RATE
                phase += 2.0 * math.pi * freq / SAMPLE_RATE
                # Warm bell tone with gentle harmonic
                tone = 0.8 * math.sin(phase) + 0.2 * math.sin(phase * 2.0)
                
                attack = min(1.0, t / 0.005)
                decay = math.exp(-t * 4.5)
                samples[i] += tone * attack * decay * (vol / len(chord))
                
    # Normalize
    max_val = max(abs(s) for s in samples) or 1.0
    return [s / max_val * 0.88 for s in samples]

# -----------------------------------------------------------------------------
# 7. lose.mp3: 600ms Buzz (descending power-down defeat buzzer)
# -----------------------------------------------------------------------------
def gen_lose():
    duration = 0.600
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    phase1 = 0.0
    phase2 = 0.0
    
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        progress = t / duration
        
        # Dissonant tritone sliding down: A3 (220Hz) & Eb4 (311Hz) -> A2 (110Hz) & Eb3 (155Hz)
        f1 = 110.0 + 110.0 * (1.0 - progress)**1.5
        f2 = 155.0 + 156.0 * (1.0 - progress)**1.5
        
        # Tremolo flutter
        tremolo = 0.8 + 0.2 * math.sin(2.0 * math.pi * 9.0 * t)
        
        phase1 += 2.0 * math.pi * f1 / SAMPLE_RATE
        phase2 += 2.0 * math.pi * f2 / SAMPLE_RATE
        
        # Filtered sawtooth waves
        s1 = 0.5 * math.sin(phase1) + 0.3 * math.sin(phase1 * 2) + 0.2 * math.sin(phase1 * 3)
        s2 = 0.5 * math.sin(phase2) + 0.3 * math.sin(phase2 * 2) + 0.2 * math.sin(phase2 * 3)
        
        env = math.exp(-progress * 4.0) * tremolo
        sig = (s1 + s2) * 0.5 * env
        samples.append(sig * 0.82)
    return samples

# -----------------------------------------------------------------------------
# 8. sweep.mp3: 500ms Whoosh (dynamic lawnmower light-beam sweep)
# -----------------------------------------------------------------------------
def gen_sweep():
    duration = 0.500
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    rng = random.Random(999)
    phase = 0.0
    lpf1 = 0.0
    lpf2 = 0.0
    
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        progress = t / duration
        
        # Resonance frequency sweeps up then down
        center_freq = 300.0 + 2200.0 * math.sin(progress * math.pi)
        phase += 2.0 * math.pi * center_freq / SAMPLE_RATE
        tone = math.sin(phase) * 0.35
        
        # Two-pole low pass filter on noise
        raw = rng.random() * 2.0 - 1.0
        fc = min(0.9, (center_freq * 2.2) / SAMPLE_RATE)
        lpf1 += fc * (raw - lpf1)
        lpf2 += fc * (lpf1 - lpf2)
        
        # Volume curve: swell and fade
        env = math.sin(progress * math.pi) ** 1.3
        sig = (tone + lpf2 * 0.65) * env
        samples.append(clamp(sig * 1.1) * 0.88)
    return samples

# -----------------------------------------------------------------------------
# 9. bgm.mp3: 16.0s Seamless Loopable Dark-Lab Ambient Theme
# -----------------------------------------------------------------------------
def gen_bgm():
    duration = 16.0  # 16 seconds loop at ~90 BPM (24 beats total)
    num_samples = int(duration * SAMPLE_RATE)
    samples = [0.0] * num_samples
    
    # Chord progression in C minor / Dorian:
    # 0s - 4s: Cmin9 (C3=130.81, Eb3=155.56, G3=196.00, Bb3=233.08, D4=293.66)
    # 4s - 8s: Abmaj7 (Ab2=103.83, C3=130.81, Eb3=155.56, G3=196.00)
    # 8s - 12s: Bbadd9 (Bb2=116.54, D3=146.83, F3=174.61, C4=261.63)
    # 12s - 16s: Gmin7 (G2=98.00, Bb2=116.54, D3=146.83, F3=174.61)
    
    chords = [
        (0.0, 4.0, [130.81, 155.56, 196.00, 233.08, 293.66]),
        (4.0, 8.0, [103.83, 130.81, 155.56, 196.00]),
        (8.0, 12.0, [116.54, 146.83, 174.61, 261.63]),
        (12.0, 16.0, [98.00, 116.54, 146.83, 174.61]),
    ]
    
    # 1. Warm Ambient Pad Swells
    for t_start, t_end, freqs in chords:
        chord_dur = t_end - t_start
        i_start = int(t_start * SAMPLE_RATE)
        i_end = int(t_end * SAMPLE_RATE)
        for freq in freqs:
            phase = 0.0
            for i in range(num_samples):
                t = i / SAMPLE_RATE
                phase += 2.0 * math.pi * freq / SAMPLE_RATE
                
                # Soft sine pad with light vibrato
                vib = 1.0 + 0.003 * math.sin(2.0 * math.pi * 3.5 * t)
                sig = math.sin(phase * vib)
                
                # Chord window envelope with smooth crossfade
                if t_start <= t < t_end:
                    local_t = t - t_start
                    env = math.sin(local_t / chord_dur * math.pi)
                    samples[i] += sig * env * 0.06
                    
    # 2. Sub-bass pulse on C2 (65.41Hz)
    bass_phase = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Gentle breathing pulse every 2 seconds
        pulse = 0.5 + 0.5 * math.cos(2.0 * math.pi * 0.5 * t)
        bass_freq = 65.41
        if 4.0 <= t < 8.0:
            bass_freq = 51.91 # Ab1
        elif 8.0 <= t < 12.0:
            bass_freq = 58.27 # Bb1
        elif 12.0 <= t < 16.0:
            bass_freq = 49.00 # G1
            
        bass_phase += 2.0 * math.pi * bass_freq / SAMPLE_RATE
        sub = math.sin(bass_phase) + 0.25 * math.sin(bass_phase * 2.0)
        samples[i] += sub * (0.16 * pulse)
        
    # 3. Soft Arpeggiated Neon Crystal Chimes (16th notes = 0.166s at 90 BPM)
    arp_notes = [523.25, 659.25, 783.99, 1046.50, 783.99, 659.25, 587.33, 783.99]
    step_dur = 0.25  # 8th notes
    num_steps = int(duration / step_dur)
    
    for s in range(num_steps):
        step_t = s * step_dur
        freq = arp_notes[s % len(arp_notes)]
        step_idx = int(step_t * SAMPLE_RATE)
        phase = 0.0
        # Decay over 0.4s (rings into next step)
        ring_samples = int(0.4 * SAMPLE_RATE)
        for offset in range(ring_samples):
            idx = (step_idx + offset) % num_samples
            t_ring = offset / SAMPLE_RATE
            phase += 2.0 * math.pi * freq / SAMPLE_RATE
            
            sig = math.sin(phase) + 0.2 * math.sin(phase * 2.76)
            env = math.exp(-t_ring * 9.0)
            samples[idx] += sig * env * 0.05
            
    # Normalize track to peak at -1.5 dB (~0.84)
    max_val = max(abs(s) for s in samples) or 1.0
    scale = 0.84 / max_val
    return [s * scale for s in samples]

# -----------------------------------------------------------------------------
# Main driver
# -----------------------------------------------------------------------------
def main():
    target_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
    os.makedirs(target_dir, exist_ok=True)
    
    generators = {
        "place.mp3": gen_place,
        "collect.mp3": gen_collect,
        "shoot.mp3": gen_shoot,
        "hit.mp3": gen_hit,
        "explosion.mp3": gen_explosion,
        "win.mp3": gen_win,
        "lose.mp3": gen_lose,
        "sweep.mp3": gen_sweep,
        "bgm.mp3": gen_bgm,
    }
    
    print(f"Generating {len(generators)} audio files into {target_dir}...")
    
    for filename, gen_fn in generators.items():
        wav_path = os.path.join(target_dir, filename.replace(".mp3", ".wav"))
        mp3_path = os.path.join(target_dir, filename)
        
        samples = gen_fn()
        write_wav(wav_path, samples)
        # Encode with libmp3lame (SFX at 128k, BGM at 160k)
        bitrate = "160k" if filename == "bgm.mp3" else "128k"
        encode_mp3(wav_path, mp3_path, bitrate)
        
        size = os.path.getsize(mp3_path)
        print(f"  [OK] {filename:<14} ({size:,} bytes)")
        
    print("\nAll audio files generated successfully!")

if __name__ == "__main__":
    main()
