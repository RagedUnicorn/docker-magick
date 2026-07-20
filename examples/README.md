# magick Docker Examples

This directory contains docker-compose configurations for common image processing tasks.

## Setup

The examples read input files from `media/input/` and write results to `media/output/` (relative to the repository
root). A sample `media/input/image.png` ships with the repository, so the `png-to-jpg` example (and the `run-examples`
run configuration) work out of the box with no setup.

To try the other examples, drop your own images into `media/input/` using the file names each service expects (see the
tables below):

```bash
# media/input/ already exists with the bundled sample; add more images as needed
cp my-photo.jpg media/input/image.jpg
```

The `media/` directory is otherwise gitignored — only the bundled sample is tracked, so your own inputs and all
generated outputs stay out of version control.

All commands below are run from the repository root.

## Format Conversion (`docker-compose.convert.yml`)

| Service         | What it does                                    |
|-----------------|-------------------------------------------------|
| `png-to-jpg`    | Convert `input/image.png` to JPEG (quality 90)  |
| `jpg-to-webp`   | Convert `input/image.jpg` to WebP (quality 80)  |
| `heic-to-jpg`   | Convert `input/photo.heic` (iPhone) to JPEG     |
| `svg-to-png`    | Rasterize `input/image.svg` to PNG              |
| `batch-convert` | Convert every PNG in `input/` to JPEG           |

```bash
docker compose -f examples/docker-compose.convert.yml run --rm png-to-jpg
```

## Resize and Optimization (`docker-compose.resize.yml`)

| Service          | What it does                                          |
|------------------|-------------------------------------------------------|
| `thumbnail`      | 150x150 thumbnail of `input/image.jpg`                |
| `resize-half`    | Resize `input/image.jpg` to 50%                       |
| `resize-width`   | Resize `input/image.jpg` to 800px width               |
| `strip-metadata` | Remove EXIF/profiles from `input/image.jpg`           |
| `web-optimize`   | Resize to max 1200px width, strip metadata, quality 85 |

```bash
docker compose -f examples/docker-compose.resize.yml run --rm thumbnail
```

## Customizing

The services use fixed file names (`input/image.png` etc.) to stay copy-paste simple. For ad-hoc commands, use the
main compose file from the repository root and pass any ImageMagick arguments directly:

```bash
docker compose run --rm magick input/photo.jpg -resize 640x -strip output/photo_small.jpg
```

## Image Version

All examples use `ragedunicorn/magick:${MAGICK_VERSION:-latest}`. To run them against a different version:

**Linux/macOS:**

```bash
MAGICK_VERSION=test docker compose -f examples/docker-compose.convert.yml run --rm png-to-jpg
```

**Windows (PowerShell):**

```powershell
$env:MAGICK_VERSION="test"; docker compose -f examples/docker-compose.convert.yml run --rm png-to-jpg
```
