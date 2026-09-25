"""Inspecciona y extrae paquetes .deb sin depender de dpkg ni tar.

uso:
    python tools/deb.py info <paquete.deb>...
    python tools/deb.py extract <paquete.deb> <destino>
"""
import io
import sys
import tarfile


def members(path):
    with open(path, "rb") as f:
        if f.read(8) != b"!<arch>\n":
            raise ValueError(f"{path} no es un paquete .deb válido")
        while header := f.read(60):
            name = header[:16].decode().strip().rstrip("/")
            size = int(header[48:58])
            yield name, f.read(size)
            f.read(size % 2)


def open_tar(path, prefix):
    for name, data in members(path):
        if name.startswith(prefix):
            return tarfile.open(fileobj=io.BytesIO(data))
    raise ValueError(f"{path} no contiene {prefix}")


def info(path):
    with open_tar(path, "control.tar") as tf:
        print(tf.extractfile("./control").read().decode())


def extract(path, dest):
    with open_tar(path, "data.tar") as tf:
        tf.extractall(dest, filter="data")


if __name__ == "__main__":
    if len(sys.argv) >= 3 and sys.argv[1] == "info":
        for p in sys.argv[2:]:
            print(f"--- {p}")
            info(p)
    elif len(sys.argv) == 4 and sys.argv[1] == "extract":
        extract(sys.argv[2], sys.argv[3])
    else:
        sys.exit(__doc__)
