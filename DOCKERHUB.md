# ImageMagick Alpine Docker Image

A lightweight ImageMagick 7 installation on Alpine Linux with the delegate libraries for common image formats.

## Quick Start

```bash
# Pull latest version
docker pull ragedunicorn/magick:latest

# Or pull specific version
docker pull ragedunicorn/magick:7.1.2.24-alpine3.24.1-1

# Convert an image
docker run -v $(pwd):/tmp/workdir ragedunicorn/magick:latest input.png output.jpg
```

## Features

- 🚀 **Small footprint**: Alpine Linux base with only the needed format delegates
- 📦 **ImageMagick 7**: The modern `magick` CLI (legacy `convert`/`identify` entry points included)
- 🖼️ **Common format support**: JPEG, PNG, GIF, WebP, HEIC/AVIF (read), SVG, TIFF
- 🔒 **Non-root**: Runs as the unprivileged `magick` user by default
- 🏗️ **Multi-platform**: Supports linux/amd64 and linux/arm64

## Supported Formats

**Built-in**: PNG, GIF, BMP
**Delegates**: JPEG (libjpeg-turbo), WebP (libwebp), HEIC/HEIF and AVIF (libheif, read), SVG (librsvg), TIFF (libtiff)
**Not included**: PDF/PostScript (ghostscript), JPEG XL, RAW

## Usage Examples

### Convert image format

```bash
docker run -v $(pwd):/tmp/workdir ragedunicorn/magick:latest \
  input.png output.jpg
```

### Resize an image

```bash
docker run -v $(pwd):/tmp/workdir ragedunicorn/magick:latest \
  input.jpg -resize 50% output.jpg
```

### Create a thumbnail

```bash
docker run -v $(pwd):/tmp/workdir ragedunicorn/magick:latest \
  input.jpg -thumbnail 150x150 thumbnail.jpg
```

### Convert iPhone photos (HEIC to JPEG)

```bash
docker run -v $(pwd):/tmp/workdir ragedunicorn/magick:latest \
  photo.heic photo.jpg
```

## Tags

This image uses semantic versioning that includes all component versions:

**Format:** `{imagemagick_version}-alpine{alpine_version}-{build_number}`

### Version Examples

- `7.1.2.24-alpine3.24.1-1` - Initial release with ImageMagick 7.1.2.24 and Alpine 3.24.1
- `7.1.2.24-alpine3.24.1-2` - Rebuild of same versions (bug fixes, security patches)
- `7.1.2.24-alpine3.24.2-1` - Alpine Linux patch update
- `7.1.2.25-alpine3.24.1-1` - ImageMagick version update

When updates are available through automated dependency management, new releases are created with appropriate version tags.

## Links

- **GitHub**: [https://github.com/RagedUnicorn/docker-magick](https://github.com/RagedUnicorn/docker-magick)
- **Issues**: [https://github.com/RagedUnicorn/docker-magick/issues](https://github.com/RagedUnicorn/docker-magick/issues)
- **Releases**: [https://github.com/RagedUnicorn/docker-magick/releases](https://github.com/RagedUnicorn/docker-magick/releases)

## License

MIT License - See [GitHub repository](https://github.com/RagedUnicorn/docker-magick) for details.
