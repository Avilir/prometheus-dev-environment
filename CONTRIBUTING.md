# Contributing to Prometheus Development Environment

First off, thank you for considering contributing to this project! 🎉

This document provides guidelines for contributing to the Prometheus Development Environment. These are guidelines, not rules. Use your best judgment, and feel free to propose changes to this document in a pull request.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Getting Started](#getting-started)
- [Development Process](#development-process)
- [Style Guidelines](#style-guidelines)
- [Testing](#testing)
- [Documentation](#documentation)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

This project adheres to a Code of Conduct. By participating, you are expected to:

- Use welcoming and inclusive language
- Be respectful of differing viewpoints and experiences
- Gracefully accept constructive criticism
- Focus on what is best for the community
- Show empathy towards other community members

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce**
- **Expected behavior**
- **Actual behavior**
- **System information** (OS, Podman/Docker version, etc.)
- **Relevant logs** (use `./scripts/logs.sh`)

### Suggesting Enhancements

Enhancement suggestions are welcome! Please provide:

- **Use case** - Why is this enhancement needed?
- **Expected behavior** - How should it work?
- **Alternative solutions** - What other approaches did you consider?
- **Additional context** - Any other relevant information

### Contributing Code

1. **Find an issue** - Look for issues labeled `good-first-issue` or `help-wanted`
2. **Comment** - Let others know you're working on it
3. **Fork & Branch** - Create your feature branch
4. **Code** - Make your changes
5. **Test** - Ensure everything works
6. **Document** - Update relevant documentation
7. **Submit** - Create a pull request

## Getting Started

### Development Environment Setup

1. **Fork the repository**:
   ```bash
   # Click "Fork" on GitHub, then clone your fork
   git clone https://github.com/Avilir/prom-dev.git
   cd prom-dev
   ```

2. **Create a branch**:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-number
   ```

3. **Set up development environment**:
   ```bash
   # Install dependencies
   ./scripts/setup-dev.sh  # If available
   
   # Copy credentials template
   cp configs/credentials.env.example configs/credentials.env
   # Edit with test values
   ```

4. **Make changes and test**:
   ```bash
   # Start environment
   ./scripts/start.sh
   
   # Run tests
   ./scripts/test.sh
   ```

### Project Structure

```
prom-dev/
├── auth/                 # Authentication configurations
├── configs/              # Configuration files
├── docs/                 # Documentation
├── prometheus/           # Prometheus configs
├── queries/              # PromQL examples
├── scripts/              # Management scripts
│   └── lib/             # Shared libraries
└── *.yml                # Compose files
```

## Development Process

### Branch Naming

- Features: `feature/description`
- Fixes: `fix/issue-number`
- Documentation: `docs/description`
- Performance: `perf/description`

### Commit Messages

Follow the Conventional Commits specification:

```
type(scope): subject

body (optional)

footer (optional)
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style changes
- `refactor`: Code refactoring
- `perf`: Performance improvement
- `test`: Adding tests
- `chore`: Maintenance tasks

Example:
```
feat(auth): add OAuth2 support

Implemented OAuth2 authentication as an alternative to basic auth.
This allows integration with external identity providers.

Closes #123
```

## Style Guidelines

### Shell Scripts

- Use `#!/bin/bash` shebang
- Set `set -e` for error handling
- Use meaningful variable names
- Add comments for complex logic
- Follow ShellCheck recommendations

Example:
```bash
#!/bin/bash
# Script description
# Author: Your Name
# Purpose: What this script does

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Main logic
main() {
    local arg="${1:-default}"
    
    info_msg "Processing: $arg"
    # ... rest of logic
}

main "$@"
```

### YAML Files

- Use 2 spaces for indentation
- Add comments for non-obvious configurations
- Group related settings
- Use meaningful service names

### Documentation

- Use Markdown for all docs
- Include code examples
- Add table of contents for long documents
- Keep language clear and concise

## Testing

### Types of Tests

1. **Unit Tests** - Test individual scripts/functions
2. **Integration Tests** - Test component interactions
3. **End-to-End Tests** - Test complete workflows

### Running Tests

```bash
# Run all tests
./scripts/test.sh

# Test authentication
./scripts/test-auth.sh

# Test specific component
./scripts/test.sh prometheus

# Verbose output
./scripts/test.sh -v
```

### Writing Tests

Create test files in `scripts/tests/`:

```bash
#!/bin/bash
# Test description

source ../lib/common.sh

test_feature() {
    # Arrange
    local expected="value"
    
    # Act
    local actual=$(some_function)
    
    # Assert
    if [ "$actual" = "$expected" ]; then
        success_msg "Test passed"
        return 0
    else
        error_exit "Test failed: expected $expected, got $actual"
    fi
}

# Run test
test_feature
```

## Documentation

### When to Update Documentation

Update documentation when you:
- Add new features
- Change existing behavior
- Fix bugs that affect usage
- Add new configuration options
- Improve setup/installation process

### Documentation Standards

- **README.md** - Overview and quick start
- **INSTALL.md** - Detailed installation steps
- **ARCHITECTURE.md** - System design and components
- **SECURITY.md** - Security considerations

### Code Comments

- Add comments for complex logic
- Document function parameters and returns
- Explain "why" not just "what"
- Keep comments up-to-date with code

## Pull Request Process

### Before Submitting

1. **Test your changes**:
   ```bash
   # Run the test suite
   ./scripts/test.sh
   
   # Test manually
   ./scripts/start.sh
   ./scripts/status.sh
   ```

2. **Update documentation**:
   - Update README if needed
   - Add/update code comments
   - Update CHANGELOG (if exists)

3. **Check code quality**:
   ```bash
   # Shell scripts
   shellcheck scripts/*.sh
   
   # YAML files
   yamllint *.yml
   ```

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement

## Testing
- [ ] Tested locally
- [ ] Added/updated tests
- [ ] All tests pass

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No hardcoded credentials
```

### Review Process

1. **Automated checks** - CI/CD runs tests
2. **Code review** - Maintainers review changes
3. **Feedback** - Address any comments
4. **Approval** - Get required approvals
5. **Merge** - Maintainer merges PR

## Recognition

Contributors are recognized in:
- GitHub contributors page
- CONTRIBUTORS.md file (if applicable)
- Release notes

## Questions?

Feel free to:
- Open an issue for questions
- Join discussions
- Contact maintainers

Thank you for contributing! 🙏