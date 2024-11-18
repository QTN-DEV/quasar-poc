#!/bin/bash

# Function to perform cleanup in case of interruption or on demand
cleanup() {
    echo "Starting cleanup..."
    terraform destroy -var="bucket_name=$WAZUH_AWS_BUCKET" -auto-approve
    echo "Terraform resources have been destroyed."

    # Remove Terraform-generated files
    echo "Cleaning up Terraform files..."
    rm -rf .terraform .terraform.lock.hcl

    echo "Cleanup complete: All generated files and configurations have been removed."
}

# Trap any interruption to trigger cleanup
trap cleanup INT TERM ERR

# Step 1: Determine Environment
echo "Is Wazuh installed on the host or inside Docker containers?"
echo "1. Host"
echo "2. Docker container"
read -p "Select an option (1 or 2): " install_location
sleep 1

# Prompt for Docker container names if using containers
if [[ "$install_location" == "2" ]]; then
    read -p "Enter the Wazuh manager container name: " manager_container
    read -p "Enter the Wazuh worker container name: " worker_container
fi

# Step 2: Dependency Check
echo "Checking dependencies..."
sleep 2
if [[ "$install_location" == "1" ]]; then
    # Install dependencies on the host
    sudo apt-get update && sudo apt-get install -y python3 python3-pip
    pip3 install --upgrade pip --break-system-packages
    pip3 install --break-system-packages boto3==1.34.135 pyarrow==14.0.1 numpy==1.26.0
else
    # Install dependencies inside Wazuh containers using Amazon Linux's package manager (dnf)
    docker exec -it $manager_container dnf install -y python3 python3-pip
    docker exec -it $manager_container pip3 install boto3==1.34.135 pyarrow==14.0.1 numpy==1.26.0

    docker exec -it $worker_container dnf install -y python3 python3-pip
    docker exec -it $worker_container pip3 install boto3==1.34.135 pyarrow==14.0.1 numpy==1.26.0
fi

echo "Dependencies installed."
sleep 2

# Step 3: S3 Bucket Selection
echo "Do you want to use an existing S3 bucket for logs, or create a new one?"
echo "1. Use existing S3 bucket"
echo "2. Create new S3 bucket"
read -p "Select an option (1 or 2): " bucket_choice
sleep 1

# If creating a new bucket
if [[ "$bucket_choice" == "2" ]]; then
    read -p "Enter a unique name for the new S3 bucket: " new_bucket_name
    export WAZUH_AWS_BUCKET=$new_bucket_name
else
    read -p "Enter the name of your existing S3 bucket: " existing_bucket_name
    export WAZUH_AWS_BUCKET=$existing_bucket_name
fi

# Step 4: IAM Setup Manual Steps
echo "If you don't have IAM credentials, please follow these steps in AWS Console:"
echo "1. Create an IAM user group."
echo "2. Create an IAM user, add it to the user group, and create access keys."
echo "3. Save the access keys for the next step."
sleep 5

# Step 5: Configure AWS Credentials
echo "Setting up AWS credentials..."
aws configure --profile wazuh-profile

# Step 6: Copy AWS Credentials to Wazuh Container (if applicable)
if [[ "$install_location" == "2" ]]; then
    # Ensure AWS credentials are mounted for the container, typically by copying .aws/credentials file
    echo "Mounting AWS credentials for Wazuh containers..."

    # Copy AWS credentials directly to the existing containers
    docker cp ~/.aws/credentials $manager_container:/root/.aws/credentials
    docker cp ~/.aws/credentials $worker_container:/root/.aws/credentials
fi

# Step 7: Start Terraform to Create Resources
echo "Initializing Terraform..."
terraform init -reconfigure
if [ $? -ne 0 ]; then
    echo "Error: Terraform initialization failed."
    exit 1
fi

echo "Starting Terraform to set up AWS CloudTrail, VPC Flow Logs, and IAM Role for Flow Logs..."
sleep 2
terraform apply -var="bucket_name=$WAZUH_AWS_BUCKET" -auto-approve

echo "Setup complete! AWS CloudTrail and VPC Flow Logs are now configured with Wazuh."

# Prompt to perform cleanup if needed
read -p "Do you want to clean up all resources and generated files? (y/n): " cleanup_choice
if [[ "$cleanup_choice" == "y" ]]; then
    cleanup
fi