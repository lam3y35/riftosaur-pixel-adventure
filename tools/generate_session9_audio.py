import os
import math
import struct
import random

SAMPLE_RATE = 44100

def write_wav(filename, samples):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    # samples are floats between -1.0 and 1.0
    # Peak normalize to -6 dBFS (amplitude ~0.501)
    max_amp = max(abs(s) for s in samples) if samples else 1.0
    if max_amp > 0:
        scale = 0.501 / max_amp
    else:
        scale = 1.0

    int_samples = [int(max(-1.0, min(1.0, s * scale)) * 32767) for s in samples]

    data = bytearray()
    for s in int_samples:
        data.extend(struct.pack("<h", s))

    num_channels = 1
    bits_per_sample = 16
    byte_rate = SAMPLE_RATE * num_channels * bits_per_sample // 8
    block_align = num_channels * bits_per_sample // 8
    data_size = len(data)

    header = bytearray()
    header.extend(b"RIFF")
    header.extend(struct.pack("<I", 36 + data_size))
    header.extend(b"WAVE")
    header.extend(b"fmt ")
    header.extend(struct.pack("<I", 16)) # Subchunk1Size (16 for PCM)
    header.extend(struct.pack("<H", 1))  # AudioFormat (1 for PCM)
    header.extend(struct.pack("<H", num_channels))
    header.extend(struct.pack("<I", SAMPLE_RATE))
    header.extend(struct.pack("<I", byte_rate))
    header.extend(struct.pack("<H", block_align))
    header.extend(struct.pack("<H", bits_per_sample))
    header.extend(b"data")
    header.extend(struct.pack("<I", data_size))

    with open(filename, "wb") as f:
        f.write(header)
        f.write(data)
    print(f"Generated {filename} ({len(samples)/SAMPLE_RATE:.2f}s)")

def make_jump():
    dur = 0.18
    num_samples = int(SAMPLE_RATE * dur)
    samples = []
    phase = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = (1.0 - t / dur) ** 0.8
        freq = 180.0 + (520.0 - 180.0) * (t / dur) ** 0.7
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        # Square wave with soft harmonics
        sample = 0.8 * math.sin(phase) + 0.3 * math.sin(2 * phase)
        samples.append(sample * env)
    return samples

def make_land():
    dur = 0.12
    num_samples = int(SAMPLE_RATE * dur)
    samples = []
    phase = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-25.0 * t)
        freq = 90.0 * (1.0 - t / dur)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        noise = (random.random() * 2.0 - 1.0) * 0.4
        samples.append((math.sin(phase) + noise) * env)
    return samples

def make_slide():
    dur = 0.22
    num_samples = int(SAMPLE_RATE * dur)
    samples = []
    last = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (t / dur))
        # Low-pass noise for friction hiss
        raw = random.random() * 2.0 - 1.0
        last = 0.85 * last + 0.15 * raw
        samples.append(last * env)
    return samples

def make_air_dash():
    dur = 0.18
    num_samples = int(SAMPLE_RATE * dur)
    samples = []
    phase = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = (1.0 - t / dur)
        freq = 600.0 - 400.0 * (t / dur)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        noise = (random.random() * 2.0 - 1.0) * 0.5
        samples.append((math.sin(phase) * 0.6 + noise) * env)
    return samples

def make_collect():
    dur = 0.20
    num_samples = int(SAMPLE_RATE * dur)
    samples = []
    p1 = 0.0
    p2 = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = (1.0 - t / dur) ** 1.2
        # Two tone bell: 987Hz (B5) and 1318Hz (E6)
        freq = 987.0 if t < 0.08 else 1318.0
        p1 += 2.0 * math.pi * freq / SAMPLE_RATE
        p2 += 2.0 * math.pi * (freq * 2.0) / SAMPLE_RATE
        sample = math.sin(p1) + 0.3 * math.sin(p2)
        samples.append(sample * env)
    return samples

def make_skill_activation():
    dur = 0.32
    num_samples = int(SAMPLE_RATE * dur)
    samples = []
    phase = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (t / dur)) * 1.1
        freq = 240.0 + 600.0 * (t / dur) ** 1.5
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        sample = math.sin(phase) + 0.4 * math.sin(phase * 1.5)
        samples.append(sample * env)
    return samples

def make_obstacle_break():
    dur = 0.25
    num_samples = int(SAMPLE_RATE * dur)
    samples = []
    last = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = (1.0 - t / dur) ** 2.0
        raw = random.random() * 2.0 - 1.0
        # High impact crunch
        last = 0.5 * last + 0.5 * raw
        samples.append(last * env)
    return samples

def make_world_enter():
    dur = 0.45
    num_samples = int(SAMPLE_RATE * dur)
    samples = []
    p = 0.0
    chord = [330.0, 440.0, 554.0, 660.0] # E major arpeggio
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        note_idx = min(int((t / dur) * 4), 3)
        freq = chord[note_idx]
        env = 0.8 + 0.2 * math.cos(math.pi * 2 * t * 4)
        decay = (1.0 - t / dur)
        p += 2.0 * math.pi * freq / SAMPLE_RATE
        samples.append(math.sin(p) * env * decay)
    return samples

def make_flight_start():
    dur = 0.35
    num_samples = int(SAMPLE_RATE * dur)
    samples = []
    p = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (t / dur))
        freq = 200.0 + 500.0 * (t / dur)
        p += 2.0 * math.pi * freq / SAMPLE_RATE
        shimmer = math.sin(2.0 * math.pi * 12.0 * t) * 0.2
        samples.append((math.sin(p) + shimmer) * env)
    return samples

def make_flight_end():
    dur = 0.28
    num_samples = int(SAMPLE_RATE * dur)
    samples = []
    p = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = (1.0 - t / dur)
        freq = 550.0 - 320.0 * (t / dur)
        p += 2.0 * math.pi * freq / SAMPLE_RATE
        samples.append(math.sin(p) * env)
    return samples

def make_damage():
    dur = 0.25
    num_samples = int(SAMPLE_RATE * dur)
    samples = []
    p = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = (1.0 - t / dur) ** 1.5
        freq = 240.0 - 140.0 * (t / dur)
        p += 2.0 * math.pi * freq / SAMPLE_RATE
        noise = (random.random() * 2.0 - 1.0) * 0.7
        samples.append((math.sin(p) * 0.5 + noise) * env)
    return samples

def make_game_over():
    dur = 0.55
    num_samples = int(SAMPLE_RATE * dur)
    samples = []
    p = 0.0
    notes = [440.0, 415.3, 392.0, 349.2] # Sad chromatic descent
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        note_idx = min(int((t / dur) * 4), 3)
        freq = notes[note_idx]
        p += 2.0 * math.pi * freq / SAMPLE_RATE
        note_t = (t % (dur / 4.0)) / (dur / 4.0)
        env = (1.0 - note_t) * (1.0 - t / dur * 0.4)
        samples.append(math.sin(p) * env)
    return samples

def main():
    out_dir = "assets/audio"
    write_wav(f"{out_dir}/sfx_jump.wav", make_jump())
    write_wav(f"{out_dir}/sfx_land.wav", make_land())
    write_wav(f"{out_dir}/sfx_slide.wav", make_slide())
    write_wav(f"{out_dir}/sfx_air_dash.wav", make_air_dash())
    write_wav(f"{out_dir}/sfx_collect.wav", make_collect())
    write_wav(f"{out_dir}/sfx_skill_activation.wav", make_skill_activation())
    write_wav(f"{out_dir}/sfx_obstacle_break.wav", make_obstacle_break())
    write_wav(f"{out_dir}/sfx_world_enter.wav", make_world_enter())
    write_wav(f"{out_dir}/sfx_flight_start.wav", make_flight_start())
    write_wav(f"{out_dir}/sfx_flight_end.wav", make_flight_end())
    write_wav(f"{out_dir}/sfx_damage.wav", make_damage())
    write_wav(f"{out_dir}/sfx_game_over.wav", make_game_over())

if __name__ == "__main__":
    main()
