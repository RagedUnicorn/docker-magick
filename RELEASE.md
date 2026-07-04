# Release Process

This document describes how to create a new release for the Docker ImageMagick project.

## Quick Start

```bash
# Tag format: v{imagemagick_version}-alpine{alpine_version}-{build_number}
git tag -a v7.1.2.24-alpine3.24.1-1 -m "v7.1.2.24-alpine3.24.1-1"
git push origin v7.1.2.24-alpine3.24.1-1
```

This automatically triggers the release process via GitHub Actions.

## Version Tag Format

See [README.md](README.md#versioning) for the complete versioning documentation.

**Format:** `v{imagemagick_version}-alpine{alpine_version}-{build_number}`

Examples:
- `v7.1.2.24-alpine3.24.1-1` - Initial release
- `v7.1.2.24-alpine3.24.1-2` - Rebuild with same versions
- `v7.1.2.24-alpine3.24.2-1` - Alpine update (build resets to 1)
- `v7.1.2.25-alpine3.24.1-1` - ImageMagick update (build resets to 1)

## Release Workflow

When you push a tag, GitHub Actions automatically:

1. **Builds Docker images** (`.github/workflows/docker_release.yml`)
   - Re-runs the Container Structure Tests as a gate
   - Multi-platform: linux/amd64 and linux/arm64
   - Pushes to both GitHub Container Registry and Docker Hub

2. **Creates GitHub Release** (`.github/workflows/github_release.yml`)
   - Generates changelog from commit history
   - Adds Docker pull commands
   - Links to the release

## When to Create a Release

Create a new release when:

1. **Renovate updates dependencies** - After merging Renovate PRs for Alpine or ImageMagick updates
2. **Bug fixes** - After fixing issues in the Dockerfile or build process
3. **Feature additions** - After adding new format delegates
4. **Security patches** - Immediately after security-related updates

### Build Number Guidelines

- **Reset to 1**: When ImageMagick or Alpine version changes
- **Increment**: When rebuilding with the same versions (fixes, optimizations)

## Post-Release Tasks

### Update Docker Hub Documentation

After creating a release, manually update the Docker Hub repository description:

1. Go to [Docker Hub](https://hub.docker.com/r/ragedunicorn/magick)
2. Click "Manage Repository" → "Description"
3. Copy the contents of `DOCKERHUB.md`
4. Update any version numbers in the examples to match the latest release
5. Save the changes

**Note**: The `DOCKERHUB.md` file is maintained in the repository as the source of truth for Docker Hub documentation.

## Best Practices

### Commit Messages

Use conventional commit format for better changelogs:

- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `chore:` Maintenance tasks
- `refactor:` Code refactoring
- `test:` Test additions/changes
- `perf:` Performance improvements

Example:
```bash
git commit -m "feat: add PDF delegate support"
git commit -m "fix: correct working directory permissions"
git commit -m "docs: update usage examples"
```

### Pre-release Testing

Before creating a release:

1. Test the Docker image locally with your version changes
2. Verify ImageMagick converts test files correctly
3. Check that multi-platform builds work (especially arm64)

## Troubleshooting

### Release didn't trigger

- Ensure tag starts with `v` and follows the format (e.g., `v7.1.2.24-alpine3.24.1-1`)
- Check GitHub Actions tab for workflow runs
- Verify you have push permissions

### Docker build failed

- Check the Docker workflow logs
- Ensure Dockerfile builds locally
- Verify multi-platform compatibility

### Missing permissions

Ensure your repository has:
- GitHub Actions enabled
- Package write permissions for workflows
- Proper secrets configuration (GITHUB_TOKEN is automatic)

### Docker Hub Configuration

To enable Docker Hub deployment, you need to add these secrets to your GitHub repository:

1. Go to Settings → Secrets and variables → Actions
2. Add the following secrets:
   - `DOCKERHUB_USERNAME`: Your Docker Hub username
   - `DOCKERHUB_TOKEN`: Your Docker Hub access token (not password)

To create a Docker Hub access token:
1. Log in to Docker Hub
2. Go to Account Settings → Security
3. Click "New Access Token"
4. Give it a descriptive name (e.g., "GitHub Actions")
5. Copy the token and add it as `DOCKERHUB_TOKEN` secret

## Manual Release (if needed)

If automation fails, you can create a release manually:

1. Go to repository's "Releases" page
2. Click "Create a new release"
3. Choose your tag (must follow format: `v7.1.2.24-alpine3.24.1-1`)
4. Add release notes
5. Include Docker pull commands:
   ```
   docker pull ghcr.io/ragedunicorn/docker-magick:7.1.2.24-alpine3.24.1-1
   docker pull ragedunicorn/magick:7.1.2.24-alpine3.24.1-1
   ```
