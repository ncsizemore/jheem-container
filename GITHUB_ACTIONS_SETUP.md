# GitHub Actions Setup Guide

This repository includes a GitHub Actions workflow that automatically builds and pushes Docker images to DockerHub on commits to the main branch.

## Required GitHub Secrets

To enable DockerHub pushing, you need to configure these secrets in your GitHub repository:

### Setting up DockerHub Secrets

1. **Go to your repository on GitHub**
2. **Navigate to Settings → Secrets and variables → Actions**
3. **Add the following repository secrets:**

#### `DOCKERHUB_USERNAME`
- Your DockerHub username (e.g., `ncsizemore`)

#### `DOCKERHUB_TOKEN`
- A DockerHub access token (recommended) or your DockerHub password
- **To create an access token:**
  1. Log in to [DockerHub](https://hub.docker.com)
  2. Go to Account Settings → Security → Access Tokens
  3. Click "New Access Token"
  4. Give it a name (e.g., "GitHub Actions")
  5. Select appropriate permissions (Read, Write, Delete)
  6. Copy the generated token and use it as the secret value

## Workflow Triggers

The workflow will run on:
- **Push to main/master branch** → Builds and pushes with `latest` tag
- **Push tags** (e.g., `v1.0.0`) → Builds and pushes with version tags
- **Pull requests** → Builds only (no push)
- **Manual trigger** → Can be run manually from Actions tab

## Image Tags

The workflow creates multiple tags:
- `latest` - for main branch builds
- `v1.0.0`, `v1.0`, `v1` - for version tags
- `main-abc123` - branch + git SHA
- `pr-123` - for pull requests

## Build Configuration

- **Platforms**: `linux/amd64`, `linux/arm64`
- **Cache**: GitHub Actions cache for faster builds
- **JHEEM Analyses**: Pinned to commit `fc3fe1d2d5f859b322414da8b11f0182e635993b`

## Testing Locally

You can test the modified Dockerfile locally:

```bash
# Build the image
docker build -t jheem-ryan-white-model .

# Test specific stage
docker build --target workspace-builder -t workspace-test .

# Use different jheem_analyses commit
docker build --build-arg JHEEM_ANALYSES_COMMIT=abc123 -t jheem-ryan-white-model .
```

## Updating JHEEM Analyses

To update to a newer commit of `tfojo1/jheem_analyses`:

1. Test the new commit locally first
2. Update the `JHEEM_ANALYSES_COMMIT` in `.github/workflows/build-and-push.yml`
3. Commit and push the change

The build arg ensures reproducible builds while allowing easy updates when needed.
