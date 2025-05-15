# Contributing to CynthiaWebsiteEngine Mini

We warmly welcome contributions to the CynthiaWebsiteEngine Mini project. This document provides guidelines and information for contributors.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [How to Contribute](#how-to-contribute)
4. [Development Process](#development-process)
5. [Submission Guidelines](#submission-guidelines)

## Code of Conduct

This project adheres to our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Getting Started

1. Fork the repository
2. Clone your fork:

   ```bash
   git clone https://github.com/your-username/Mini.git
   ```

3. Set up your development environment:

   ```bash
   cd CynthiaWebsiteEngine-Mini
   bun install
   ```

## How to Contribute

### Reporting Issues

- Utilise the [issue tracker](https://github.com/CynthiaWebsiteEngine/Mini/issues)
- Search for existing issues before creating a new one
- Provide detailed reproduction steps
- Include system information when relevant

### Contributing Code

1. Create a feature branch:

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes
3. Write or update tests
4. Run the test suite:

   ```bash
   bun run check
   bun run test
   ```

5. Commit your changes using conventional commit messages
6. Push to your fork
7. Submit a Pull Request

### Documentation

- Keep documentation up-to-date with code changes
- Follow British English spelling conventions
- Use clear, concise language
- Include examples where appropriate

### Contributing Themes

Please refer to our [Theme Contribution Guide](https://cynthiawebsiteengine.github.io/Mini-docs/#/adding-themes) for detailed instructions.

## Development Process

### Code Style

- Follow the established project coding style
- Use meaningful variable and function names
- Include appropriate comments
- Maintain consistent formatting

### Testing

- Write tests for new features
- Update tests for modified code
- Ensure all tests pass before submitting
- Aim for comprehensive test coverage

### Version Control

- Make focused, atomic commits
- Write clear commit messages
- Keep pull requests concise and focused
- Rebase your branch before submitting

## Submission Guidelines

### Pull Request Process

1. Update documentation as needed
2. Add tests for new functionality
3. Ensure CI passes
4. Request review from maintainers
5. Address review feedback promptly

### Review Process

- Maintainers will review PRs regularly
- Feedback should be addressed timely
- Changes may be requested before merging
- Be patient and responsive during review

Thank you for contributing to CynthiaWebsiteEngine Mini!
