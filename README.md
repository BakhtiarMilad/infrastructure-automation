# infrastructure-automation

This repository demonstrates an automated Infrastructure-as-Code (IaC) workflow designed for a scalable Kubernetes environment, inspired by the requirements of satellite data processing systems.

## Tech Stack
- **Terraform**: Infrastructure provisioning and resource management.
- **Kubernetes (kind)**: Local cluster orchestration.
- **Docker**: Container runtime for node simulation.

## Key Features
- **Automated Deployment**: Full lifecycle management of a Kubernetes deployment using HCL.
- **Configuration Management**: Externalized settings via **Kubernetes ConfigMaps**, simulating satellite sensor configurations.
- **Scalability**: Parameterized replica counts for high-availability testing.
- **Decoupling**: Strict separation of infrastructure code, environment variables, and application configuration.

## How to Run
1. Ensure `kind` and `terraform` are installed.
2. Initialize the cluster: `kind create cluster --name milad-cluster`
3. Deploy the infrastructure:
   ```bash
   terraform init
   terraform apply -var="replica_count=3"
