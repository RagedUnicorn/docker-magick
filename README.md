# docker-magick

![](./docs/docker_magick_banner.svg)

[![Release Build](https://github.com/RagedUnicorn/docker-magick/actions/workflows/docker_release.yml/badge.svg)](https://github.com/RagedUnicorn/docker-magick/actions/workflows/docker_release.yml)
[![Test](https://github.com/RagedUnicorn/docker-magick/actions/workflows/test.yml/badge.svg)](https://github.com/RagedUnicorn/docker-magick/actions/workflows/test.yml)
![License: MIT](docs/license_badge.svg)

> Docker Alpine image with ImageMagick and common image format delegates.

![](./docs/alpine_linux_logo.svg)

## Overview

This Docker image provides a lightweight ImageMagick 7 installation on Alpine Linux, installed from Alpine's package
repository with a pinned version. It includes the delegate libraries for the common image formats so you can convert,
resize, and inspect images without installing ImageMagick on your host.

## Features

- **Small footprint**: Alpine Linux base with only the needed format delegates
- **ImageMagick 7**: The modern `magick` CLI (legacy `convert`/`identify`/`mogrify` entry points included)
- **Common format support**: JPEG, PNG, GIF, WebP, HEIC/AVIF (read), SVG, and TIFF
- **Text rendering**: DejaVu fonts installed and wired into `type.xml`, so `-annotate`, `-draw "text"` and `label:` work without passing `-font`
- **Non-root**: Runs as the unprivileged `magick` user by default
- **Volume mounting**: Easy file input/output through `/tmp/workdir`

## Supported Formats

### Built-in

- PNG
- GIF
- BMP

### Via delegate packages

- JPEG (libjpeg-turbo)
- WebP (libwebp)
- HEIC/HEIF (libheif, read/decode)
- AVIF (libheif, read/decode)
- SVG (librsvg)
- TIFF (libtiff)

### Not included

- PDF/PostScript (requires ghostscript — deliberately excluded to keep the image small and avoid the ghostscript
  security surface)
- JPEG XL, RAW, OpenEXR

See [DEVELOPMENT.md](DEVELOPMENT.md) if you need to build a variant with additional delegates.

## Quick Start

```bash
# Pull the image
docker pull ragedunicorn/magick:latest

# Convert an image in the current directory
docker run -v $(pwd):/tmp/workdir ragedunicorn/magick:latest input.png output.jpg
```

On Windows, use the PowerShell form:

```powershell
# Convert an image in the current directory
docker run -v "${PWD}:/tmp/workdir" ragedunicorn/magick:latest input.png output.jpg
```

Write `${PWD}` **with braces** and keep the colon inside the quotes - without
braces PowerShell parses `$PWD:` as a scope-qualified variable (as in
`$env:PATH`) and rejects the argument. See the
[Windows (PowerShell) notes](#windows-powershell-notes) for details.

For development and building from source, see [DEVELOPMENT.md](DEVELOPMENT.md).

## Usage

The container uses `magick` as the entrypoint, so any ImageMagick parameters can be passed directly to the
`docker run` command. Running the image without arguments prints the ImageMagick version.

### Basic Usage

```bash
# Using latest version
docker run -v $(pwd):/tmp/workdir ragedunicorn/magick:latest [magick-options]

# Using specific ImageMagick version (latest Alpine build)
docker run -v $(pwd):/tmp/workdir ragedunicorn/magick:<imagemagick-version> [magick-options]

# Using exact version combination
docker run -v $(pwd):/tmp/workdir ragedunicorn/magick:<imagemagick-version>-alpine<alpine-version>-<build> [magick-options]
```

PowerShell:

```powershell
# Using latest version
docker run -v "${PWD}:/tmp/workdir" ragedunicorn/magick:latest [magick-options]

# Using specific ImageMagick version (latest Alpine build)
docker run -v "${PWD}:/tmp/workdir" ragedunicorn/magick:<imagemagick-version> [magick-options]

# Using exact version combination
docker run -v "${PWD}:/tmp/workdir" ragedunicorn/magick:<imagemagick-version>-alpine<alpine-version>-<build> [magick-options]
```

Available tags are listed on [Docker Hub](https://hub.docker.com/r/ragedunicorn/magick/tags) and in the
[GitHub releases](https://github.com/RagedUnicorn/docker-magick/releases).

### Examples

#### Convert Image Format

```bash
docker run -v $(pwd):/tmp/workdir ragedunicorn/magick:latest input.png output.jpg
```

PowerShell:

```powershell
docker run -v "${PWD}:/tmp/workdir" ragedunicorn/magick:latest input.png output.jpg
```

#### Resize an Image

```bash
docker run -v $(pwd):/tmp/workdir ragedunicorn/magick:latest input.jpg -resize 50% output.jpg
```

PowerShell:

```powershell
docker run -v "${PWD}:/tmp/workdir" ragedunicorn/magick:latest input.jpg -resize 50% output.jpg
```

#### Create a Thumbnail

```bash
docker run -v $(pwd):/tmp/workdir ragedunicorn/magick:latest input.jpg -thumbnail 150x150 thumbnail.jpg
```

PowerShell:

```powershell
docker run -v "${PWD}:/tmp/workdir" ragedunicorn/magick:latest input.jpg -thumbnail 150x150 thumbnail.jpg
```

#### Get Image Information

```bash
docker run -v $(pwd):/tmp/workdir ragedunicorn/magick:latest identify input.png
```

PowerShell:

```powershell
docker run -v "${PWD}:/tmp/workdir" ragedunicorn/magick:latest identify input.png
```

#### Convert iPhone Photos (HEIC to JPEG)

```bash
docker run -v $(pwd):/tmp/workdir ragedunicorn/magick:latest photo.heic photo.jpg
```

PowerShell:

```powershell
docker run -v "${PWD}:/tmp/workdir" ragedunicorn/magick:latest photo.heic photo.jpg
```

#### Strip Metadata

```bash
docker run -v $(pwd):/tmp/workdir ragedunicorn/magick:latest input.jpg -strip output.jpg
```

PowerShell:

```powershell
docker run -v "${PWD}:/tmp/workdir" ragedunicorn/magick:latest input.jpg -strip output.jpg
```

#### Create an Animated GIF from Images

```bash
docker run -v $(pwd):/tmp/workdir ragedunicorn/magick:latest -delay 20 -loop 0 "frame*.png" animation.gif
```

PowerShell:

```powershell
docker run -v "${PWD}:/tmp/workdir" ragedunicorn/magick:latest -delay 20 -loop 0 "frame*.png" animation.gif
```

Keep the quotes around `"frame*.png"` in both shells: ImageMagick expands the
wildcard inside the container, against the files in `/tmp/workdir`.

### Windows (PowerShell) notes

The PowerShell variants above differ from the bash ones only in the mount,
which is written `-v "${PWD}:/tmp/workdir"` instead of `-v $(pwd):/tmp/workdir`.
The ImageMagick arguments after the image name are passed through unchanged.

The mount spelling matters:

- Pasting the bash form into PowerShell breaks: an argument that starts with
  `$(pwd)` ends after the subexpression, so `$(pwd):/tmp/workdir` reaches
  Docker as two arguments (`C:\path` and `:/tmp/workdir`) and fails with
  `invalid reference format`.
- `"$PWD:/tmp/workdir"` without braces is a parse error: PowerShell reads a
  colon after a variable as a scope qualifier (as in `$env:PATH`), and `/` is
  not a valid variable-name character.
- `"${PWD}:/tmp/workdir"` works: the braces end the variable name at `PWD`, the
  colon stays literal, and Docker splits the resulting `C:\path:/tmp/workdir`
  on the second colon because it recognises the `C:` drive prefix.

The image runs as the non-root `magick` user. On Windows hosts this needs no
extra flags: Docker Desktop bind mounts do not carry Unix file ownership, so
the container can write its output files into the mounted directory.

To check what the container actually sees under `/tmp/workdir`, run a
look-inside command:

```powershell
docker run --rm -v "${PWD}:/tmp/workdir" --entrypoint sh ragedunicorn/magick:latest -c 'pwd; ls -la /tmp/workdir'
```

The single quotes keep the `sh -c` command one literal argument; unquoted,
PowerShell would treat `;` as its own statement separator and run
`ls -la /tmp/workdir` on the host.

## Docker Compose Usage

This repository includes Docker Compose configurations for easier usage and common image processing workflows.

### Basic Setup

1. Create a `media` directory structure:

```bash
mkdir -p media/input media/output
```

PowerShell:

```powershell
New-Item -ItemType Directory -Force media/input, media/output
```

2. Place your input files in `media/input/`

3. Run ImageMagick using docker compose:

```bash
docker compose run --rm magick input/image.png output/image.jpg
```

The `docker compose` commands in this section mount `./media` through the
compose file, so they run unchanged in PowerShell.

### Example Configurations

The `examples/` directory contains specialized docker-compose files for common tasks:

#### Format Conversion (`examples/docker-compose.convert.yml`)

```bash
# Convert PNG to JPEG
docker compose -f examples/docker-compose.convert.yml run --rm png-to-jpg

# Convert JPEG to WebP
docker compose -f examples/docker-compose.convert.yml run --rm jpg-to-webp

# Convert iPhone HEIC photos to JPEG
docker compose -f examples/docker-compose.convert.yml run --rm heic-to-jpg
```

#### Resizing (`examples/docker-compose.resize.yml`)

```bash
# Create a 150x150 thumbnail
docker compose -f examples/docker-compose.resize.yml run --rm thumbnail

# Resize to half size
docker compose -f examples/docker-compose.resize.yml run --rm resize-half
```

See [examples/README.md](examples/README.md) for the full list of example services.

### Environment Variables

- `MAGICK_VERSION`: Specify the image version (default: latest)

### Tips

1. **Custom Commands**: Override the default command:

   ```bash
   docker compose run --rm magick input/photo.jpg -resize 800x -strip output/photo_web.jpg
   ```

2. **Batch Processing**: Use the batch service in `examples/docker-compose.convert.yml` for processing multiple files

3. **Persistent Settings**: The repository includes a `.env` file with default settings. You can modify it to set your
   preferred version:

   ```env
   MAGICK_VERSION=<imagemagick-version>-alpine<alpine-version>-<build>
   ```

## Versioning

This project uses semantic versioning that matches the Docker image contents:

**Format:** `{imagemagick_version}-alpine{alpine_version}-{build_number}`

Examples (`W.X.Y.Z` is the 4-part ImageMagick version, `A.B.C` the Alpine version):
- `W.X.Y.Z-alpineA.B.C-1` - ImageMagick W.X.Y.Z on Alpine A.B.C, build 1
- `W.X.Y.Z` - Most recent build of ImageMagick W.X.Y.Z
- `latest` - Most recent stable release

The current tags are listed on [Docker Hub](https://hub.docker.com/r/ragedunicorn/magick/tags).

For detailed release process and versioning guidelines, see [RELEASE.md](RELEASE.md).

## Image Verification

Released images are signed with [cosign](https://docs.sigstore.dev/) keyless signing and carry SBOM and provenance attestations.

```bash
# Verify the signature (works for both ghcr.io/ragedunicorn/docker-magick and ragedunicorn/magick)
cosign verify ragedunicorn/magick:latest \
  --certificate-identity-regexp '^https://github.com/RagedUnicorn/docker-magick/\.github/workflows/docker_release\.yml@refs/tags/v' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com

# Inspect the SBOM and provenance attestations
docker buildx imagetools inspect ragedunicorn/magick:latest --format '{{ json .SBOM }}'
docker buildx imagetools inspect ragedunicorn/magick:latest --format '{{ json .Provenance }}'
```

## Automated Dependency Updates

This project uses [Renovate](https://docs.renovatebot.com/) to automatically check for updates to:
- Alpine Linux base image version (all major, minor, and patch updates)
- ImageMagick package version (pinned Alpine package, tracked via Repology)

Renovate runs weekly (every Monday) and creates pull requests when updates are available. The configuration tracks
both Alpine Linux and the ImageMagick package, creating separate pull requests for each update.

## Documentation

- [Development Guide](DEVELOPMENT.md) - Building, debugging, and contributing
- [Testing Guide](TEST.md) - Running and writing tests
- [Release Process](RELEASE.md) - Creating releases and versioning

## Links

- [ImageMagick Documentation](https://imagemagick.org/script/command-line-processing.php)
- [Alpine Linux](https://www.alpinelinux.org/)

# License

MIT License

Copyright (c) 2026 Michael Wiesendanger

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
