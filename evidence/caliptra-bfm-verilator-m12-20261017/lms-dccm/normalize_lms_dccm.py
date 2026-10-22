import re


DCCM_SIZE = 0x40000
SIGNED_DCCM_BASE = 0xFFFFFFFFB0000000


def normalize_dccm_text(text):
    output = []
    addresses = []
    for line in text.splitlines(keepends=True):
        content = line.rstrip("\r\n")
        if not content.strip().startswith("@"):
            output.append(line)
            continue
        match = re.fullmatch(r"(\s*)@([0-9a-fA-F]+)(\s*)", content)
        if not match:
            raise ValueError("invalid DCCM readmemh address directive")
        address = int(match.group(2), 16)
        if SIGNED_DCCM_BASE <= address < SIGNED_DCCM_BASE + DCCM_SIZE:
            offset = address - SIGNED_DCCM_BASE
        elif address < DCCM_SIZE:
            offset = address
        else:
            raise ValueError("DCCM readmemh address is outside the 256 KiB DCCM image")
        addresses.append((address, offset))
        output.append(f"{match.group(1)}@{offset:08X}{match.group(3)}{line[len(content):]}")

    if not addresses:
        raise ValueError("DCCM readmemh image has no address directive")
    normalized = "".join(output)
    payload = lambda value: [
        token
        for line in value.splitlines()
        if not line.strip().startswith("@")
        for token in line.split()
    ]
    if payload(text) != payload(normalized):
        raise AssertionError("DCCM normalization changed image data")
    return normalized, addresses
