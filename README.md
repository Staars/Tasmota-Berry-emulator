# Tasmota-Berry-emulator

This project is part of the [Tasmota](https://github.com/arendst/Tasmota) project. Since end of 2023, Tasmota introduced an [animation framework](https://tasmota.github.io/docs/Berry_Addressable-LED/#animation-framework-module-animate) for Leds based on the embedded [Berry](https://tasmota.github.io/docs/Berry/) programming language. However iterating when building new animations requires numerous updates on the Tasmota devices and reboots.

This project is a minimal Tasmota/Berry emulator enabling to run and try animations on a laptop, without the need to iterate on an actual embedded device. The goal is to provide an animated image (animated GIF or else) to visualize the result and iterate.

## Installation

Requirements: Python 3.x, C standard compiler, [Emscripten](https://emscripten.org/) (for WASM build)

### Step 1. Clone the repository

```bash
git clone https://github.com/Staars/Tasmota-Berry-emulator.git
cd Tasmota-Berry-emulator
```

### Step 2. Compile Berry (native)

```bash
make
```

### Step 3. Compile Berry (WASM)

```bash
make web
```

### Step 4. Prepare the Python environment

```bash
python3 -m venv python_env
source python_env/bin/activate
python3 -m pip install "imageio"
```

## How to use

### WASM (browser)

```bash
emrun docs/berry.js
```

### Native (GIF export)

Copy your animation script in directory `demos/` and run the following:

```bash
./run_animate.be demos/<file>.be
python3 generate_gif.py output.jsonl
```

Example:

```bash
> ./run_animate.be demos/animate_demo_cylon.be
Animation exported to 'output.jsonl'
> python3 generate_gif.py output.jsonl -o cylon.gif
```

## Example

#### demo_pulse

<img src='/demo_gif/pulse.gif' height='20'>

Berry code:

```berry
import animate

var strip = Leds(5 * 5, gpio.pin(gpio.WS2812, 0))
var anim = animate.core(strip)
anim.set_back_color(0x2222AA)
var pulse = animate.pulse(0xFF4444, 2, 1)
var osc1 = animate.oscillator(-3, 26, 5000, animate.COSINE)
osc1.set_cb(pulse, pulse.set_pos)

# animate color of pulse
var palette = animate.palette(animate.PALETTE_STANDARD_TAG, 30000)
palette.set_cb(pulse, pulse.set_color)

anim.start()
```

```bash
> ./run_animate.be -d 30000 demos/animate_demo_pulse.be
Animation exported to 'output.jsonl'
> python3 generate_gif.py output.jsonl -o pulse.gif
```

#### demo_cylon

<img src='/demo_gif/cylon.gif' height='20'>

```berry
import animate

var strip = Leds(5 * 5, gpio.pin(gpio.WS2812, 0))
var anim = animate.core(strip)
anim.set_back_color(0x000000)
var pulse = animate.pulse(0xFF0000, 3, 2)
var osc1 = animate.oscillator(0, 23, 3000, animate.TRIANGLE)
osc1.set_cb(pulse, pulse.set_pos)

anim.start()
```

```bash
> ./run_animate.be -d 3000 demos/animate_demo_cylon.be
Animation exported to 'output.jsonl'
> python3 generate_gif.py output.jsonl -o cylon.gif
```
