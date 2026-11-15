import os
import math
import struct
import random

SAMPLE_RATE = 44100
MUSIC_SAMPLE_RATE = 44100


def _apply_edge_fades(samples: list[float], sample_rate: int, fade_in_ms: float = 4.0, fade_out_ms: float = 8.0) -> list[float]:
    n = len(samples)
    if n < 4:
        return samples
    out = list(samples)
    n_in = min(n // 2, max(2, int(sample_rate * fade_in_ms / 1000.0)))
    n_out = min(n // 2, max(2, int(sample_rate * fade_out_ms / 1000.0)))
    for i in range(n_in):
        w = 0.5 * (1.0 - math.cos(math.pi * i / n_in))
        out[i] *= w
    for i in range(n_out):
        w = 0.5 * (1.0 - math.cos(math.pi * i / n_out))
        out[n - 1 - i] *= w
    return out


def write_wav_stereo(filename: str, left: list[float], right: list[float], sample_rate: int = SAMPLE_RATE, peak_norm: float = 0.65) -> None:
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    left = _apply_edge_fades(left, sample_rate)
    right = _apply_edge_fades(right, sample_rate)
    max_amp = max(max((abs(s) for s in left), default=1.0), max((abs(s) for s in right), default=1.0))
    scale = (peak_norm / max_amp) if max_amp > 1e-6 else 1.0

    pcm = bytearray()
    for l_val, r_val in zip(left, right):
        cl = max(-1.0, min(1.0, l_val * scale))
        cr = max(-1.0, min(1.0, r_val * scale))
        pcm.extend(struct.pack("<hh", int(cl * 32767), int(cr * 32767)))

    num_channels = 2
    bits_per_sample = 16
    byte_rate = sample_rate * num_channels * bits_per_sample // 8
    block_align = num_channels * bits_per_sample // 8
    data_size = len(pcm)

    header = bytearray()
    header.extend(b"RIFF")
    header.extend(struct.pack("<I", 36 + data_size))
    header.extend(b"WAVE")
    header.extend(b"fmt ")
    header.extend(struct.pack("<I", 16))
    header.extend(struct.pack("<H", 1))
    header.extend(struct.pack("<H", num_channels))
    header.extend(struct.pack("<I", sample_rate))
    header.extend(struct.pack("<I", byte_rate))
    header.extend(struct.pack("<H", block_align))
    header.extend(struct.pack("<H", bits_per_sample))
    header.extend(b"data")
    header.extend(struct.pack("<I", data_size))

    with open(filename, "wb") as f:
        f.write(header)
        f.write(pcm)
    print(f"Generated STEREO {filename} ({len(left) / sample_rate:.2f}s @ {sample_rate}Hz)")


def write_wav(filename: str, samples: list[float], sample_rate: int = SAMPLE_RATE, peak_norm: float = 0.65) -> None:
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    samples = _apply_edge_fades(samples, sample_rate)
    max_amp = max((abs(s) for s in samples), default=1.0)
    scale = (peak_norm / max_amp) if max_amp > 1e-6 else 1.0

    pcm = bytearray()
    for s in samples:
        clamped = max(-1.0, min(1.0, s * scale))
        pcm.extend(struct.pack("<h", int(clamped * 32767)))

    num_channels = 1
    bits_per_sample = 16
    byte_rate = sample_rate * num_channels * bits_per_sample // 8
    block_align = num_channels * bits_per_sample // 8
    data_size = len(pcm)

    header = bytearray()
    header.extend(b"RIFF")
    header.extend(struct.pack("<I", 36 + data_size))
    header.extend(b"WAVE")
    header.extend(b"fmt ")
    header.extend(struct.pack("<I", 16))
    header.extend(struct.pack("<H", 1))
    header.extend(struct.pack("<H", num_channels))
    header.extend(struct.pack("<I", sample_rate))
    header.extend(struct.pack("<I", byte_rate))
    header.extend(struct.pack("<H", block_align))
    header.extend(struct.pack("<H", bits_per_sample))
    header.extend(b"data")
    header.extend(struct.pack("<I", data_size))

    with open(filename, "wb") as f:
        f.write(header)
        f.write(pcm)
    print(f"Generated {filename} ({len(samples) / sample_rate:.2f}s @ {sample_rate}Hz)")


def soft_square(phase: float, duty: float = 0.5) -> float:
    frac = (phase / (2.0 * math.pi)) % 1.0
    val = 1.0 if frac < duty else -1.0
    return 0.7 * val + 0.3 * math.sin(phase)


def triangle(phase: float) -> float:
    frac = (phase / (2.0 * math.pi)) % 1.0
    return 4.0 * abs(frac - 0.5) - 1.0


def saw(phase: float) -> float:
    frac = (phase / (2.0 * math.pi)) % 1.0
    return 2.0 * frac - 1.0


def midi_to_hz(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def make_jump() -> list[float]:
    dur = 0.19
    n = int(SAMPLE_RATE * dur)
    out = []
    ph1 = 0.0
    ph2 = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        p = t / dur
        env = math.exp(-6.0 * p) * min(1.0, t / 0.006)
        f1 = 190.0 + 460.0 * (p ** 0.55)
        f2 = 95.0 + 180.0 * (p ** 0.5)
        ph1 += 2.0 * math.pi * f1 / SAMPLE_RATE
        ph2 += 2.0 * math.pi * f2 / SAMPLE_RATE
        noise = (random.random() * 2.0 - 1.0) * 0.18 * math.exp(-16.0 * p)
        s = 0.65 * soft_square(ph1, 0.35) + 0.45 * math.sin(ph2) + noise
        out.append(s * env)
    return out


def make_land() -> list[float]:
    dur = 0.13
    n = int(SAMPLE_RATE * dur)
    out = []
    ph = 0.0
    last_n = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        p = t / dur
        env = math.exp(-18.0 * t)
        freq = 115.0 * (1.0 - 0.65 * p)
        ph += 2.0 * math.pi * freq / SAMPLE_RATE
        raw_n = random.random() * 2.0 - 1.0
        last_n = 0.65 * last_n + 0.35 * raw_n
        out.append((0.8 * math.sin(ph) + 0.45 * last_n) * env)
    return out


def make_slide() -> list[float]:
    dur = 0.24
    n = int(SAMPLE_RATE * dur)
    out = []
    lp = 0.0
    hp_prev = 0.0
    ph = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        p = t / dur
        env = math.sin(math.pi * (p ** 0.7)) * (1.0 - 0.35 * p)
        raw = random.random() * 2.0 - 1.0
        lp = 0.78 * lp + 0.22 * raw
        bp = lp - 0.5 * hp_prev
        hp_prev = lp
        freq = 280.0 - 140.0 * p
        ph += 2.0 * math.pi * freq / SAMPLE_RATE
        out.append((0.75 * bp + 0.25 * math.sin(ph)) * env)
    return out


def make_air_dash() -> list[float]:
    dur = 0.22
    n = int(SAMPLE_RATE * dur)
    out = []
    ph1 = 0.0
    ph2 = 0.0
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        p = t / dur
        env = math.exp(-5.0 * p) * min(1.0, t / 0.008)
        f1 = 880.0 - 540.0 * (p ** 0.6)
        f2 = 440.0 + 360.0 * p
        ph1 += 2.0 * math.pi * f1 / SAMPLE_RATE
        ph2 += 2.0 * math.pi * f2 / SAMPLE_RATE
        raw = random.random() * 2.0 - 1.0
        lp = 0.7 * lp + 0.3 * raw
        out.append((0.5 * saw(ph1) + 0.35 * soft_square(ph2) + 0.45 * lp) * env)
    return out


def make_collect() -> list[float]:
    dur = 0.20
    n = int(SAMPLE_RATE * dur)
    out = []
    ph1 = 0.0
    ph2 = 0.0
    notes = [987.77, 1318.51, 1567.98]
    for i in range(n):
        t = i / SAMPLE_RATE
        p = t / dur
        seg = min(int(p * 3.0), 2)
        f = notes[seg]
        ph1 += 2.0 * math.pi * f / SAMPLE_RATE
        ph2 += 2.0 * math.pi * (f * 2.0) / SAMPLE_RATE
        seg_p = (p * 3.0) % 1.0
        env = math.exp(-4.5 * seg_p) * (1.0 - p * 0.4)
        out.append((0.75 * math.sin(ph1) + 0.25 * triangle(ph2)) * env)
    return out


def make_pickup() -> list[float]:
    dur = 0.32
    n = int(SAMPLE_RATE * dur)
    out = []
    ph = 0.0
    notes = [523.25, 659.25, 783.99, 1046.5]
    for i in range(n):
        t = i / SAMPLE_RATE
        p = t / dur
        idx = min(int(p * len(notes)), len(notes) - 1)
        f = notes[idx]
        ph += 2.0 * math.pi * f / SAMPLE_RATE
        env = (1.0 - p * 0.6) * min(1.0, t / 0.008)
        out.append((0.65 * soft_square(ph, 0.25) + 0.4 * math.sin(ph * 1.5)) * env)
    return out


def make_skill_activation() -> list[float]:
    dur = 0.30
    n = int(SAMPLE_RATE * dur)
    out = []
    ph1 = 0.0
    ph2 = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        p = t / dur
        env = math.exp(-4.2 * p) * min(1.0, t / 0.006)
        f1 = 260.0 + 780.0 * (p ** 0.7)
        f2 = 520.0 + 390.0 * p
        ph1 += 2.0 * math.pi * f1 / SAMPLE_RATE
        ph2 += 2.0 * math.pi * f2 / SAMPLE_RATE
        out.append((0.6 * soft_square(ph1, 0.3) + 0.4 * saw(ph2)) * env)
    return out


def make_obstacle_break() -> list[float]:
    dur = 0.28
    n = int(SAMPLE_RATE * dur)
    out = []
    ph = 0.0
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        p = t / dur
        env = math.exp(-11.0 * t)
        f = 160.0 * math.exp(-5.0 * t) + 45.0
        ph += 2.0 * math.pi * f / SAMPLE_RATE
        crackle = (random.random() * 2.0 - 1.0)
        lp = 0.5 * lp + 0.5 * crackle
        burst = 1.3 if (0.04 < t < 0.07) else 1.0
        out.append((0.7 * math.sin(ph) + 0.75 * lp * burst) * env)
    return out


def make_world_enter() -> list[float]:
    dur = 0.68
    n = int(SAMPLE_RATE * dur)
    out = []
    ph1 = 0.0
    ph2 = 0.0
    ph3 = 0.0
    chord = [261.63, 329.63, 392.00, 523.25]
    for i in range(n):
        t = i / SAMPLE_RATE
        p = t / dur
        env = math.sin(min(p * 2.2, 1.0) * math.pi * 0.5) * math.exp(-2.8 * max(0.0, p - 0.15))
        step = min(int(p * 4.0), 3)
        f1 = chord[step]
        f2 = f1 * 1.5
        f3 = 180.0 + 620.0 * (p ** 0.9)
        ph1 += 2.0 * math.pi * f1 / SAMPLE_RATE
        ph2 += 2.0 * math.pi * f2 / SAMPLE_RATE
        ph3 += 2.0 * math.pi * f3 / SAMPLE_RATE
        out.append((0.5 * soft_square(ph1, 0.4) + 0.3 * math.sin(ph2) + 0.25 * math.sin(ph3)) * env)
    return out


def make_flight_start() -> list[float]:
    dur = 0.36
    n = int(SAMPLE_RATE * dur)
    out = []
    ph = 0.0
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        p = t / dur
        env = math.sin(min(p * 3.0, 1.0) * math.pi * 0.5) * (1.0 - 0.5 * p)
        f = 150.0 + 600.0 * (p ** 1.1)
        ph += 2.0 * math.pi * f / SAMPLE_RATE
        lp = 0.8 * lp + 0.2 * (random.random() * 2.0 - 1.0)
        out.append((0.55 * saw(ph) + 0.45 * lp) * env)
    return out


def make_flight_end() -> list[float]:
    dur = 0.30
    n = int(SAMPLE_RATE * dur)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        p = t / dur
        env = (1.0 - p) ** 1.1
        f = 420.0 - 270.0 * (p ** 0.8)
        ph += 2.0 * math.pi * f / SAMPLE_RATE
        out.append(0.75 * triangle(ph) * env)
    return out


def make_damage() -> list[float]:
    dur = 0.22
    n = int(SAMPLE_RATE * dur)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        p = t / dur
        env = math.exp(-12.0 * t)
        f = 140.0 * math.exp(-8.0 * t) + 48.0
        ph += 2.0 * math.pi * f / SAMPLE_RATE
        crunch = (random.random() * 2.0 - 1.0) * 0.65
        out.append((0.8 * soft_square(ph, 0.5) + crunch) * env)
    return out


def make_game_over() -> list[float]:
    dur = 0.64
    n = int(SAMPLE_RATE * dur)
    out = []
    notes = [392.00, 349.23, 311.13, 261.63]
    ph = 0.0
    ph_sub = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        p = t / dur
        idx = min(int(p * len(notes)), len(notes) - 1)
        f = notes[idx] * (1.0 - 0.08 * ((p * len(notes)) % 1.0))
        ph += 2.0 * math.pi * f / SAMPLE_RATE
        ph_sub += 2.0 * math.pi * (f * 0.5) / SAMPLE_RATE
        env = (1.0 - 0.75 * p) * min(1.0, t / 0.015)
        out.append((0.55 * saw(ph) + 0.45 * math.sin(ph_sub)) * env)
    return out


def make_ui_click() -> list[float]:
    dur = 0.065
    n = int(SAMPLE_RATE * dur)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        p = t / dur
        f = 680.0 + 360.0 * p
        ph += 2.0 * math.pi * f / SAMPLE_RATE
        env = math.exp(-26.0 * t)
        out.append(0.8 * math.sin(ph) * env)
    return out


def make_bounce() -> list[float]:
    dur = 0.24
    n = int(SAMPLE_RATE * dur)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        p = t / dur
        wobble = math.sin(t * 75.0) * 40.0 * (1.0 - p)
        f = 220.0 + 520.0 * (p ** 0.6) + wobble
        ph += 2.0 * math.pi * f / SAMPLE_RATE
        env = math.exp(-7.0 * p) * min(1.0, t / 0.006)
        out.append((0.7 * triangle(ph) + 0.35 * math.sin(ph * 2.0)) * env)
    return out


def make_combo() -> list[float]:
    dur = 0.24
    n = int(SAMPLE_RATE * dur)
    out = []
    ph = 0.0
    notes = [659.25, 880.0, 1174.66, 1318.51]
    for i in range(n):
        t = i / SAMPLE_RATE
        p = t / dur
        f = notes[min(int(p * 4.0), 3)]
        ph += 2.0 * math.pi * f / SAMPLE_RATE
        env = math.exp(-4.0 * p)
        out.append((0.65 * math.sin(ph) + 0.35 * soft_square(ph, 0.25)) * env)
    return out


def make_shield_break() -> list[float]:
    dur = 0.26
    n = int(SAMPLE_RATE * dur)
    out = []
    ph1 = 0.0
    ph2 = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        p = t / dur
        f1 = 1480.0 - 800.0 * p
        f2 = 2120.0 + 300.0 * math.sin(t * 90.0)
        ph1 += 2.0 * math.pi * f1 / SAMPLE_RATE
        ph2 += 2.0 * math.pi * f2 / SAMPLE_RATE
        noise = (random.random() * 2.0 - 1.0) * 0.45 * math.exp(-18.0 * t)
        env = math.exp(-10.0 * t)
        out.append((0.45 * math.sin(ph1) + 0.35 * math.sin(ph2) + noise) * env)
    return out


def make_boomerang() -> list[float]:
    dur = 0.28
    n = int(SAMPLE_RATE * dur)
    out = []
    lp = 0.0
    ph = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        p = t / dur
        pulse = 0.45 + 0.55 * abs(math.sin(t * 28.0))
        f = 340.0 + 180.0 * math.sin(t * 28.0)
        ph += 2.0 * math.pi * f / SAMPLE_RATE
        lp = 0.7 * lp + 0.3 * (random.random() * 2.0 - 1.0)
        env = math.sin(math.pi * p)
        out.append((0.55 * lp + 0.45 * math.sin(ph)) * pulse * env)
    return out


def make_slam() -> list[float]:
    dur = 0.38
    n = int(SAMPLE_RATE * dur)
    out = []
    ph = 0.0
    lp = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        p = t / dur
        f = 135.0 * math.exp(-7.5 * t) + 38.0
        ph += 2.0 * math.pi * f / SAMPLE_RATE
        lp = 0.65 * lp + 0.35 * (random.random() * 2.0 - 1.0)
        env = math.exp(-6.8 * t)
        out.append((0.85 * math.sin(ph) + 0.65 * lp) * env)
    return out


def make_new_best() -> list[float]:
    dur = 0.56
    n = int(SAMPLE_RATE * dur)
    out = []
    notes = [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98]
    ph = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        p = t / dur
        f = notes[min(int(p * len(notes)), len(notes) - 1)]
        ph += 2.0 * math.pi * f / SAMPLE_RATE
        env = min(1.0, t / 0.01) * (1.0 - 0.55 * max(0.0, p - 0.4))
        out.append((0.6 * soft_square(ph, 0.3) + 0.4 * math.sin(ph * 2.0)) * env)
    return out


def make_bgm_run() -> tuple[list[float], list[float]]:
    # 136 BPM, 16 bars (256 sixteenth-notes) -> rich ~28.24s 44.1kHz stereo loop with A + B sections
    bpm = 136.0
    step_dur = 60.0 / bpm / 4.0
    total_steps = 256
    total_samples = int(round(total_steps * step_dur * MUSIC_SAMPLE_RATE))
    buf_l = [0.0] * total_samples
    buf_r = [0.0] * total_samples

    # 16-bar progression: Section A (Dm -> Bb -> C -> Am) + Section B lift (F -> C -> Gm -> A)
    bar_roots = [
        38, 38, 34, 34, 36, 36, 33, 33,
        41, 41, 36, 36, 43, 43, 45, 45,
    ]
    lead_a = [
        62, 0, 65, 69, 0, 65, 67, 0, 69, 0, 72, 69, 65, 0, 64, 0,
        62, 0, 65, 69, 0, 74, 72, 0, 69, 67, 65, 0, 64, 65, 69, 0,
        58, 0, 62, 65, 0, 69, 67, 0, 65, 0, 69, 65, 62, 0, 60, 0,
        60, 0, 64, 67, 0, 72, 71, 0, 69, 0, 64, 67, 69, 0, 72, 0,
    ]
    lead_b = [
        65, 0, 69, 72, 0, 77, 76, 0, 72, 0, 69, 72, 74, 0, 72, 0,
        67, 0, 72, 76, 0, 79, 76, 0, 74, 72, 69, 0, 67, 69, 72, 0,
        67, 0, 70, 74, 0, 79, 77, 0, 74, 0, 70, 74, 76, 0, 74, 0,
        69, 0, 73, 76, 0, 81, 79, 0, 76, 73, 69, 0, 73, 76, 81, 0,
    ]
    arp_offsets = [0, 7, 12, 19, 12, 7, 12, 15]
    pad_triads = [
        [50, 53, 57], [50, 53, 57], [46, 50, 53], [46, 50, 53],
        [48, 52, 55], [48, 52, 55], [45, 48, 52], [45, 48, 52],
        [53, 57, 60], [53, 57, 60], [48, 52, 55], [48, 52, 55],
        [55, 58, 62], [55, 58, 62], [57, 61, 64], [57, 61, 64],
    ]

    rng = random.Random(42)
    step_samples = total_samples / total_steps
    ph_pad_l = [0.0, 0.0, 0.0]
    ph_pad_r = [0.0, 0.0, 0.0]

    for step in range(total_steps):
        s0 = int(round(step * step_samples))
        s1 = int(round((step + 1) * step_samples))
        bar = step // 16
        in_bar = step % 16
        root = bar_roots[bar]

        bass_note = root + (12 if in_bar % 4 == 2 else 0)
        bass_hz = midi_to_hz(bass_note)
        arp_hz = midi_to_hz(root + 24 + arp_offsets[in_bar % len(arp_offsets)])
        lead_src = lead_b if bar >= 8 else lead_a
        lead_note = lead_src[step % 64]
        if (bar % 8) >= 4 and lead_note > 0 and (step % 8 == 3):
            lead_note += 12
        lead_hz = midi_to_hz(lead_note) if lead_note > 0 else 0.0

        has_kick = (in_bar % 4 == 0) or (bar % 4 == 3 and in_bar == 14)
        has_snare = (in_bar == 4 or in_bar == 12)
        has_hat = (in_bar % 2 == 1)

        # Pan shimmer gently back and forth for wide stereo depth
        arp_pan = 0.35 + 0.30 * math.sin(step * 0.45)

        ph_b = 0.0
        ph_l1 = 0.0
        ph_l2 = 0.0
        ph_a = 0.0
        ph_k = 0.0
        seg_len = max(1, s1 - s0)

        for k in range(seg_len):
            idx = s0 + k
            if idx >= total_samples:
                break
            lt = k / MUSIC_SAMPLE_RATE
            lp = k / seg_len

            ph_b += 2.0 * math.pi * bass_hz / MUSIC_SAMPLE_RATE
            b_env = math.exp(-3.6 * lp) * min(1.0, lt / 0.004)
            bass_s = (0.52 * saw(ph_b) + 0.48 * math.sin(ph_b)) * b_env * 0.40

            ph_a += 2.0 * math.pi * arp_hz / MUSIC_SAMPLE_RATE
            a_env = math.exp(-4.8 * lp) * min(1.0, lt / 0.004)
            arp_s = triangle(ph_a) * a_env * 0.14

            lead_l = 0.0
            lead_r = 0.0
            if lead_hz > 0.0:
                # Subtle stereo detune chorus on lead melody
                ph_l1 += 2.0 * math.pi * (lead_hz * 0.9985) / MUSIC_SAMPLE_RATE
                ph_l2 += 2.0 * math.pi * (lead_hz * 1.0015) / MUSIC_SAMPLE_RATE
                l_env = (1.0 - 0.42 * lp) * min(1.0, lt / 0.006)
                lead_l = soft_square(ph_l1, 0.34) * l_env * 0.22
                lead_r = soft_square(ph_l2, 0.36) * l_env * 0.22

            pad_l = 0.0
            pad_r = 0.0
            for ci, n in enumerate(pad_triads[bar]):
                nhz = midi_to_hz(n)
                ph_pad_l[ci] += 2.0 * math.pi * (nhz * 0.999) / MUSIC_SAMPLE_RATE
                ph_pad_r[ci] += 2.0 * math.pi * (nhz * 1.001) / MUSIC_SAMPLE_RATE
                pad_l += math.sin(ph_pad_l[ci]) * 0.045
                pad_r += math.sin(ph_pad_r[ci]) * 0.045

            drum_l = 0.0
            drum_r = 0.0
            if has_kick:
                kf = 132.0 * math.exp(-18.0 * lt) + 46.0
                ph_k += 2.0 * math.pi * kf / MUSIC_SAMPLE_RATE
                kd = math.sin(ph_k) * math.exp(-14.0 * lt) * 0.42
                drum_l += kd
                drum_r += kd
            if has_snare:
                sn = (rng.random() * 2.0 - 1.0) * math.exp(-21.0 * lt)
                drum_l += sn * 0.25
                drum_r += sn * 0.23
            elif has_hat:
                hh = (rng.random() * 2.0 - 1.0) * math.exp(-52.0 * lt)
                drum_l += hh * 0.07
                drum_r += hh * 0.11

            buf_l[idx] += bass_s + arp_s * (1.0 - arp_pan) + lead_l + pad_l + drum_l
            buf_r[idx] += bass_s + arp_s * arp_pan + lead_r + pad_r + drum_r

    return buf_l, buf_r


def make_bgm_menu() -> tuple[list[float], list[float]]:
    # 108 BPM atmospheric prehistoric-cyber rift theme, 8 bars (~17.78s) 44.1kHz stereo loop
    bpm = 108.0
    step_dur = 60.0 / bpm / 4.0
    total_steps = 128
    total_samples = int(round(total_steps * step_dur * MUSIC_SAMPLE_RATE))
    buf_l = [0.0] * total_samples
    buf_r = [0.0] * total_samples

    bar_roots = [38, 38, 34, 36, 38, 41, 34, 36]
    arp_seq = [0, 7, 12, 15, 19, 15, 12, 7]
    pad_chords = [
        [50, 53, 57],
        [50, 53, 57],
        [46, 50, 53],
        [48, 52, 55],
        [50, 53, 57],
        [53, 57, 60],
        [46, 50, 53],
        [48, 52, 55],
    ]

    step_samples = total_samples / total_steps
    ph_pad_l = [0.0, 0.0, 0.0]
    ph_pad_r = [0.0, 0.0, 0.0]

    for step in range(total_steps):
        s0 = int(round(step * step_samples))
        s1 = int(round((step + 1) * step_samples))
        bar = step // 16
        in_bar = step % 16
        root = bar_roots[bar]
        arp_hz = midi_to_hz(root + 24 + arp_seq[in_bar % len(arp_seq)])
        bass_hz = midi_to_hz(root)
        play_bass = (in_bar % 4 == 0)
        arp_pan = 0.5 + 0.25 * math.cos(step * 0.32)

        ph_a = 0.0
        ph_b = 0.0
        seg_len = max(1, s1 - s0)
        for k in range(seg_len):
            idx = s0 + k
            if idx >= total_samples:
                break
            lt = k / MUSIC_SAMPLE_RATE
            lp = k / seg_len

            ph_a += 2.0 * math.pi * arp_hz / MUSIC_SAMPLE_RATE
            arp_s = triangle(ph_a) * math.exp(-3.4 * lp) * min(1.0, lt / 0.008) * 0.22

            bass_s = 0.0
            if play_bass:
                ph_b += 2.0 * math.pi * bass_hz / MUSIC_SAMPLE_RATE
                bass_s = math.sin(ph_b) * math.exp(-2.6 * lp) * min(1.0, lt / 0.01) * 0.28

            pad_l = 0.0
            pad_r = 0.0
            for ci, n in enumerate(pad_chords[bar]):
                nhz = midi_to_hz(n)
                ph_pad_l[ci] += 2.0 * math.pi * (nhz * 0.9988) / MUSIC_SAMPLE_RATE
                ph_pad_r[ci] += 2.0 * math.pi * (nhz * 1.0012) / MUSIC_SAMPLE_RATE
                pad_l += math.sin(ph_pad_l[ci]) * 0.075
                pad_r += math.sin(ph_pad_r[ci]) * 0.075

            buf_l[idx] += arp_s * (1.0 - arp_pan * 0.5) + bass_s + pad_l
            buf_r[idx] += arp_s * (0.5 + arp_pan * 0.5) + bass_s + pad_r

    return buf_l, buf_r


def main() -> None:
    random.seed(1337)
    out_dir = "assets/audio"
    sfx_map = {
        "sfx_jump.wav": make_jump(),
        "sfx_land.wav": make_land(),
        "sfx_slide.wav": make_slide(),
        "sfx_air_dash.wav": make_air_dash(),
        "sfx_collect.wav": make_collect(),
        "sfx_pickup.wav": make_pickup(),
        "sfx_skill_activation.wav": make_skill_activation(),
        "sfx_obstacle_break.wav": make_obstacle_break(),
        "sfx_world_enter.wav": make_world_enter(),
        "sfx_flight_start.wav": make_flight_start(),
        "sfx_flight_end.wav": make_flight_end(),
        "sfx_damage.wav": make_damage(),
        "sfx_game_over.wav": make_game_over(),
        "sfx_ui_click.wav": make_ui_click(),
        "sfx_bounce.wav": make_bounce(),
        "sfx_combo.wav": make_combo(),
        "sfx_shield_break.wav": make_shield_break(),
        "sfx_boomerang.wav": make_boomerang(),
        "sfx_slam.wav": make_slam(),
        "sfx_new_best.wav": make_new_best(),
    }
    for fname, samples in sfx_map.items():
        write_wav(os.path.join(out_dir, fname), samples, SAMPLE_RATE, peak_norm=0.72)

    run_l, run_r = make_bgm_run()
    write_wav_stereo(os.path.join(out_dir, "bgm_run.wav"), run_l, run_r, MUSIC_SAMPLE_RATE, peak_norm=0.45)
    menu_l, menu_r = make_bgm_menu()
    write_wav_stereo(os.path.join(out_dir, "bgm_menu.wav"), menu_l, menu_r, MUSIC_SAMPLE_RATE, peak_norm=0.38)
    print("Enhanced audio generation completed!")


if __name__ == "__main__":
    main()
