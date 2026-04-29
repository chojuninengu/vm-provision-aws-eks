#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
fail() { echo -e "${RED}[-]${NC} $1"; exit 1; }

[[ $EUID -eq 0 ]] && fail "Do not run as root. Run as a normal user with sudo access."

command -v curl >/dev/null 2>&1 || { warn "curl not found, installing..."; sudo apt-get update && sudo apt-get install -y curl; }

PLAYBOOK_URL='https://raw.githubusercontent.com/ju-nine/vm-provision-aws-eks/main/provision.yaml'
INVENTORY_URL='https://raw.githubusercontent.com/ju-nine/vm-provision-aws-eks/main/inventory/localhost.yml'

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

log "Working in $WORK_DIR"
cd "$WORK_DIR"

log "Checking dependencies..."

if ! command -v ansible >/dev/null 2>&1; then
    warn "Ansible not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y ansible python3-pip
fi

log "Downloading playbook and inventory..."
curl -fsSL "$PLAYBOOK_URL" -o provision.yaml
curl -fsSL "$INVENTORY_URL" -o inventory.yml

log "Running Ansible playbook..."
ansible-playbook -i inventory.yml provision.yaml

log "Configuring shell for kubectl and k9s..."

SHELL_CONFIG=""
if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [[ -n "${BASH_VERSION:-}" ]] || [[ "$SHELL" == *"bash"* ]]; then
    SHELL_CONFIG="$HOME/.bashrc"
fi

if [[ -n "$SHELL_CONFIG" ]]; then
    if ! grep -q 'kubectl completion' "$SHELL_CONFIG" 2>/dev/null; then
        {
            echo ''
            echo '# kubectl completion'
            echo 'source <(kubectl completion bash 2>/dev/null || kubectl completion zsh 2>/dev/null)'
            echo 'alias k=kubectl'
            echo 'complete -o default -F __start_kubectl k 2>/dev/null || true'
        } >> "$SHELL_CONFIG"
    fi

    if ! grep -q 'k9s' "$SHELL_CONFIG" 2>/dev/null; then
        {
            echo ''
            echo '# k9s'
            echo 'alias k9=k9s'
        } >> "$SHELL_CONFIG"
    fi

    # shellcheck disable=SC1090
    source "$SHELL_CONFIG" 2>/dev/null || true
    log "Shell configuration updated: $SHELL_CONFIG"
fi

log "Setup complete!"
echo ""
echo "Tools installed:"
echo "  - AWS CLI:    $(aws --version 2>/dev/null || echo 'not found')"
echo "  - kubectl:    $(kubectl version --client 2>/dev/null | head -1 || echo 'not found')"
echo "  - k9s:        $(k9s version --short 2>/dev/null || echo 'not found')"
echo ""
echo "Run 'source $SHELL_CONFIG' or restart your shell to load completions."
