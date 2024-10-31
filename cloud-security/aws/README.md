
# AWS S3 Bucket Setup with IAM Role Using Terraform

This guide helps you set up an Amazon S3 bucket with a dedicated IAM role using Terraform, specifically for use with the Wazuh AWS module. We’ll cover each step, from configuring AWS credentials to deploying the resources securely.

## Prerequisites

- **AWS CLI**: Install and configure the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
- **Terraform**: [Install Terraform](https://www.terraform.io/downloads) on your local machine.

## Step 1: Configure AWS Credentials

Run the following command to set up AWS credentials for Terraform (AWS CLI will store these securely on your machine):

```bash
aws configure
```

Provide your AWS Access Key, Secret Access Key, Region, and default Output format.

## Project Structure

Here's the structure of this project:

```plaintext
terraform-project/
├── main.tf              # Main configuration, setting up providers and calling modules
├── variables.tf         # Global variables for the project
├── versions.tf          # Terraform and provider versioning
├── modules/
│   ├── s3_bucket/       # Module to create and manage S3 buckets
│   ├── cloudtrail/      # Module for CloudTrail logging and integration
│   ├── vpcflow/         # Module for VPC Flow Logs configuration
│   ├── cloudtrail/          # Module for AWS Config logs setup
│   ├── guardduty/       # Module for GuardDuty logs
│   └── <other-modules>/ # Additional modules for each supported AWS service
├── environments/
│   ├── production/      # Separate environment configuration
│   └── staging/         # Staging environment configuration
├── outputs.tf           # Outputs for generated resources
└── README.md            # Project documentation
```

## Step 2: Define Variables in `variables.tf`

This file contains customizable options. The important ones include:

- **`region`**: The AWS region where the resources will be created.
- **`bucket_name`**: The name for your S3 bucket.
- **`aws_profile`**: Your AWS CLI profile for authentication.

## Step 3: Initialize and Deploy the Setup

1. **Initialize the project** to download any necessary provider files:
   ```bash
   terraform init
   ```

2. **Apply the configuration** to create your S3 bucket and IAM role:
   ```bash
   terraform apply -var="aws_profile=default" -var="region=us-east-1" -var="bucket_name=<YOUR_BUCKET_NAME>"
   ```
   Replace `<YOUR_BUCKET_NAME>` with a unique name for your bucket.

3. Review the plan output, and enter `yes` to confirm deployment.

## Step 4: Outputs and Next Steps

After deployment, Terraform will provide details on the created resources:

- **Bucket ARN** – The unique identifier for your S3 bucket.
- **IAM Role ARN** – The ARN of the IAM role configured for S3 access.

You can use these details to integrate the bucket and role with other AWS services or applications.

## Additional Tips

- **Using Different AWS Profiles**: Set the `aws_profile` variable in `terraform.tfvars` if you’re using a non-default profile.
- **Environment Variables**: You can also set AWS credentials with environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`).
- **Remote State**: For team projects, consider using a remote backend (e.g., S3) to store the Terraform state.

---

This setup provides a clean, secure foundation for managing AWS S3 and IAM resources with Terraform. For more details on customizing and scaling, check out the `.tf` files in this project!