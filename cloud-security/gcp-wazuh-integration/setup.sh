#!/bin/bash

# Function to clean up Terraform resources and generated files
cleanup() {
    echo "Cleaning up Terraform files and resources..."
    # Destroy Terraform resources if applicable
    if [ -f "terraform.tfstate" ]; then
        terraform destroy -var="project_id=$PROJECT_ID" \
                          -var="topic_name=$TOPIC_NAME" \
                          -var="sink_name=$SINK_NAME" \
                          -auto-approve
    fi

    # Remove generated Terraform files
    rm -rf .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup

    echo "Cleanup complete. Environment reset to initial state."
}

# Function to validate prerequisites
validate_prerequisites() {
    echo "Validating prerequisites..."
    if ! command -v gcloud &>/dev/null; then
        echo "Error: gcloud CLI is not installed. Please install it and authenticate."
        exit 1
    fi

    if [ ! -f "$SERVICE_ACCOUNT_KEY" ]; then
        echo "Error: Service account key file not found at $SERVICE_ACCOUNT_KEY."
        exit 1
    fi

    echo "Prerequisites validated successfully."
}

# Function to perform Terraform setup
run_terraform() {
    echo "Initializing Terraform..."
    terraform init -reconfigure
    if [ $? -ne 0 ]; then
        echo "Error: Terraform initialization failed."
        cleanup
        exit 1
    fi

    echo "Applying Terraform configuration..."
    terraform apply -var="project_id=$PROJECT_ID" \
                    -var="topic_name=$TOPIC_NAME" \
                    -var="sink_name=$SINK_NAME" \
                    -auto-approve
    if [ $? -eq 0 ]; then
        echo "Terraform applied successfully!"
    else
        echo "Error: Terraform apply failed."
        cleanup
        exit 1
    fi
}

# Trap interruptions and call cleanup
trap cleanup INT TERM ERR

# Prompt user for inputs
read -p "Enter your GCP Project ID: " PROJECT_ID
read -p "Enter Pub/Sub Topic Name: " TOPIC_NAME
read -p "Enter Log Sink Name: " SINK_NAME
read -p "Enter path to your Service Account JSON key: " SERVICE_ACCOUNT_KEY

# Export environment variable for Terraform
export GOOGLE_APPLICATION_CREDENTIALS=$SERVICE_ACCOUNT_KEY

# Validate prerequisites
validate_prerequisites

# Run Terraform
run_terraform