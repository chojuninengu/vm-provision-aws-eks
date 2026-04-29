# Personal AWS EKS Jumpbox Provisioner

Ansible playbook to set up an Ubuntu 22.04 VM as a secure access point for AWS EC2/EKS.

## Quick Start

Run this single command to automatically install all dependencies and configure your system:

```bash
curl -fsSL https://raw.githubusercontent.com/chojuninengu/vm-provision-aws-eks/main/bootstrap.sh | bash
```

This will:
- Check for and install Ansible if missing
- Download and run the Ansible playbook
- Install AWS CLI, kubectl, k9s
- Configure shell completions for kubectl and k9s
- Set up secure ~/.kube permissions

## Tools Installed
- AWS CLI v2
- kubectl (latest stable)
- k9s (Kubernetes TUI)
- Secure ~/.kube setup (ownership & permissions)

## Manual Usage

### Prerequisites:
- Ansible installed
- Ubuntu 22.04

```bash
# Dry run
sudo ansible-playbook provision.yaml --check

# Apply
sudo ansible-playbook provision.yaml
```
