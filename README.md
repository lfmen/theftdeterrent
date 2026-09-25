# Theft Deterrent para Linux moderno

Instalador del cliente Theft Deterrent (equipos de Conectar Igualdad y Plan Juana Manso) para distribuciones basadas en Debian actuales, donde los paquetes oficiales ya no funcionan.

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
| Huayra 5 / 6 | Paquete `theft` de los repositorios de Huayra |
| Windows 10 / 11 | Instaladores en `windows/` |

## Instalación en Linux

```bash
git clone https://github.com/lfmen/TheftDeterrent.git
cd TheftDeterrent
sudo bash install.sh
```

Sin clonar el repositorio:

```bash
wget -qO- https://raw.githubusercontent.com/lfmen/TheftDeterrent/main/install.sh | sudo bash
```

Opciones disponibles con `sudo bash install.sh --help`. La salida queda registrada en `tda_install_log.txt`, dentro del directorio de trabajo (`$HOME/tda` de root por defecto).

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
