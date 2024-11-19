#!/bin/bash

# Function to configure AWS
configure_aws() {
  echo "Configuring AWS..."
  sudo /usr/local/bin/aws configure
  export AWS_PROFILE=default
  export AWS_REGION=$(aws configure get region)
}

# Function to configure GCP
configure_gcp() {
  echo "Configuring GCP..."
  gcloud auth application-default login
  echo "Enter GCP Project ID:"
  read GCP_PROJECT_ID
  export GOOGLE_PROJECT=$GCP_PROJECT_ID
}

# List available attacks for AWS or GCP
list_attacks() {
  if [[ $1 == "aws" ]]; then
    stratus list | grep 'aws.'
  elif [[ $1 == "gcp" ]]; then
    stratus list | grep 'gcp.'
  else
    echo "Unknown provider!"
  fi
}

# Execute selected attack
execute_attack() {
  echo "Enter the attack identifier (e.g., aws.credential-access.ec2-get-password-data):"
  read ATTACK_ID
  stratus warmup $ATTACK_ID
  stratus detonate $ATTACK_ID
}

# Ask the user for the cloud provider
echo "Select cloud provider (aws/gcp):"
read PROVIDER

case $PROVIDER in
  aws)
    configure_aws
    echo "Available AWS attacks:"
    list_attacks aws
    ;;
  gcp)
    configure_gcp
    echo "Available GCP attacks:"
    list_attacks gcp
    ;;
  *)
    echo "Invalid selection! Exiting..."
    exit 1
    ;;
esac

# Ask for the attack type and execute
execute_attack

# Clean up infrastructure
echo "Do you want to clean up the infrastructure created? (yes/no):"
read CLEANUP
if [[ $CLEANUP == "yes" ]]; then
  stratus cleanup --all
fi