# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-04-25

### Added

- On-device disease detection using TFLite (EfficientNet-B0)
- Pest identification with image classification
- Pasadee Thai-native chatbot for rice farming advice
- Weather integration with device GPS detection and 77-province offline lookup
- Encrypted local storage for GPS coordinates and farmer data

### Fixed

- **Weather**: Use device GPS instead of hardcoded Sukhothai default location ([#15](https://github.com/nenoteerawat/rice-smart/pull/15), closes [#14](https://github.com/nenoteerawat/rice-smart/issues/14))
  - Added fallback chain: saved location → GPS detection → manual province picker
  - Encrypted GPS coordinates at rest using flutter_secure_storage
  - Added privacy redaction of coordinates in logs
  - Added lat/lon bounds validation

### Security

- GPS coordinates encrypted at rest and redacted from logs to protect farmer privacy
