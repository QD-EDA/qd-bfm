# M16 local Python + NumPy setup

Host: macOS arm64 (`macOS-27.0-arm64-arm-64bit-Mach-O`)

- Python: CPython 3.14.7 (`/opt/homebrew/opt/python@3.14/bin/python3.14`)
- `uv`: 0.12.3
- NumPy: 2.5.4
- Isolated environment: `/Users/danielellerbrock/.local/share/qd-bfm/m16-python`

Setup command:

```sh
uv venv --python 3.14 "$HOME/.local/share/qd-bfm/m16-python"
uv pip install --python "$HOME/.local/share/qd-bfm/m16-python/bin/python" numpy
```

Verification imported NumPy and asserted that the sum of `[1, 2, 3]` is 6. The venv is outside the repository, so it does not add project dependencies or alter system Python.
