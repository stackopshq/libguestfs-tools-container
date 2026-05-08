# Contributing to LibGuestFS Tools Container

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with:
- A clear, descriptive title
- Steps to reproduce the issue
- Expected behavior vs actual behavior
- Your environment (Podman version, OS, SELinux mode, etc.)
- Relevant logs or error messages

### Suggesting Enhancements

Enhancement suggestions are welcome! Please create an issue with:
- A clear description of the enhancement
- Use cases and benefits
- Any implementation ideas you have

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Make your changes** following the coding standards below
3. **Test your changes** thoroughly
4. **Update documentation** (README, examples, etc.) as needed
5. **Commit your changes** with clear, descriptive commit messages
6. **Push to your fork** and submit a pull request

#### Pull Request Guidelines

- Keep changes focused and atomic
- Write clear commit messages following conventional commits format
- Update the CHANGELOG.md with your changes
- Ensure the container image builds successfully (`podman build`)
- Test with multiple image formats if applicable

## Development Setup

### Building Locally

```bash
git clone https://github.com/stackopshq/libguestfs-tools-container.git
cd docker-libguestfs-tools
podman build -t libguestfs-tools:dev .
```

### Testing Changes

```bash
# Test basic functionality
podman run --rm libguestfs-tools:dev qemu-img --version
podman run --rm libguestfs-tools:dev libguestfs-test-tool

# Test with a sample image (note :Z for SELinux Enforcing hosts)
podman run --rm -v ./test-images:/workspace/images:Z libguestfs-tools:dev \
  virt-df -a /workspace/images/test.qcow2
```

## Coding Standards

### Containerfile
- Keep the build to a single layer where it makes sense (install + cleanup in one `RUN`)
- Minimize image size: aggressive cleanup of caches, docs, man pages
- Document all `ENV` variables in [README.md](README.md)
- The file is named `Containerfile` (OCI convention) and consumed by `podman build`

### Shell Scripts
- Use `#!/bin/bash` shebang
- Include `set -e` for error handling
- Add comments for complex operations
- Make scripts executable (`chmod +x`)

### Documentation
- Keep README.md up to date
- Add examples for new features
- Use clear, concise language
- Include code examples where helpful

## Commit Message Format

Follow the conventional commits specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `chore`: Maintenance tasks
- `refactor`: Code refactoring
- `test`: Adding or updating tests

**Example:**
```
feat(containerfile): add support for additional filesystems

Added support for ZFS and F2FS filesystems by including
necessary packages in the base image.

Closes #123
```

## Release Process

Releases are automated via GitHub Actions ([.github/workflows/build-image.yml](.github/workflows/build-image.yml)) using `buildah` and `podman push`:

1. Update CHANGELOG.md with release notes
2. Create and push a version tag:
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```
3. The workflow builds multi-arch (linux/amd64, linux/arm64) and pushes to `ghcr.io/stackopshq/libguestfs-tools` automatically

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Assume good intentions

## Questions?

Feel free to open an issue for any questions about contributing!
