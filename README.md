# Tasmota-Berry-emulator

This project is a minimal Tasmota/Berry emulator enabling to run and try animations on a laptop, without the need to iterate on an actual embedded device. The goal is to provide an animated image (animated GIF or else) to visualize the result and iterate.

Online demo: [Emulator](https://staars.github.io/docs/emulator/)

## Installation

Requirements: Python 3.x, C standard compiler, [Emscripten](https://emscripten.org/) (for WASM build)

### Step 1. Clone the repository

```bash
git clone https://github.com/Staars/Tasmota-Berry-emulator.git
cd Tasmota-Berry-emulator
```

### Step 2. Compile Berry (WASM)

```bash
make web
```
## How to use

### WASM (browser)

```bash
emrun docs
```
