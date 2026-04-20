#!/bin/bash
# ============================================================
# rice-smart - GitHub Repository Setup Script
# ============================================================
# Run this script from the rice-smart project root directory:
#   cd rice-smart
#   chmod +x scripts/setup_github.sh
#   ./scripts/setup_github.sh
# ============================================================
# Prerequisites:
#   - git installed
#   - gh CLI installed (https://cli.github.com)
#   - gh auth login (authenticated with your GitHub account)
# ============================================================

set -e

REPO_NAME="rice-smart"
GITHUB_USER="nenoteerawat"
DESCRIPTION="AI-powered mobile app to help Thai rice farmers optimize costs and increase yield"

echo "🌾 rice-smart GitHub Setup"
echo "========================="

# Check prerequisites
if ! command -v gh &> /dev/null; then
    echo "❌ gh CLI not found. Install it: https://cli.github.com"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated. Run: gh auth login"
    exit 1
fi

echo "✅ Prerequisites check passed"

# Initialize git if not already done
if [ ! -d ".git" ]; then
    echo "📁 Initializing git repository..."
    git init -b main
    git add -A
    git commit -m "Initial project setup: rice-smart Flutter app with DevSecOps pipeline

- Flutter 3.x project structure with feature-based architecture
- Core features: Disease Detection, Pest Identification, Pasadee Chatbot
- Multi-LLM Gateway (Claude, GPT, Gemini, Typhoon) with failover
- Weather service (TMD API + NASA POWER fallback)
- GitHub Actions CI/CD: lint, test, security scan, build
- Security: Semgrep SAST, Trivy vulnerability scan, TruffleHog secrets
- Envied for secure API key management
- Riverpod state management + GoRouter navigation

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
fi

# Create GitHub repo
echo "🚀 Creating GitHub repository..."
gh repo create "$REPO_NAME" \
    --public \
    --description "$DESCRIPTION" \
    --source . \
    --remote origin \
    --push

echo ""
echo "✅ Done! Your repo is live at:"
echo "   https://github.com/$GITHUB_USER/$REPO_NAME"
echo ""
echo "Next steps:"
echo "   1. flutter pub get"
echo "   2. cp .env.example .env  (add your API keys)"
echo "   3. dart run build_runner build --delete-conflicting-outputs"
echo "   4. flutter run"
