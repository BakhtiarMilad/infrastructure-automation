# 🛰️ infrastructure-automation

[![Terraform Check](https://github.com/DEIN_USERNAME/DEIN_REPO_NAME/actions/workflows/terraform-check.yml/badge.badge.svg)](https://github.com/DEIN_USERNAME/DEIN_REPO_NAME/actions/workflows/terraform-check.yml)
![Checkov Security](https://img.shields.io/badge/Security-Checkov-brightgreen)
![License](https://img.shields.io/badge/License-MIT-blue)

This repository demonstrates a production-grade Automated Infrastructure-as-Code (IaC) workflow. It features a hardened Kubernetes environment with a focus on **Security-by-Design** and **CI/CD Best Practices**.

## Tech Stack
- **Terraform**: Infrastructure provisioning and resource management.
- **Kubernetes**: Container orchestration.
- **GitHub Actions**: Automated CI/CD pipeline for linting and security scans.
- **Checkov**: Static Analysis (SCA) for security compliance.

## Security & Hardening (Shift Left)
This project implements advanced Kubernetes security features to meet Enterprise standards:
- **Immutable Root Filesystem**: Containers run with `read_only_root_filesystem = true`.
- **Non-Root Execution**: All processes run as non-privileged users (UID 101).
- **Resource Management**: Strict CPU/Memory requests and limits to prevent Resource Starvation.
- **Supply Chain Security**: Container images are pinned via **SHA256 digests** to prevent image spoofing.
- **Least Privilege**: GitHub Actions are configured with minimal required `permissions`.

## CI/CD Workflow
The repository uses a **GitOps-inspired Pull Request workflow**:
1. **Linting**: Automated `terraform fmt` and `validate` checks.
2. **Security Scanning**: Every PR is scanned by **Checkov**. Results are integrated directly into the GitHub Security Tab and PR comments.
3. **Branch Protection**: Merging to `main` is blocked unless all security and functional checks pass.

## How to Run
1. Ensure `kind` and `terraform` are installed.
2. Initialize the cluster: 
   ```bash
   kind create cluster --name milad-cluster