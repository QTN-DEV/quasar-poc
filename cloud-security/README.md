# Cloud Security Infrastructure with Terraform

This project automates the configuration of security services across multiple cloud providers, using Terraform to set up and manage infrastructure components securely and consistently. Currently, it includes modules for **AWS** and **GCP** cloud providers, focusing on logging and monitoring services that integrate with **Wazuh** for enhanced security management.

## Project Structure

The repository is organized by cloud providers, with each provider containing separate modules for specific services, as well as environment-specific configurations.

```
cloud-security/
├── README.md                  # General project documentation
├── aws/                       # AWS-specific infrastructure configurations
│   ├── README.md              # AWS-specific documentation
│   ├── environments/          # Separate directories for each environment (e.g., dev, production)
│   ├── main.tf                # Main file for calling AWS modules
│   ├── modules/               # AWS service modules (e.g., CloudTrail, VPC Flow Logs)
│   ├── output.tf              # Outputs for AWS
│   ├── terraform.tfvars       # Variable values for AWS configurations
│   ├── variables.tf           # Variable definitions for AWS
│   └── versions.tf            # Terraform and provider version management
└── gcp/                       # GCP-specific infrastructure configurations
    ├── README.md              # GCP-specific documentation
    ├── main.tf                # Main file for GCP resource configurations
    ├── outputs.tf             # Outputs for GCP
    ├── terraform.tfvars       # Variable values for GCP configurations
    └── variables.tf           # Variable definitions for GCP
```

### AWS Modules

Each AWS service is configured in a dedicated module for modularity and ease of management:

- **CloudTrail**: Collects and stores logs for API activity within AWS.
- **VPC Flow Logs**: Captures and stores IP traffic data for VPCs, subnets, and network interfaces.

Each module is reusable, with environment-specific configurations set in the `environments` directory (e.g., `dev`, `production`, `staging`). This allows for consistent deployment across multiple environments while maintaining flexibility.

### GCP Configuration

The GCP folder contains Terraform scripts to configure logging and monitoring services for integration with Wazuh, similar to AWS. These configurations are also separated by environment to provide a scalable setup for development, testing, and production.

## Getting Started

### Prerequisites

1. **Terraform**: Install [Terraform](https://www.terraform.io/downloads) on your local machine.
2. **AWS CLI**: Install and configure the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
3. **GCP SDK**: Install and configure the [Google Cloud SDK](https://cloud.google.com/sdk/docs/install).

### Quick Start

1. **Clone the repository**:
   ```bash
   git clone <repo-url>
   cd cloud-security
   ```

2. **Configure Provider-Specific Authentication**:
   - **AWS**: Run `aws configure` to set up access credentials.
   - **GCP**: Run `gcloud auth application-default login` to set up GCP authentication.

3. **Set Up Environment-Specific Variables**:
   - Modify `terraform.tfvars` within each environment folder (e.g., `aws/environments/dev/terraform.tfvars`) to customize variables for your environment.

4. **Initialize Terraform**:
   ```bash
   terraform init
   ```

5. **Deploy the Infrastructure**:
   - From the provider-specific directory (`aws/` or `gcp/`), select the desired environment and run:
     ```bash
     terraform apply -var-file="environments/<environment>/terraform.tfvars"
     ```
     Replace `<environment>` with `dev`, `staging`, or `production`.

6. **Review and Confirm**: Terraform will display a plan of resources it will create. Type `yes` to apply the changes and deploy the infrastructure.

## Environment Configuration

Each environment (e.g., dev, staging, production) has its own configuration files to ensure isolation and ease of management. Use `terraform.tfvars` files within each environment directory to define environment-specific settings, such as:

- **AWS**: S3 bucket names, VPC IDs, and other resource-specific identifiers.
- **GCP**: Project IDs, logging configuration, and region settings.

## Outputs

After deploying, Terraform will output key resource identifiers, such as:

- **AWS S3 Bucket ARN**: For centralized logging storage.
- **IAM Policy ARNs**: To control permissions and access securely.
- **GCP Logging Configurations**: Integration points for monitoring services.

Use these outputs to integrate the resources with Wazuh or other security monitoring tools.

## Additional Notes

- **Environment Isolation**: Each environment’s configuration is isolated, allowing teams to deploy resources safely without impacting production.
- **Modularity**: Each service (CloudTrail, VPC Flow Logs, etc.) is encapsulated in its own module, making it easy to expand or modify without affecting other configurations.
- **Scalability**: The structure supports multiple cloud environments and providers, allowing for straightforward scaling to new environments or services.

## Troubleshooting

- **Authentication Errors**: Ensure that AWS and GCP credentials are correctly configured in their respective CLI tools.
- **Permission Issues**: Check IAM policies to ensure sufficient permissions for creating and managing resources.

---

This project provides a secure and scalable foundation for managing cloud security infrastructure, with reusable modules and consistent environment configurations, making it suitable for production deployments.