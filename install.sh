#!/bin/bash

# Salir si algo sale mal
set -e

# Variables predeterminadas
URL_BASE="https://raw.githubusercontent.com/lfmen/TheftDeterrent/main/deb"
# Directorio donde está el script (para buscar los .deb locales)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILES=(
    "theftdeterrentclient-lib_6.0.0.11.huayra10_amd64.deb"
    "theftdeterrentdaemon_6.0.0.11.huayra10_amd64.deb"
    "theftdeterrentguardian_6.0.0.11.huayra10_amd64.deb"
    "theftdeterrentclient_6.0.0.11.huayra10_amd64.deb"
)
GUARDIAN_FILE="theftdeterrentguardian_6.0.0.11.huayra10_amd64.deb"
PATCHED_FILE="theftdeterrentguardian_6.0.0.11.debian10_amd64.deb"
AUTORUN="/opt/TheftDeterrentclient/client/Theft_Deterrent_client.autorun"
DEFAULT_DIR="$HOME/tda"
LOG_FILE="tda_install_log.txt"
USE_LOG=true
CLEANUP=true
INSTALL=true
RUN_AFTER_INSTALL=false

handle_error() {
    echo "Error: $1" >&2
    exit 1
}

show_help() {
    echo "Uso: $0 [OPCIONES]"
    echo "Opciones:"
    echo "  -D, --solo-descarga, --download-only  Solo descarga los paquetes, sin instalar"
    echo "  -d, --dir <directorio>                Directorio de trabajo (predeterminado: $DEFAULT_DIR)"
    echo "  -M, --mirror <URL>                    Servidor alternativo para descargar los paquetes"
    echo "  -L, --log <archivo>                   Archivo de log (predeterminado: $LOG_FILE)"
    echo "      --no-log                          No guarda log"
    echo "      --no-limpiar, --no-cleanup        No borra los .deb después de instalar"
    echo "  -E, --ejecutar                        Abre el cliente al terminar la instalación"
    echo "  -h, --help                            Muestra esta ayuda"
    exit 0
}

process_parameters() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -D | --solo-descarga | --download-only)
                INSTALL=false
                CLEANUP=false
                ;;
            -d | --dir)
                shift
                DEFAULT_DIR="$1"
                ;;
            -M | --mirror)
                shift
                URL_BASE="$1"
                ;;
            -L | --log)
                shift
                LOG_FILE="$1"
                ;;
            --no-log)
                USE_LOG=false
                ;;
            --no-limpiar | --no-cleanup)
                CLEANUP=false
                ;;
            -E | --ejecutar)
                RUN_AFTER_INSTALL=true
                ;;
            -h | -H | --help)
                show_help
                ;;
            *)
                handle_error "parámetro desconocido: $1 (usá --help)"
                ;;
        esac
        shift
    done
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        handle_error "este script tiene que ejecutarse como root (sudo bash install.sh)."
    fi
}

check_dependencies() {
    echo "Verificando dependencias..."
    command -v dpkg >/dev/null || handle_error "dpkg no está instalado."
    command -v wget >/dev/null || { apt-get update && apt-get install -y wget; } || handle_error "no se pudo instalar wget."
}

# El cliente gráfico está enlazado dinámicamente contra libpython2.7
install_python_lib() {
    if dpkg -s libpython2.7 >/dev/null 2>&1; then
        echo "libpython2.7 ya está instalada."
        return 0
    fi

    echo "Instalando libpython2.7..."

    # Ubuntu 22.04 / Mint 21: el paquete está en 'universe'
    apt-get install -y software-properties-common >/dev/null 2>&1 || true
    add-apt-repository universe -y >/dev/null 2>&1 || true
    apt-get update -qq

    if apt-cache show libpython2.7 >/dev/null 2>&1; then
        apt-get install -y libpython2.7 || handle_error "no se pudo instalar libpython2.7."
        return 0
    fi

    # Ubuntu 24.04 / Mint 22: se toma de Jammy con un repositorio temporal
    local jammy_list="/etc/apt/sources.list.d/python2-jammy-temp.list"
    trap "rm -f '$jammy_list'; apt-get update -qq 2>/dev/null || true" EXIT

    echo "libpython2.7 no está en los repositorios. Agregando Jammy de forma temporal..."
    echo "deb http://archive.ubuntu.com/ubuntu/ jammy universe" > "$jammy_list"
    apt-get update -qq
    apt-get install -y libpython2.7 || handle_error "no se pudo instalar libpython2.7 desde Jammy."

    rm -f "$jammy_list"
    apt-get update -qq
    trap - EXIT
}

# Sin Python 2 en el sistema se usa el guardian con metadatos parcheados para Python 3
select_guardian() {
    if command -v python2 >/dev/null 2>&1 || dpkg -s python >/dev/null 2>&1; then
        echo "Python 2 detectado: se usa el guardian original."
    else
        echo "Python 2 no detectado: se usa el guardian parcheado para Python 3."
        FILES=("${FILES[@]/"$GUARDIAN_FILE"/"$PATCHED_FILE"}")
    fi
}

prepare_directory() {
    mkdir -p "$DEFAULT_DIR" || handle_error "no se pudo crear el directorio $DEFAULT_DIR."
    cd "$DEFAULT_DIR" || handle_error "no se puede usar el directorio $DEFAULT_DIR."

    local required_mb=100
    local available_mb
    available_mb=$(( $(df -Pk . | awk 'NR==2 {print $4}') / 1024 ))
    if (( available_mb < required_mb )); then
        handle_error "espacio insuficiente: se necesitan al menos ${required_mb} MB libres en $DEFAULT_DIR."
    fi
}

download_files() {
    for FILE in "${FILES[@]}"; do
        if [ -f "$FILE" ]; then
            echo "$FILE ya está en el directorio de trabajo."
        elif [ -f "$SCRIPT_DIR/deb/$FILE" ]; then
            echo "Copiando $FILE desde deb/..."
            cp "$SCRIPT_DIR/deb/$FILE" "$FILE"
        else
            echo "Descargando $FILE..."
            wget -q "$URL_BASE/$FILE" || handle_error "no se pudo descargar $FILE desde $URL_BASE."
        fi
    done
}

install_files() {
    for FILE in "${FILES[@]}"; do
        echo "Instalando $FILE..."
        dpkg -i "$FILE" || handle_error "no se pudo instalar $FILE."
    done
}

configure_client() {
    if [[ ! -f "$AUTORUN" ]]; then
        echo "Advertencia: no se encontró $AUTORUN; no se creó el comando 'theftdeterrentclient'."
        return 0
    fi

    ln -sf "$AUTORUN" /usr/local/bin/theftdeterrentclient || handle_error "no se pudo crear el enlace simbólico."

    # Evita el error de libgail/atk-bridge en escritorios GTK modernos
    grep -q '^export GTK_MODULES=""' "$AUTORUN" || sed -i '2i export GTK_MODULES=""' "$AUTORUN"

    echo "Comando 'theftdeterrentclient' disponible."
}

process_parameters "$@"
check_root
prepare_directory

if $USE_LOG; then
    exec > >(tee -a "$LOG_FILE") 2>&1
fi

check_dependencies
select_guardian
download_files

if $INSTALL; then
    install_python_lib
    install_files
    configure_client
fi

if $CLEANUP; then
    echo "Borrando paquetes .deb..."
    rm -f -- *.deb
fi

if ! $INSTALL; then
    echo "Paquetes descargados en $DEFAULT_DIR."
    exit 0
fi

echo "Theft Deterrent instalado."
echo "Configuración inicial: https://github.com/lfmen/TheftDeterrent#configuración"

if $RUN_AFTER_INSTALL; then
    "$AUTORUN" || handle_error "no se pudo ejecutar el cliente."
fi
