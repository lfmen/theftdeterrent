"""Lista las librerías compartidas que referencia cada binario ELF de un archivo o directorio.

uso:
    python tools/elf_deps.py <binario_o_directorio>
"""
import os
import re
import sys

# heurístico: busca nombres lib*.so en los bytes del binario; para un análisis exacto usar `readelf -d` o `ldd`.
LIB = re.compile(rb"lib[\w\-.+]+\.so[.\d]*")


def scan(path):
    with open(path, "rb") as f:
        data = f.read()
    if data.startswith(b"\x7fELF"):
        print(path)
        for lib in sorted(set(LIB.findall(data))):
            print("   ", lib.decode())


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    target = sys.argv[1]
    if os.path.isdir(target):
        for root, _, files in os.walk(target):
            for name in files:
                path = os.path.join(root, name)
                if os.path.isfile(path) and not os.path.islink(path):
                    scan(path)
    else:
        scan(target)
