# Contribuir a obs-noter-toolchain

## Ownership

| Rol | Responsable | Alcance |
|---|---|---|
| Maintainer y owner | [@gmoivan](https://github.com/gmoivan) | Merge a `main`, ejecución de workflows, tags y releases, configuración del repositorio. |
| Consumidor | [`obs-noter`](https://github.com/gmoivan/obs-noter) | Fija URL y SHA-256 de cada asset que usa; decide cuándo adoptar un build nuevo. |

El ownership de los archivos se declara en [`.github/CODEOWNERS`](.github/CODEOWNERS). Sólo el maintainer ejecuta workflows o crea tags y releases.

## Flujo de cambios

1. Crea una rama corta desde `main` (`fix/...`, `feat/...`, `docs/...`, `chore/...`). `main` está protegida: PR obligatorio, historial lineal, sin force push ni borrado.
2. Limita cada PR a un solo resultado observable.
3. En el PR describe el problema, el cambio, la evidencia de validación, los riesgos y el efecto sobre los assets publicados o sobre `obs-noter`.
4. Fusiona con squash y borra la rama tras confirmar que su contenido está en `main`.

Los cambios en workflows, `permissions`, versiones de actions o lógica de publicación requieren revisión independiente antes del merge.

## Reglas para workflows

- Fija cada action por SHA completo, con la versión en un comentario.
- Declara `permissions` mínimos; sólo se permite `contents: write` donde haga falta publicar un release.
- Descarga el código upstream sólo desde tags oficiales y por HTTPS.
- No agregues secretos: los workflows publican con `github.token`.

## Contrato de release

- **Origen:** los workflows que publican se ejecutan sólo desde `main` (`workflow_dispatch` sobre `main` o tags que apunten a commits de `main`). No ejecutes workflows de publicación desde ramas de PR.
- **Inmutabilidad:** un asset publicado nunca se reemplaza ni se borra. No uses `--clobber` y no borres tags ni releases que `obs-noter` haya fijado. Cada build publica en un tag nuevo `<dep>-<versión>-r<run>` (`obs-`, `opencv-`, `ffmpeg-`). Los tags sin sufijo (`obs-32.2.1`, `opencv-4.10.0`, `ffmpeg-7.1`) se conservan como referencia de los hashes que `obs-noter` fijó.
- **Manifiesto:** cada asset se publica junto a `<asset>.manifest.json` (esquema `obs-noter-toolchain.release-manifest/v1`, generado por [`scripts/write-release-manifest.ps1`](scripts/write-release-manifest.ps1)) con origen upstream (URL, ref, commit y SHA-256 de la fuente cuando aplica), parámetros de compilación, versiones de herramientas, commit y run del toolchain, y tamaño y SHA-256 del asset.
- **Adopción:** `obs-noter` adopta un build mediante un PR propio que actualiza la URL y el SHA-256 fijados. Un release del toolchain no cambia `obs-noter` por sí solo.
- **Retiro:** retira un asset defectuoso dejando de referenciarlo en `obs-noter`. Bórralo del toolchain sólo cuando ningún commit soportado de `obs-noter` lo use.
