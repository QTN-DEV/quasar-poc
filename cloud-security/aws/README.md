# AWS Project Setup with Terraform for Wazuh Integration

> For this PoC I want to: 
> - Create a guideline that Monitors All Supported service in Wazuh
> - Create a Terraform automated resource sript for each service/all

This project automates the creation of an Amazon S3 bucket, specifically configured for use with the Wazuh AWS module to store logs from supported AWS services.

The project follows Terraform best practices, including clear project organization, remote state management, and environment-based configurations to enhance scalability, security, and ease of maintenance.

## Project Structure

- **main.tf** - Defines the AWS provider.
- **s3_bucket.tf** - Contains the S3 bucket and related IAM policies.
- **variables.tf** - Defines variables for flexibility and scalability.
- **outputs.tf** - Captures and outputs useful information like bucket ARN.
- **versions.tf** - Locks Terraform and provider versions for consistency.

## Configuration Steps

1. Clone the repository and navigate to the project directory.
   ```bash
   git clone <repo-url>
   cd <project-directory>
   ```

2. Update `terraform.tfvars` with values specific to your environment.

3. Initialize the project and apply the configuration.
   ```bash
   terraform init
   terraform apply -var="bucket_name=<YOUR_BUCKET_NAME>"
   ```

## Key Best Practices

- **Version Control & GitOps**: Treat infrastructure code as application code, using version control for changes.
- **Environment Isolation**: Organize configurations by environment (e.g., `prod`, `staging`) for isolated testing and management.
- **Remote State**: Use a remote backend (e.g., S3) for storing Terraform state, ensuring data consistency and security.
- **Tagging & Naming Conventions**: Apply consistent naming and tagging strategies to track resource usage effectively.
- **Reusable Modules**: Encapsulate reusable configurations in separate modules for flexibility across projects.
- **Testing & Validation**: Run `terraform validate` and `terraform plan` regularly, with CI/CD pipelines to automate formatting and validation.

## Requirements

- **Terraform** version 1.3.0 or higher
- **AWS CLI** configured for your account

## Outputs

- **Bucket ARN** - Amazon Resource Name for the created S3 bucket.
- **Bucket Name** - Name of the created S3 bucket.

For further customization and detailed explanations, refer to individual `.tf` files in the project.

---

This setup provides a robust foundation for managing AWS S3 bucket infrastructure with Terraform, enabling automated, repeatable deployments.