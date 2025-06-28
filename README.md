# URL Shortener - AWS, Terraform, EKS, Node.js

URL shortener service deployed on **AWS** using **Terraform**, **EKS (Kubernetes)**, **Helm**, and a **MySQL RDS backend**. Built with **Node.js** and **Docker**.

## Architecture Overview

- **Infrastructure**: Provisioned via Terraform (VPC, EKS, RDS, WAF, ALB)
- **App**: Node.js Express app with JWT authentication
- **CI/CD**: GitHub Actions automates builds and deploys to EKS via Helm
- **Container**: Dockerized app deployed via Helm chart
- **Persistence**: MySQL (AWS RDS)
- **Security**: WAF + Rate limiting + JWT + Secret management

# Folder Structure

├── app/ # Node.js application
├── chart/ # Helm chart for K8s deployment
├── terraform/ # Terraform AWS infrastructure
│ └── environments/ # Separate tfvars for dev/staging/prod
├── .github/workflows/ # GitHub Actions CI/CD
├── scripts/ # Helper scripts (Helm init, etc.)
└── README.md # This file


## Features

-  JWT-based API authentication (`/shorten`)
-  URL redirect endpoint (`/:short`)
-  Helm-deployed containerized service on EKS
-  Autoscaling and monitoring
-  AWS WAF for malicious traffic
-  GitHub Actions CI/CD for infra and app
-  Supports multi-env via `terraform workspace`

---

##  Setup Instructions

###  Clone and configure

```bash
git clone https://github.com/your-org/url-shortener.git
cd url-shortener
cp app/.env.example app/.env

cd terraform
terraform init
terraform workspace new dev
terraform apply -var-file="environments/dev.tfvars"

