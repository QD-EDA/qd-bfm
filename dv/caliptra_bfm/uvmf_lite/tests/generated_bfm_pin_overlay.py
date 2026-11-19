#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Stage scalar-pin generated UVMF BFMs for use as IEEE 1800 virtual interfaces."""

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


def stage_sources(bfms, top, output):
    """Flatten {bfm_name: (bfm_path, bus_path)} and rewire their instances in top."""
    output.mkdir(parents=True, exist_ok=True)
    top_source = top.read_text()
    connections = 0
    paths = {}
    for bfm, (bfm_path, bus_path) in bfms.items():
        bus_type = re.sub(r"_(?:driver|monitor)_bfm$", "_if", bfm)
        bus_source = bus_path.read_text()
        content, ports = flatten_bfm(bfm_path.read_text(), bus_type, bus_source)
        paths[f"{bfm}.sv"] = output / f"{bfm}.sv"
        paths[f"{bfm}.sv"].write_text(content)

        def connect(match):
            parameters, instance, bus, modport = match.groups()
            read_only = modport_inputs(bus_source, modport)
            pins = []
            for direction, port, signal in ports:
                # The generated hdl_top selects a modport that makes this
                # signal an input, so its drive pin stays unconnected.
                active = not (direction == "output" and signal in read_only)
                pins.append(f".{port}({bus + '.' + signal if active else ''})")
            head = " ".join(filter(None, (bfm, parameters, instance)))
            return f"{head}(\n    " + ",\n    ".join(pins) + "\n  );"

        top_source, count = re.subn(
            rf"\b{bfm}\s*(#\s*\((?:[^()]|\([^()]*\))*\))?\s+(\w+)\s*\(\s*(\w+)(?:\.(\w+))?\s*\)\s*;",
            connect, top_source,
        )
        connections += count
    paths[top.name] = output / top.name
    paths[top.name].write_text(top_source)
    return paths, connections


def stage_bfms(caliptra, kind, output, top, overrides=()):
    area = {"ECC": "ecc/uvmf_ecc", "HMAC": "hmac/uvmf_2022"}[kind]
    packages = caliptra / "src" / area / "uvmf_template_output/verification_ip/interface_packages"
    if output.resolve().is_relative_to(caliptra.resolve()):
        raise ValueError("overlay must be outside the Caliptra checkout")
    sources = {path.name: path for path in overrides}
    bfms = {}
    for direction in ("in", "out"):
        package = packages / f"{kind}_{direction}_pkg/src"
        for role in ("driver", "monitor"):
            bfm = f"{kind}_{direction}_{role}_bfm"
            bfms[bfm] = (sources.get(f"{bfm}.sv", package / f"{bfm}.sv"),
                         package / f"{kind}_{direction}_if.sv")
    paths, connections = stage_sources(bfms, top, output)
    if connections not in (3, 4):
        raise ValueError(f"expected three generated or four probe BFM instances, got {connections}")
    return paths


def stage_filelist(filelist, output, variables):
    """Stage every generated BFM named by filelist and return the rewritten list."""
    text = filelist.read_text()
    sources = {}
    for line in text.splitlines():
        entry = line.strip()
        for name, value in variables.items():
            entry = entry.replace(f"${{{name}}}", value)
        if entry.endswith(".sv"):
            sources[Path(entry).name] = Path(entry)
    bfms = {}
    for name, path in sources.items():
        match = re.fullmatch(r"(\w+)_(?:driver|monitor)_bfm\.sv", name)
        if match:
            bfms[name[:-3]] = (path, sources[f"{match.group(1)}_if.sv"])
    if not bfms or "hdl_top.sv" not in sources:
        raise ValueError(f"no generated BFMs and hdl_top.sv in {filelist}")
    paths, connections = stage_sources(bfms, sources["hdl_top.sv"], output)
    if not connections:
        raise ValueError(f"no generated BFM instances rewired in {filelist}")
    staged = output / "generated_bfm_pins.vf"
    staged.write_text(rewrite_filelist(text, paths))
    return staged


def rewrite_filelist(text, paths):
    return "".join(
        f"{paths[Path(line.strip()).name]}\n"
        if Path(line.strip()).name in paths else line
        for line in text.splitlines(keepends=True)
    )


if __name__ == "__main__":
    kind, root, out, top, *overrides = sys.argv[1:]
    stage_bfms(Path(root), kind, Path(out), Path(top), map(Path, overrides))
