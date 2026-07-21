#!/usr/bin/env python3
"""
Phase 3a: Solidify Berry files to C headers using the Python Berry port.

Adapted from solidify_all.be from lv_binding_berry.
Writes a Berry script that runs at top-level (where `global` keyword works),
then executes it via be_loadmode.
"""

import sys
import os
import re
import tempfile

BERRY_PARENT = os.path.join(os.path.dirname(__file__),
    '..', '..', '..', '.tmp', 'Tasmota', 'lib', 'libesp32', 'berry')
sys.path.insert(0, os.path.abspath(BERRY_PARENT))

from berry_port.berry import be_vm_new, be_vm_delete, be_loadbuffer, be_pcall
from berry_port.be_api import be_dumpexcept, be_pop, be_loadmode

HERE = os.path.dirname(os.path.abspath(__file__))
EMBEDDED_DIR = os.path.abspath(os.path.join(HERE, '..', 'src', 'embedded'))
SOLIDIFY_DIR = os.path.abspath(os.path.join(HERE, '..', 'src', 'solidify'))
BERRY_PACKAGES = os.path.abspath(os.path.join(HERE,
    '..', '..', '..', '.tmp', 'Tasmota', 'lib', 'libesp32', 'berry', 'default'))

PATTERN = re.compile(r'#@\s*solidify:([A-Za-z0-9_.,]+)')


def build_berry_script():
    """Build a Berry script that solidifies all .be files."""

    files = ['lv.be', 'lvgl_glob.be', 'lvgl_extra.be']
    lines = []

    # Set globals to nil (as solidify_all.be does)
    globs = [
        "path", "ctypes_bytes_dyn", "tasmota", "ccronexpr", "gpio", "light",
        "webclient", "load", "MD5", "lv", "light_state",
        "lv_clock", "lv_clock_icon", "lv_signal_arcs", "lv_signal_bars",
        "lv_wifi_arcs_icon", "lv_wifi_arcs",
        "lv_wifi_bars_icon", "lv_wifi_bars",
        "_lvgl", "cb",
    ]
    for g in globs:
        lines.append(f"{g} = nil")

    lines.append("")
    lines.append("import global")
    lines.append("import solidify")
    lines.append("import string")
    lines.append("import re")
    lines.append("")

    for src_file in files:
        src_path = os.path.join(EMBEDDED_DIR, src_file)
        fname_h = src_file.split('.be')[0] + '.h'
        out_path = os.path.join(SOLIDIFY_DIR, f"solidified_{fname_h}")

        with open(src_path, 'r') as f:
            src = f.read()

        directives = PATTERN.findall(src)
        if not directives:
            lines.append(f"# {src_file}: no solidify directives, skipping")
            lines.append("")
            continue

        # Escape backslashes and quotes in source path
        src_path_esc = src_path.replace('\\', '\\\\')
        out_path_esc = out_path.replace('\\', '\\\\')

        lines.append(f"# ---- {src_file} ----")
        lines.append(f'var f = open("{src_path_esc}")')
        lines.append("var src = f.read()")
        lines.append("f.close()")
        lines.append("var compiled = compile(src)")
        lines.append("compiled()")
        lines.append("")

        for directive in directives:
            parts = directive.split(',')
            obj_name = parts[0]
            is_weak = 'weak' in parts
            weak_arg = "true" if is_weak else "false"

            # Build the resolve expression using global namespace
            path_parts = obj_name.split('.')
            if len(path_parts) == 1:
                resolve = f"global.{obj_name}"
            else:
                resolve = "global." + ".".join(path_parts)

            lines.append(f'var fout = open("{out_path_esc}", "w")')
            lines.append(f'fout.write("/* Solidification of {fname_h} */\\n")')
            lines.append('fout.write("/********************************************************************\\\\\\n")')
            lines.append('fout.write("* Generated code, don\'t edit                                         *\\n")')
            lines.append('fout.write("\\\\********************************************************************/\\n")')
            lines.append("fout.write('#include \"be_constobj.h\"\\n')")
            lines.append(f'solidify.dump({resolve}, {weak_arg}, fout)')
            lines.append('fout.write("/********************************************************************/\\n")')
            lines.append('fout.write("/* End of solidification */\\n")')
            lines.append("fout.close()")
            lines.append("")

        lines.append("")

    return "\n".join(lines)


def main():
    os.makedirs(SOLIDIFY_DIR, exist_ok=True)

    # Clean output directory
    for f in os.listdir(SOLIDIFY_DIR):
        if not f.startswith('.'):
            os.remove(os.path.join(SOLIDIFY_DIR, f))

    # Write the Berry script to a temp file
    script = build_berry_script()
    script_path = os.path.join(SOLIDIFY_DIR, "_solidify_all.be")
    with open(script_path, 'w') as f:
        f.write(script)

    print(f"Generated Berry script: {script_path}")
    print(f"Script length: {len(script)} bytes")

    # Create VM and run the script via be_loadmode (script-level, where global works)
    vm = be_vm_new()

    try:
        from berry_port.be_module import be_module_path_set
        be_module_path_set(vm, BERRY_PACKAGES)

        res = be_loadmode(vm, script_path, False)
        if res != 0:
            print("COMPILE ERROR:")
            be_dumpexcept(vm)
            be_pop(vm, 1)
            return

        res = be_pcall(vm, 0)
        if res != 0:
            print("RUNTIME ERROR:")
            be_dumpexcept(vm)
            be_pop(vm, 1)
            return

        print("Done.")
    finally:
        be_vm_delete(vm)


if __name__ == '__main__':
    main()
