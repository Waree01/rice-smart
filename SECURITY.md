# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in rice-smart, please report it responsibly:

1. **Do NOT** create a public GitHub issue
2. Email: nenoteerawat@gmail.com
3. Include: description, steps to reproduce, potential impact

We will acknowledge receipt within 48 hours and provide a detailed response within 7 days.

## Security Measures

- API keys stored via `envied` with obfuscation (never hardcoded)
- On-device ML inference (no image data sent to servers)
- Firebase Authentication for user management
- HTTPS for all API communications
- SAST scanning via Semgrep in CI/CD
- Dependency vulnerability scanning via Trivy
- Secret detection via TruffleHog
- OWASP MSTG guidelines compliance
