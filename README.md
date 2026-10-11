# obs-noter-toolchain

Repositorio de automatización de compilación y aprovisionamiento de dependencias binarias y SDKs versionados para [obs-noter](https://github.com/gmoivan/obs-noter).

## Propósito

Aprovisionar binarios precompilados, SDKs y cabeceras de desarrollo de forma determinista, rápida y reproducible para los pipelines de CI y release de OBS Noter (cumpliendo con la decisión arquitectónica D08), evitando sobrecargas de compilación nativa en los runners de GitHub Actions.

## Dependencias y Workflows

| Dependencia | Plataformas | Workflow | Formato de Release / Tag | Archivo generado |
|---|---|---|---|---|
| **OBS Studio SDK** | Windows x64 | `.github/workflows/build-obs-sdk.yml` | `obs-<version>` (ej. `obs-32.2.1`) | `obs-sdk-win64.zip` |
| **OpenCV** | Linux x64, Windows x64 | `.github/workflows/build-opencv.yml` | `opencv-<version>-r<run>` (ej. `opencv-4.10.0-r12`) | `opencv-<version>-linux.tar.gz`, `opencv-<version>-windows-x64.zip` |
| **FFmpeg** | Windows x64 | `.github/workflows/build-ffmpeg.yml` | `ffmpeg-<version>-r<run>` (ej. `ffmpeg-7.1-r3`) | `ffmpeg-<version>-windows-x64.zip` |

Los releases de OpenCV y FFmpeg son inmutables: cada ejecución publica en un tag nuevo con su `run_number` (`-r<run>`) y nunca reemplaza assets existentes. Para adoptar un build nuevo, actualiza en `obs-noter` la URL y el SHA-256 fijados. Los tags anteriores sin sufijo (`opencv-4.10.0`, `ffmpeg-7.1`) se conservan como referencia de los hashes vigentes.

## Módulos y configuración

- **OpenCV**: Compilación ligera con `core`, `imgproc`, `dnn`, `objdetect`.
- **FFmpeg**: Cabeceras (`include/libav*`), librerías de importación (`lib/*.lib`), archivos `pkgconfig` y binarios de ejecución (`bin/*.dll`).
- **OBS Studio SDK**: `libobs` y `obs-frontend-api` para la versión de OBS y Qt correspondiente (ej. Qt 6.11.0, MSVC x64).

## Uso en `obs-noter`

El monorepo consume estos activos directamente a través de:
- `.github/actions/setup-windows-native/` con el flag `enable_full_deps: true`
- `.github/workflows/ci.yml`
- `.github/workflows/release.yml`

## Contribución y releases

Ownership, flujo de cambios y contrato de release: [CONTRIBUTING.md](CONTRIBUTING.md).
