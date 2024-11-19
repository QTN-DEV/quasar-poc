#!/bin/bash

# Function to clean up Terraform state
cleanup() {
    echo "Cleaning up Terraform files and resources..."
    if [ -f "terraform.tfstate" ]; then
        terraform destroy -auto-approve
    fi
    rm -rf .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup
    echo "Cleanup complete."
}

# Validate prerequisites
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
    echo "Prerequisites validated."
}

# Run Terraform
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
                    -var="audit_logs_sink_name=$AUDIT_LOGS_SINK_NAME" \
                    -var="vpc_flow_logs_sink_name=$VPC_FLOW_LOGS_SINK_NAME" \
                    -var="create_subscription=$CREATE_SUBSCRIPTION" \
                    -auto-approve
    if [ $? -eq 0 ]; then
        echo "Terraform applied successfully."
    else
        echo "Error: Terraform apply failed."
        cleanup
        exit 1
    fi
}

# Trap cleanup on interruption
trap cleanup INT TERM ERR

# Prompt user for inputs
read -p "Enter your GCP Project ID: " PROJECT_ID
read -p "Enter Pub/Sub Topic Name: " TOPIC_NAME
read -p "Enter Cloud Audit Logs Sink Name: " AUDIT_LOGS_SINK_NAME
read -p "Enter VPC Flow Logs Sink Name: " VPC_FLOW_LOGS_SINK_NAME
read -p "Do you want to create a subscription for the topic? (yes/no): " CREATE_SUBSCRIPTION_INPUT

if [[ "$CREATE_SUBSCRIPTION_INPUT" =~ ^(yes|y)$ ]]; then
    CREATE_SUBSCRIPTION=true
else
    CREATE_SUBSCRIPTION=false
fi

read -p "Enter path to your Service Account JSON key: " SERVICE_ACCOUNT_KEY

# Export environment variable for Terraform
export GOOGLE_APPLICATION_CREDENTIALS=$SERVICE_ACCOUNT_KEY

# Validate prerequisites
validate_prerequisites

# Run Terraform
run_terraform
