# Docker Container Build Workflow

This document explains how to build the rTorrent-ruTorrent Docker container using both automated CI/CD workflows and local development builds.

## Overview

The project provides multiple ways to build the Docker container:

1. **GitHub Actions Workflow** - Automated CI/CD pipeline
2. **Local Build Script** - Interactive development builds
3. **Direct Docker Bake** - Manual build commands

## 📦 Container Registry

Built images are published to GitHub Container Registry. After the workflow runs, you can pull and use the images:

```bash
# Pull the latest image
docker pull ghcr.io/your-username/rtorrent-rutorrent:latest

# Run the published image
docker run -d --name rtorrent-rutorrent \
  -e PUID=1000 -e PGID=1000 \
  -v ./data:/data \
  -v ./downloads:/downloads \
  -v ./passwd:/passwd \
  -p 8080:8080 -p 8000:8000 \
  ghcr.io/your-username/rtorrent-rutorrent:latest
```

Replace `your-username` with your actual GitHub username.

## GitHub Actions Workflow

### Workflow Features

The GitHub Actions workflow (`.github/workflows/build.yml`) provides:

- **Multi-platform builds**: Supports `linux/amd64`, `linux/arm/v6`, `linux/arm/v7`, and `linux/arm64`
- **Automated publishing**: Pushes to GitHub Container Registry
- **Build caching**: Uses GitHub Actions cache for faster builds
- **Security scanning**: Trivy vulnerability scanning
- **Container testing**: Basic functionality tests
- **Smart triggering**: Builds on pushes, PRs, and tags

### Workflow Jobs

#### 1. Build Job
- Builds images for each platform in parallel
- Uploads build artifacts (digests) for multi-platform manifest creation
- Uses build matrix for efficient parallel processing

#### 2. Merge Job
- Creates multi-platform manifests
- Pushes final images to GitHub Container Registry
- Runs only on non-PR events

#### 3. Test Job
- Runs basic container functionality tests
- Only executes on pull requests
- Validates container startup and web interface

#### 4. Security Scan Job
- Performs vulnerability scanning with Trivy
- Uploads results to GitHub Security tab
- Runs on main builds only

### Required Secrets

The GitHub Actions workflow only requires the automatically provided `GITHUB_TOKEN` secret for pushing to GitHub Container Registry. No additional secrets need to be configured.

### Triggering Builds

The workflow triggers on:

- **Push to main/master**: Builds and publishes `latest` tag
- **Push tags (v\*)**: Builds and publishes versioned releases
- **Pull requests**: Builds and tests without publishing
- **Manual dispatch**: Can be triggered manually from GitHub UI

### Image Tags

The workflow creates these image tags:

- `latest` - Latest build from main/master branch
- `<branch-name>` - Branch-specific builds
- `<version>` - Semantic version tags (e.g., `v1.2.3`)
- `<major>.<minor>` - Major.minor version tags (e.g., `1.2`)
- `<major>` - Major version tags (e.g., `1`)

## Local Build Script

### Quick Start

```bash
# Simple local build
./build.sh

# Build with custom tag
./build.sh --tag my-rtorrent:dev

# Build for specific platform
./build.sh --platform linux/arm64

# Build multi-platform (requires push)
./build.sh --type multi-platform --push
```

### Build Script Options

```bash
Usage: ./build.sh [OPTIONS]

Options:
  -t, --type TYPE         Build type: local, multi-platform, or all (default: local)
  -p, --platform PLATFORM Specific platform to build (e.g., linux/amd64)
  --push                  Push image to registry
  --no-cache              Disable build cache
  --tag TAG               Custom tag for the image (default: rtorrent-rutorrent:local)
  -h, --help              Display this help message

Build Types:
  local                   Build for local platform only (default)
  multi-platform          Build for all supported platforms
  all                     Build and export to docker for all platforms

Examples:
  ./build.sh                      # Build for local platform
  ./build.sh --type multi-platform --push  # Build multi-platform and push
  ./build.sh --platform linux/arm64        # Build for ARM64 only
  ./build.sh --tag my-rtorrent:v1.0        # Build with custom tag
```

### Build Script Features

- **Prerequisites checking**: Validates Docker and Buildx availability
- **Buildx setup**: Automatically configures multi-platform builder
- **Build caching**: Intelligent cache management
- **Container testing**: Runs basic functionality tests
- **Colored output**: Easy-to-read status messages
- **Error handling**: Proper error handling and cleanup

## Direct Docker Bake Commands

### Basic Commands

```bash
# Build for local development
docker buildx bake

# Build specific target
docker buildx bake image-local

# Build multi-platform
docker buildx bake image-all

# Build with cache disabled
docker buildx bake --no-cache

# Build for specific platform
docker buildx bake --set *.platform=linux/arm64
```

### Docker Bake Targets

The `docker-bake.hcl` file defines these targets:

- `image-local`: Build for local platform and load to Docker
- `image`: Base image target
- `image-all`: Multi-platform build for all supported architectures

## Build Environment

### System Requirements

- Docker 20.10+ with Buildx support
- Multi-platform builds require QEMU emulation
- At least 4GB RAM recommended for builds
- Fast internet connection for downloading base images

### Supported Platforms

- `linux/amd64` - x86_64 Linux
- `linux/arm/v6` - ARM v6 (Raspberry Pi 1)
- `linux/arm/v7` - ARM v7 (Raspberry Pi 2/3)
- `linux/arm64` - ARM 64-bit (Raspberry Pi 4, Apple Silicon)

## Build Performance

### Optimization Tips

1. **Use build cache**: Significantly reduces rebuild times
2. **Multi-stage builds**: The Dockerfile uses multi-stage builds for efficiency
3. **Parallel builds**: Build script uses all available CPU cores
4. **Layer caching**: Optimize Docker layer caching with proper ordering

### Build Times

Approximate build times (varies by system):

- **Local build (cached)**: 5-10 minutes
- **Local build (no cache)**: 30-45 minutes
- **Multi-platform build**: 1-2 hours

## Troubleshooting

### Common Issues

#### Docker Buildx Not Available
```bash
# Install buildx plugin
docker buildx install
```

#### Platform Not Supported
```bash
# Register QEMU emulators
docker run --privileged --rm tonistiigi/binfmt --install all
```

#### Build Cache Issues
```bash
# Clear build cache
docker buildx prune -a
```

#### Permission Issues
```bash
# Fix script permissions
chmod +x build.sh
```

### Debug Mode

Enable verbose logging:

```bash
# Set buildx debug mode
export BUILDX_EXPERIMENTAL=1
export BUILDKIT_PROGRESS=plain

# Run build with debug
./build.sh --no-cache
```

## Container Usage

### Running the Built Container

```bash
# Create required directories
mkdir -p data downloads passwd

# Set proper ownership (replace 1000:1000 with your UID:GID)
sudo chown 1000:1000 data downloads passwd

# Run container
docker run -d --name rtorrent-rutorrent \
  -e PUID=1000 -e PGID=1000 \
  -v ./data:/data \
  -v ./downloads:/downloads \
  -v ./passwd:/passwd \
  -p 8080:8080 -p 8000:8000 \
  rtorrent-rutorrent:local
```

### Accessing the Interface

- **ruTorrent Web UI**: http://localhost:8080
- **XMLRPC Interface**: http://localhost:8000

### Environment Variables

Key environment variables for the container:

```bash
# User/Group IDs
PUID=1000                    # User ID
PGID=1000                    # Group ID

# Network Configuration
RT_DHT_PORT=6881            # DHT port
RT_INC_PORT=50000           # Incoming connections port
XMLRPC_PORT=8000            # XMLRPC port
RUTORRENT_PORT=8080         # Web interface port

# Resource Limits
MEMORY_LIMIT=256M           # PHP memory limit
UPLOAD_MAX_SIZE=16M         # Upload size limit
```

## Development Workflow

### Recommended Development Process

1. **Fork the repository**
2. **Create a feature branch**
3. **Make changes to Dockerfile or scripts**
4. **Test locally**: `./build.sh`
5. **Test container functionality**
6. **Submit pull request**
7. **CI/CD tests run automatically**
8. **Merge triggers production build**

### Testing Changes

```bash
# Build and test locally
./build.sh --tag test:dev

# Run extended tests
docker run --rm -it test:dev /bin/bash

# Check container logs
docker logs container-name
```

## CI/CD Integration

### Branch Protection

Recommended branch protection rules:

- Require status checks: `build`, `test`, `security-scan`
- Require up-to-date branches
- Restrict pushes to main/master

### Release Process

1. **Create release tag**: `git tag v1.2.3`
2. **Push tag**: `git push origin v1.2.3`
3. **GitHub Actions builds and publishes automatically**
4. **Images available on GitHub Container Registry**

### Monitoring

Monitor build status:

- GitHub Actions tab for build logs
- GitHub Container Registry for image statistics
- GitHub Security tab for vulnerability reports

## Contributing

### Build System Changes

When modifying the build system:

1. **Test locally first**: Use `./build.sh` for validation
2. **Update documentation**: Keep this BUILD.md current
3. **Test CI/CD**: Verify workflow changes in fork first
4. **Consider backward compatibility**: Don't break existing workflows

### Adding New Platforms

To add support for new platforms:

1. **Update `docker-bake.hcl`**: Add platform to `image-all` target
2. **Update workflow**: Add platform to build matrix
3. **Test thoroughly**: Ensure platform compatibility
4. **Update documentation**: Add platform to supported list 