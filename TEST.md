# Testing Guide

This document describes how to test the magick Docker image using Container Structure Tests.

## Quick Start

```bash
# Run all tests
docker compose -f docker-compose.test.yml run test-all

# Run individual test suites
docker compose -f docker-compose.test.yml up container-test          # File structure tests
docker compose -f docker-compose.test.yml up container-test-command  # Command execution tests
docker compose -f docker-compose.test.yml up container-test-metadata # Metadata validation tests
```

## Test Structure

The test suite consists of three main test files:

### 1. File Structure Tests (`test/magick_test.yml`)

Validates:

- The `magick` binary and legacy entry points (`convert`, `identify`) exist
- The ImageMagick security policy is present
- Working directory `/tmp/workdir` exists and is accessible
- Delegate shared libraries (JPEG, WebP, HEIC, SVG, TIFF) are installed
- CA certificates are present

### 2. Command Execution Tests (`test/magick_command_test.yml`)

Validates:

- ImageMagick version output
- Built-in format support (PNG, GIF)
- Delegate format support (JPEG, WEBP, HEIC, SVG, TIFF)
- A generate-and-convert roundtrip in the working directory
- Working directory functionality
- The non-root `magick` user exists

### 3. Metadata Tests (`test/magick_metadata_test.yml`)

Validates:

- OCI-compliant labels are present and correct
- Container entrypoint and default command
- Working directory configuration
- User context (runs as the non-root `magick` user)

## Running Tests

### Prerequisites

1. Docker must be installed and running
2. Build the magick image locally before testing

### Important: Always Test Local Builds

**⚠️ Always build and test locally to ensure consistency:**

```bash
# Build the image locally with a test tag
docker build -t ragedunicorn/magick:test .
```

**Linux/macOS:**

```bash
# Run tests against your local build
MAGICK_VERSION=test docker compose -f docker-compose.test.yml run test-all
```

**Windows (PowerShell):**

```powershell
# Run tests against your local build
$env:MAGICK_VERSION="test"; docker compose -f docker-compose.test.yml run test-all
```

**Windows (Command Prompt):**

```cmd
# Run tests against your local build
set MAGICK_VERSION=test && docker compose -f docker-compose.test.yml run test-all
```

**Why local testing is important:**
- Remote images (Docker Hub, GHCR) may have different labels due to CI/CD overrides
- Ensures you're testing exactly what you built
- Avoids false positives/negatives from version mismatches
- Guarantees consistent test results

**Never pull remote images for testing:**

**❌ DON'T DO THIS - may have different labels/settings:**

```bash
docker pull ragedunicorn/magick:latest
docker compose -f docker-compose.test.yml run test-all
```

**✅ DO THIS - test your local build:**

Linux/macOS:

```bash
docker build -t ragedunicorn/magick:test .
MAGICK_VERSION=test docker compose -f docker-compose.test.yml run test-all
```

Windows (PowerShell):

```powershell
docker build -t ragedunicorn/magick:test .
$env:MAGICK_VERSION="test"; docker compose -f docker-compose.test.yml run test-all
```

### Test Execution

Run all tests against your local build:

**Linux/macOS:**

```bash
# Ensure you've built locally first!
MAGICK_VERSION=test docker compose -f docker-compose.test.yml run test-all
```

**Windows (PowerShell):**

```powershell
# Ensure you've built locally first!
$env:MAGICK_VERSION="test"; docker compose -f docker-compose.test.yml run test-all
```

**Windows (Command Prompt):**

```cmd
# Ensure you've built locally first!
set MAGICK_VERSION=test && docker compose -f docker-compose.test.yml run test-all
```

Run specific test categories:

**Linux/macOS:**

```bash
# File structure and library tests
MAGICK_VERSION=test docker compose -f docker-compose.test.yml up container-test

# Command execution and format tests
MAGICK_VERSION=test docker compose -f docker-compose.test.yml up container-test-command

# Metadata and label tests
MAGICK_VERSION=test docker compose -f docker-compose.test.yml up container-test-metadata
```

**Windows (PowerShell):**

```powershell
# File structure and library tests
$env:MAGICK_VERSION="test"; docker compose -f docker-compose.test.yml up container-test

# Command execution and format tests
$env:MAGICK_VERSION="test"; docker compose -f docker-compose.test.yml up container-test-command

# Metadata and label tests
$env:MAGICK_VERSION="test"; docker compose -f docker-compose.test.yml up container-test-metadata
```

### Testing Different Versions

When testing different versions, always build locally first:

```bash
# Build a specific version locally
docker build -t ragedunicorn/magick:7.1.2.24-alpine3.24.1-1 .
```

**Linux/macOS:**

```bash
# Test that specific version
MAGICK_VERSION=7.1.2.24-alpine3.24.1-1 docker compose -f docker-compose.test.yml run test-all
```

**Windows (PowerShell):**

```powershell
# Test that specific version
$env:MAGICK_VERSION="7.1.2.24-alpine3.24.1-1"; docker compose -f docker-compose.test.yml run test-all
```

## Troubleshooting Test Failures

### Library Version Mismatches

Alpine Linux uses versioned shared libraries (e.g., `libjpeg.so.8` instead of `libjpeg.so`), and the SONAME version can
change on Alpine bumps. To avoid breaking on every update, `test/magick_test.yml` checks delegate libraries with
version-agnostic globs (`ls /usr/lib/libjpeg.so.*`) instead of hardcoded paths, so no manual version updates are
needed. Functional format coverage lives in `test/magick_command_test.yml`, which verifies the formats by name via
`magick -list format`.

To inspect the current library versions in the image:

```bash
docker run --rm --entrypoint sh ragedunicorn/magick:latest -c \
  "find /usr/lib -name '*.so*' | grep -E '(jpeg|webp|heif|rsvg|tiff)' | sort"
```

### Metadata Test Failures

**Common causes:**

1. **Testing remote images instead of local builds**
   - Remote images (Docker Hub, GHCR) have labels overridden by CI/CD
   - Always test your local builds with `MAGICK_VERSION=test`

2. **Label value mismatches**
   - CI/CD systems may capitalize values (e.g., "RagedUnicorn" vs "ragedunicorn")
   - GitHub Actions may override labels during build
   - Docker Hub automated builds may set different values

3. **Version-specific labels**
   - The `org.opencontainers.image.version` label changes with each build
   - Build date labels are dynamic

4. **Alpine base image drift**
   - `test/magick_metadata_test.yml` asserts `org.opencontainers.image.base.name` (e.g. `docker.io/library/alpine:X.X.X`)
   - This value must match the `FROM alpine:X.X.X` line and the `base.name` label in the Dockerfile
   - Renovate keeps all three in sync: the Alpine version in the metadata test and the Dockerfile label are tracked by
     regex custom managers, so they bump together with the `FROM` line in a single `alpine` PR and no longer drift apart
   - If you bump Alpine manually, update the metadata test value in the same change

**Solution:** Always build and test locally before pushing:

```bash
docker build -t ragedunicorn/magick:test .
```

Linux/macOS:

```bash
MAGICK_VERSION=test docker compose -f docker-compose.test.yml run test-all
```

Windows (PowerShell):

```powershell
$env:MAGICK_VERSION="test"; docker compose -f docker-compose.test.yml run test-all
```

### Permission Errors

If you encounter Docker socket permission errors:

```bash
sudo docker compose -f docker-compose.test.yml run test-all
```

Or ensure your user is in the `docker` group:

```bash
sudo usermod -aG docker $USER
# Log out and back in for changes to take effect
```

## Writing New Tests

To add new tests, follow the Container Structure Test schema:

1. **File tests**: Add to `test/magick_test.yml`
2. **Command tests**: Add to `test/magick_command_test.yml`
3. **Metadata tests**: Add to `test/magick_metadata_test.yml`

Example of adding a new format test:

```yaml
- name: 'Check new format support'
  command: 'magick'
  args: ['-list', 'format']
  expectedOutput:
    - 'NEWFORMAT'
  exitCode: 0
```

## CI/CD Integration

These tests are automatically run in GitHub Actions:

- **On every push** to master branches
- **On every pull request** to master branches
- **Before releases** to ensure quality

The test workflow (`.github/workflows/test.yml`):
1. Builds the Docker image
2. Runs all Container Structure Tests
3. Verifies basic ImageMagick functionality
4. Blocks releases if tests fail

Manual integration example:

```yaml
- name: Run Container Structure Tests
  env:
    MAGICK_VERSION: test
  run: docker compose -f docker-compose.test.yml run test-all
```

The `test-all` service returns:
- Exit code 0: All tests passed
- Exit code 1: One or more tests failed

## Test Maintenance

When updating the Docker image:

1. **ImageMagick version updates**: Usually no test changes needed (the version check asserts `ImageMagick 7.1.2`,
   which only needs loosening on a minor version jump)
2. **Alpine version updates**: The Alpine version in `test/magick_metadata_test.yml` is kept in sync with the
   Dockerfile by Renovate (same `alpine` dependency bumps everywhere together)
3. **New delegate additions**: Add corresponding tests to verify functionality
4. **Label changes**: Update metadata tests to match new labels

Always run the full test suite before creating a release.
