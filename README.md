<div align="center">
  <img src="portada_final.png" width="450" alt="Theft Deterrent client" />
</div>

# Theft Deterrent para Linux moderno

Instalador del cliente Theft Deterrent (equipos de Conectar Igualdad y Plan Juana Manso) para distribuciones basadas en Debian actuales y para Fedora, donde los paquetes oficiales ya no funcionan.

Basado en [Jotalea/TheftDeterrent](https://github.com/Jotalea/TheftDeterrent). Proyecto no oficial, sin relación con Intel ni con el Ministerio de Educación.

## Problema

Los paquetes `.deb` de la versión 6.0.0.11 fallan en Ubuntu 22.04+, Linux Mint 21+ y Huayra 6.5+ por dos motivos:

1. `theftdeterrentguardian` depende de Python 2, que ya no está en los repositorios, y `apt` queda con dependencias rotas.
2. El cliente gráfico está enlazado dinámicamente contra `libpython2.7.so.1.0` y se cierra al iniciar si la librería no está instalada.

## Qué hace `install.sh`

- Instala `libpython2.7` desde `universe` o, si no existe (Ubuntu 24.04, Mint 22), desde el repositorio de Ubuntu 22.04 (Jammy), que agrega temporalmente y quita al terminar.
- Usa una versión de `theftdeterrentguardian` con metadatos adaptados a Python 3 cuando el sistema no tiene Python 2.
- Instala los cuatro paquetes desde `deb/` (o los descarga si el script se ejecuta solo).
- Crea el comando `theftdeterrentclient` y desactiva `GTK_MODULES` en el lanzador para evitar un error de GTK en escritorios actuales.

## Compatibilidad

| Sistema | Método |
|:---|:---|
| Ubuntu 22.04 / 24.04, Linux Mint 21 / 22 | `install.sh` (probado) |
| Debian 10+, Huayra 6.5+ | `install.sh` |
| Fedora Workstation 44 (GNOME, SELinux) | `install.sh` (probado; extrae los `.deb` a mano) |
| Huayra 5 / 6 | Paquete `theft` de los repositorios de Huayra |
| Windows 10 / 11 | Instaladores en `windows/` |

## Instalación en Linux

```bash
git clone https://github.com/lfmen/theftdeterrent.git
cd theftdeterrent
sudo bash install.sh
```

Sin clonar el repositorio:

```bash
wget -qO- https://raw.githubusercontent.com/lfmen/theftdeterrent/main/install.sh | sudo bash
```

Opciones disponibles con `sudo bash install.sh --help`. La salida queda registrada en `tda_install_log.txt`, dentro del directorio de trabajo (`$HOME/tda` de root por defecto).

### Fedora

`install.sh` detecta Fedora y, en lugar de `dpkg`, hace esto:

- Instala con `dnf` las herramientas para abrir los `.deb` (`binutils`, `tar`, `xz`). `python2.7` ya no está en los repositorios de Fedora 44; no hace falta, el cliente trae su propio `libpython2.7`.
- Extrae los cuatro paquetes en `/` y ejecuta sus `postinst`.
- Marca las carpetas de Theft Deterrent como `bin_t` en SELinux, para que systemd pueda ejecutarlas.
- Habilita e inicia los servicios `theftdeterrent-tpmdaemon`, `theftdeterrent-guardian` y `theftdeterrent-agent`.

Si un servicio no arranca, revisar `journalctl -u theftdeterrent-agent` y `sudo ausearch -m avc -ts recent`. La extensión de GNOME Shell del cliente es de la era GNOME 3 y puede no cargar en versiones actuales; el cliente se abre igual con `theftdeterrentclient`.

## Instalación en Windows

1. Ejecutar `windows/Theft Deterrent Guardian.exe` y habilitar la desinstalación sin contraseña.
2. Ejecutar `windows/Theft Deterrent Agent.exe`.
3. Reiniciar.

## Configuración

1. Abrir el cliente con `theftdeterrentclient` o desde el menú de aplicaciones.
2. En **Configuración**, indicar el servidor:
   - Equipos Juana Manso: `citd.dgp.educ.ar`
   - Resto de los equipos: `tds.educacion.gob.ar`

## Herramientas de análisis

Scripts en Python 3.12+ usados para diagnosticar los paquetes, sin dependencias externas:

```bash
python tools/deb.py info deb/*.deb                  # metadatos de cada paquete
python tools/deb.py extract <paquete.deb> <destino> # contenido del paquete
python tools/elf_deps.py <destino>                  # librerías que usa cada binario
```

## Referencias

- [Jotalea/TheftDeterrent](https://github.com/Jotalea/TheftDeterrent): repositorio y documentación original.
- [HuayraLinux/theftdeterrent6](https://github.com/HuayraLinux/theftdeterrent6): paquetes oficiales de Huayra.
- [Maxelslasarte](https://huayra.educar.gob.ar/ayuda/?qa=user/Maxelslasarte): adaptación de los metadatos de guardian a Python 3.

## Licencia

El software Theft Deterrent pertenece a sus titulares. Los scripts de este repositorio se distribuyen bajo la [licencia MIT](LICENSE).
