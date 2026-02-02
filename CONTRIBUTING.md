# Contributing to AKS-Cilium Demo

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion:

1. **Check existing issues** to avoid duplicates
2. **Create a new issue** with:
   - Clear title and description
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Environment details (OS, tool versions)
   - Relevant logs or screenshots

### Suggesting Enhancements

For feature requests:

1. Open an issue with tag `enhancement`
2. Describe the use case
3. Explain why it would be useful
4. Provide examples if possible

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
4. **Test thoroughly**
5. **Commit with clear messages**:
   ```bash
   git commit -m "Add: description of changes"
   ```
6. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```
7. **Create a Pull Request**

## Development Guidelines

### Code Style

**Terraform**:
- Use `terraform fmt` before committing
- Follow HashiCorp style guide
- Add comments for complex logic
- Use meaningful variable names

**YAML/Kubernetes**:
- 2-space indentation
- Follow Kubernetes best practices
- Include resource limits
- Add descriptive labels

**Bash Scripts**:
- Use `#!/bin/bash` shebang
- Set `set -e` for error handling
- Add comments for complex operations
- Use functions for reusable code

### Documentation

- Update README.md if adding features
- Add comments in code
- Include examples
- Update relevant docs/ files

### Testing

Before submitting:

1. **Terraform**:
   ```bash
   terraform validate
   terraform fmt -check
   terraform plan
   ```

2. **Kubernetes Manifests**:
   ```bash
   kubectl apply --dry-run=client -f manifests/
   kubectl apply --dry-run=server -f manifests/
   ```

3. **Scripts**:
   ```bash
   shellcheck scripts/*.sh
   bash -n scripts/*.sh  # syntax check
   ```

4. **End-to-End**:
   - Deploy the full stack
   - Run all demos
   - Verify functionality
   - Clean up successfully

## Areas for Contribution

### High Priority

- [ ] Additional network policy examples
- [ ] More Gatekeeper constraint templates
- [ ] Custom Grafana dashboards
- [ ] Prometheus alert rules
- [ ] GitHub Actions CI/CD
- [ ] Cost optimization examples

### Documentation

- [ ] Video tutorials
- [ ] Blog posts
- [ ] Translation to other languages
- [ ] Architecture diagrams
- [ ] Best practices guides

### Examples

- [ ] Multi-tier applications
- [ ] Integration with Azure services
- [ ] GitOps workflows
- [ ] Backup/restore procedures
- [ ] Disaster recovery scenarios

### Tools & Automation

- [ ] Pre-commit hooks
- [ ] Automated testing
- [ ] Cost estimation scripts
- [ ] Performance benchmarking
- [ ] Security scanning

## Project Structure

```
.
├── terraform/              # Terraform IaC
├── manifests/             # Kubernetes manifests
│   ├── network-policies/  # Cilium policies
│   ├── monitoring/        # Monitoring configs
│   └── constraints/       # OPA policies
├── demos/                 # Demo scripts
├── scripts/               # Utility scripts
└── docs/                  # Documentation
```

## Commit Message Format

Use clear, descriptive commit messages:

```
Type: Brief description

Detailed explanation if needed

- Change 1
- Change 2
```

**Types**:
- `Add`: New feature or file
- `Fix`: Bug fix
- `Update`: Modify existing feature
- `Refactor`: Code restructuring
- `Docs`: Documentation changes
- `Test`: Testing changes
- `Chore`: Maintenance tasks

**Examples**:
```
Add: Layer 4 network policy example

Adds a new example demonstrating layer 4 TCP/UDP policies
with port-specific rules.

- New manifest file
- Updated README with example
- Demo script updated
```

## Review Process

1. All PRs require at least one review
2. CI checks must pass
3. Documentation must be updated
4. Changes should be tested

## Community Guidelines

- Be respectful and inclusive
- Provide constructive feedback
- Help newcomers
- Follow the code of conduct

## Questions?

- Open an issue with `question` label
- Check existing documentation
- Review closed issues/PRs

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Credited in documentation

Thank you for contributing! 🎉
