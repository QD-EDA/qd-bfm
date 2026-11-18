#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Stage scalar-pin ECC/HMAC BFMs for use as IEEE 1800 virtual interfaces."""

import re
import sys
from pathlib import Path


def flatten_bfm(source, bus_type, bus_source):
    widths = {name: width.strip() for width, name in re.findall(
        r"(?m)^[ \t]*(?:input|inout) tri\s+((?:\[[^\]\n]+\][ \t]*)*)(\w+)",
        bus_source,
    )}
    reads = dict.fromkeys(re.findall(r"(?m)^\s*assign \w+ = bus\.(\w+);", source))
    drives = dict.fromkeys(re.findall(r"(?m)^\s*assign bus\.(\w+) =", source))
    if not reads or not drives.keys() <= reads.keys() or not reads.keys() <= widths.keys():
        raise ValueError(f"unexpected pin assignments for {bus_type}")
    ports = [("input", "qd_pin_" + name, name) for name in reads]
    ports += [("output", "qd_drive_" + name, name) for name in drives]
    declarations = ",\n".join(
        "  " + " ".join(filter(None, (direction, "wire", widths[name], port)))
        for direction, port, name in ports
    )
    source, count = re.subn(rf"\(\s*{bus_type}\s+bus\s*\);",
                            f"(\n{declarations}\n);", source)
    if count != 1:
        raise ValueError(f"expected one {bus_type} interface port")
    source = re.sub(r"(?m)^(\s*assign )bus\.(\w+)( =)", r"\g<1>qd_drive_\2\3", source)
    source = re.sub(r"(= )bus\.(\w+)(;)", r"\g<1>qd_pin_\2\3", source)
    if re.search(r"\bbus\.", re.sub(r"(?m)//[^\n]*", "", source)):
        raise ValueError(f"unhandled bus reference in {bus_type}")
    return source, ports


def modport_inputs(bus_source, modport):
    if modport is None:
        return set()
    match = re.search(rf"\bmodport\s+{modport}\s*\((.*?)\);", bus_source, re.S)
    if match is None:
        raise ValueError(f"modport {modport} not found")
    return set(re.findall(r"\binput\s+(\w+)", match.group(1)))


def stage_bfms(caliptra, kind, output, top, overrides=()):
    area = {"ECC": "ecc/uvmf_ecc", "HMAC": "hmac/uvmf_2022"}[kind]
    packages = caliptra / "src" / area / "uvmf_template_output/verification_ip/interface_packages"
    if output.resolve().is_relative_to(caliptra.resolve()):
        raise ValueError("overlay must be outside the Caliptra checkout")
    output.mkdir(parents=True, exist_ok=True)
    sources = {path.name: path for path in overrides}
    top_source = top.read_text()
    connections = 0
    paths = {}
    for direction in ("in", "out"):
        prefix = f"{kind}_{direction}"
        package = packages / f"{prefix}_pkg/src"
        bus_type = f"{prefix}_if"
        bus_source = (package / f"{bus_type}.sv").read_text()
        for role in ("driver", "monitor"):
            bfm = f"{prefix}_{role}_bfm"
            name = f"{bfm}.sv"
            content, ports = flatten_bfm(sources.get(name, package / name).read_text(),
                                         bus_type, bus_source)
            paths[name] = output / name
            paths[name].write_text(content)

            def connect(match):
                instance, bus, modport = match.groups()
                read_only = modport_inputs(bus_source, modport)
                pins = []
                for direction, port, signal in ports:
                    # The generated hdl_top selects a modport that makes this
                    # signal an input, so its drive pin stays unconnected.
                    active = not (direction == "output" and signal in read_only)
                    pins.append(f".{port}({bus + '.' + signal if active else ''})")
                return f"{bfm} {instance}(\n    " + ",\n    ".join(pins) + "\n  );"

            top_source, count = re.subn(
                rf"\b{bfm}\s+(\w+)\(\s*(\w+)(?:\.(\w+))?\s*\);",
                connect, top_source,
            )
            connections += count
    if connections not in (3, 4):
        raise ValueError(f"expected three generated or four probe BFM instances, got {connections}")
    paths[top.name] = output / top.name
    paths[top.name].write_text(top_source)
    return paths


def rewrite_filelist(text, paths):
    return "".join(
        f"{paths[Path(line.strip()).name]}\n"
        if Path(line.strip()).name in paths else line
        for line in text.splitlines(keepends=True)
    )


if __name__ == "__main__":
    kind, root, out, top, *overrides = sys.argv[1:]
    stage_bfms(Path(root), kind, Path(out), Path(top), map(Path, overrides))
