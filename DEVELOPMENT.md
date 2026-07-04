# Development Guide

This document provides information for developers working on the ImageMagick Docker image.

## Development Environment

### Prerequisites

- Docker installed and running
- Docker Compose installed
- Git for version control
- Text editor or IDE

### Project Structure

```
docker-magick/
├── Dockerfile              # Main image definition
├── docker-compose.yml      # Basic usage configuration
├── docker-compose.dev.yml  # Development environment
├── docker-compose.test.yml # Test orchestration
├── .env                    # Default environment variables
├── examples/               # Example Docker Compose configurations
│   ├── docker-compose.convert.yml
│   └── docker-compose.resize.yml
├── test/                   # Container Structure Tests
│   ├── magick_test.yml
│   ├── magick_command_test.yml
│   └── magick_metadata_test.yml
└── docs/                   # Documentation assets
```

## Development Workflow

### 1. Local Development Mode

The `docker-compose.dev.yml` file provides an interactive development environment:

```bash
# Build the image locally
docker compose -f docker-compose.dev.yml build

# Run in development mode (interactive shell)
docker compose -f docker-compose.dev.yml run --rm magick-dev

# Inside the container, you can run magick manually
magick -version
magick -list format
magick input/image.png output/image.jpg
```

The development mode:

- Overrides the entrypoint to `/bin/sh` for interactive access
- Mounts the `./media` directory for testing files
- Sets a custom prompt to identify the development environment
- Keeps STDIN open and allocates a TTY

### 2. Building the Image

```bash
# Basic build
docker build -t ragedunicorn/magick:dev .

# Build with specific versions
docker build \
  --build-arg IMAGEMAGICK_VERSION=7.1.2.24-r0 \
  --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
  --build-arg VERSION=7.1.2.24-alpine3.24.1-1 \
  -t ragedunicorn/magick:7.1.2.24-alpine3.24.1-1 .

# Multi-platform build (requires buildx)
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t ragedunicorn/magick:dev .
```

### 3. Testing Your Changes

After making changes, always build and test locally:

```bash
# Build your changes locally
docker build -t ragedunicorn/magick:test .
```

#### Running Tests (Cross-Platform)

**Linux/macOS:**

```bash
# Run all tests against your local build
MAGICK_VERSION=test docker compose -f docker-compose.test.yml run test-all

# Run specific tests during development
MAGICK_VERSION=test docker compose -f docker-compose.test.yml up container-test-command
```

**Windows Command Prompt:**

```cmd
# Run all tests against your local build
set MAGICK_VERSION=test && docker compose -f docker-compose.test.yml run test-all

# Run specific tests during development
set MAGICK_VERSION=test && docker compose -f docker-compose.test.yml up container-test-command
```

**Windows PowerShell:**

```powershell
# Run all tests against your local build
$env:MAGICK_VERSION="test"; docker compose -f docker-compose.test.yml run test-all

# Run specific tests during development
$env:MAGICK_VERSION="test"; docker compose -f docker-compose.test.yml up container-test-command
```

**Important:** Never test against remote images - they may have different labels or configurations due to CI/CD overrides.

See [TEST.md](TEST.md) for detailed testing information.

## Making Changes

### Version Updates

This project uses [Renovate](https://docs.renovatebot.com/) to automatically manage dependency updates:

- **ImageMagick**: Renovate monitors the Alpine package version via [Repology](https://repology.org/) and creates PRs
  when the pinned `imagemagick` apk package moves
- **Alpine Linux**: Renovate monitors Docker Hub and creates PRs for new Alpine versions

The Alpine version is referenced in several places that must stay aligned:

- The `FROM alpine:X.X.X` line in the Dockerfile (tracked by Renovate's built-in Dockerfile manager)
- The `org.opencontainers.image.base.name` OCI label in the Dockerfile (tracked by a regex custom manager)
- The Alpine version asserted in `test/magick_metadata_test.yml` (tracked by a regex custom manager)

All of these resolve to the same `alpine` dependency at the same version, so Renovate bumps them together in a single
PR — the base image, the label, and the metadata test no longer drift apart. No manual sync step is required.

**ImageMagick version pinning caveat:** the Dockerfile pins the apk package
(`imagemagick=${IMAGEMAGICK_VERSION}`). Alpine's package index only serves the latest version per branch, so when the
branch gets a package update the old pin no longer resolves and the image build fails until the Renovate PR (automerged
once tests pass) lands. This is expected and self-healing.

**Manual step on Alpine minor/major bumps (e.g. 3.24 → 3.25):** the Renovate comment above the version ARG embeds the
Alpine branch in the Repology package name:

```dockerfile
# renovate: datasource=repology depName=alpine_3_24/imagemagick versioning=loose
ARG IMAGEMAGICK_VERSION=7.1.2.24-r0
```

When the `alpine` group PR bumps the base image to a new minor release, that PR will fail CI because the pinned
ImageMagick version usually does not exist on the new branch. Fix it inside the same PR:

1. Update the branch in the depName: `alpine_3_24/imagemagick` → `alpine_3_25/imagemagick`
2. Set `IMAGEMAGICK_VERSION` to the version the new branch ships (check
   [pkgs.alpinelinux.org](https://pkgs.alpinelinux.org/packages?name=imagemagick))
3. Update the version examples in the documentation if needed

When Renovate creates a PR:

1. Review the changes in the PR
2. Check the CI/CD pipeline passes all tests
3. Test the build locally if it's a major version update
4. Merge the PR if everything looks good

### Adding New Format Delegates

Alpine packages ImageMagick's format support as subpackages (e.g. `imagemagick-pdf`, `imagemagick-jxl`,
`imagemagick-raw`). To add one:

1. Add the subpackage to the `apk add` list in the Dockerfile, pinned to the same `${IMAGEMAGICK_VERSION}`
2. Add the format to the delegate format check in `test/magick_command_test.yml`
3. Add a shared-library glob check in `test/magick_test.yml` (find the library with the inspection command in TEST.md)
4. Update the supported-format lists in README.md and DOCKERHUB.md
5. Test the build locally

Example of adding PDF support:

```dockerfile
RUN apk add --no-cache \
    ca-certificates \
    imagemagick=${IMAGEMAGICK_VERSION} \
    ...
    imagemagick-pdf=${IMAGEMAGICK_VERSION} \
    ghostscript
```

## Code Style and Best Practices

### Dockerfile Best Practices

1. **Single stage**: The image installs a packaged payload; no build stage is needed
2. **Layer optimization**: Group related commands to minimize layers
3. **Cache efficiency**: Order commands from least to most frequently changed
4. **Security**: Run as a non-root user; keep the delegate set minimal
5. **Labels**: Follow OCI naming conventions

### Documentation

1. **README.md**: Keep focused on user-facing information
2. **Comments**: Add comments in Dockerfile for complex operations
3. **Examples**: Provide working examples for new features
4. **Commit messages**: Use conventional format (feat:, fix:, docs:, etc.)

### Testing

1. **Test everything**: New features must include tests
2. **Test edge cases**: Include negative tests where appropriate
3. **Keep tests fast**: Avoid long-running operations in tests
4. **Test organization**: Group related tests together

## Debugging

### Common Issues

**Build failures:**

```bash
# Verbose build output
docker build --progress=plain --no-cache -t ragedunicorn/magick:debug .
```

**Format not available:**

```bash
# List all available formats
docker run --rm ragedunicorn/magick:dev -list format

# Check delegate configuration
docker run --rm ragedunicorn/magick:dev -list delegate

# Check the version and enabled features
docker run --rm ragedunicorn/magick:dev -version
```

**Library issues:**

```bash
# Check which delegate libraries are present
docker run --rm --entrypoint sh ragedunicorn/magick:dev -c \
  "ls /usr/lib | grep -E '(jpeg|webp|heif|rsvg|tiff)'"

# Check the security policy
docker run --rm --entrypoint sh ragedunicorn/magick:dev -c "cat /etc/ImageMagick-7/policy.xml"
```

## Contributing

### Before Submitting Changes

1. Run the full test suite
2. Update documentation if needed
3. Add tests for new features
4. Ensure your code follows the existing style
5. Write clear commit messages

### Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes using conventional commits
4. Push to your fork
5. Open a Pull Request with a clear description

### Release Process

See [RELEASE.md](RELEASE.md) for information about creating releases.
