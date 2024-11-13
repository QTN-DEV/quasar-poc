# GCP Project Setup with Terraform for Wazuh Integration

This guide provides steps to set up a new GCP project with Terraform to enable the Wazuh GCP module for pulling log data from Google Pub/Sub. It configures a Pub/Sub topic, Cloud Logging sink, and service account with the necessary roles.

## Prerequisites

- [Install Terraform](https://www.terraform.io/downloads)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- GCP Organization ID (if creating a new project)

## Configuration Overview

1. **Create a new GCP project**
2. **Set up a service account** with `Pub/Sub Publisher` and `Pub/Sub Subscriber` roles
3. **Create a Pub/Sub topic** and **Cloud Logging Sink**
4. **Enable necessary APIs**

## Setup Instructions

### Step 1: Clone the Repository and Initialize Terraform

1. Clone this repository and navigate to the directory:
   ```bash
   git clone <repo-url>
   cd <repo-directory>
   ```

2. Initialize the Terraform project:
   ```bash
   terraform init
   ```

### Step 2: Configure Variables

In the `variables.tf` file, set your `project_id` and `region` (or pass them via the command line).

### Step 3: Update Organization ID (Optional)

If you’re creating a new GCP project, add your GCP `org_id` in the `main.tf` file under `google_project`.

### Step 4: Run Terraform

Run the following command to create the resources:
```bash
terraform apply -var="project_id=<YOUR_PROJECT_ID>" -var="region=<YOUR_REGION>"
```

### Step 5: Retrieve Outputs

Once the setup is complete, Terraform outputs the following values:

- **Service Account Email** – Used by Wazuh to authenticate
- **Subscription ID** – ID for the Pub/Sub subscription
- **Sink Writer Identity** – Identity for log sink writer

## Terraform Files Overview

### `main.tf`

The main configuration file contains:

- **GCP Project** (optional) and Service Account setup
- IAM roles for `Pub/Sub Publisher` and `Subscriber`
- Pub/Sub topic and subscription
- Cloud Logging sink with Pub/Sub destination

### `variables.tf`

Defines variables for flexibility:
- `project_id` – GCP project ID
- `region` – GCP region

### `outputs.tf`

Outputs for reference, including:
- Service account email
- Subscription ID
- Sink writer identity

## Example Terraform Configuration

Below is a sample setup in `main.tf`:

```hcl
provider "google" {
  project = var.project_id
  region  = var.region
}

# Service Account creation
resource "google_service_account" "wazuh_service_account" {
  account_id   = "wazuh-service-account"
  display_name = "Service Account for Wazuh GCP Integration"
}

# Attach Pub/Sub Roles
resource "google_project_iam_member" "pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.wazuh_service_account.email}"
}

resource "google_project_iam_member" "pubsub_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.wazuh_service_account.email}"
}

# Pub/Sub Topic and Subscription
resource "google_pubsub_topic" "wazuh_topic" {
  name = "wazuh-topic"
}

resource "google_pubsub_subscription" "wazuh_subscription" {
  name  = "wazuh-subscription"
  topic = google_pubsub_topic.wazuh_topic.id
}

# Log Sink with Pub/Sub destination
resource "google_logging_project_sink" "wazuh_sink" {
  name                   = "wazuh-sink"
  destination            = "pubsub.googleapis.com/${google_pubsub_topic.wazuh_topic.id}"
  unique_writer_identity = true
}
```

## API Enablement

To enable necessary APIs, the following code is included:
```hcl
resource "google_project_service" "required_apis" {
  for_each = toset([
    "iam.googleapis.com",
    "compute.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "pubsub.googleapis.com",
    "logging.googleapis.com"
  ])
  project = var.project_id
  service = each.value
}
```

## Cleanup

To delete the resources created by this Terraform configuration:
```bash
terraform destroy -var="project_id=<YOUR_PROJECT_ID>" -var="region=<YOUR_REGION>"
```

## Additional Notes

- **Private Key**: The `google_service_account_key` resource will create a private key in JSON format, downloaded automatically for authentication.
- **IAM Permissions**: Ensure that the IAM roles are sufficient for your needs.

## Troubleshooting

- **API Access Errors**: Ensure that your GCP account has permissions to enable APIs and create IAM roles.
- **Project ID**: If creating the project manually, specify the correct `project_id` in `terraform.tfvars`.

---

This setup automates the integration of Google Cloud Pub/Sub and Logging Sink for use with the Wazuh GCP module.