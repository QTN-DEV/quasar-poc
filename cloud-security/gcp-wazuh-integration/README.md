
# GCP Pub/Sub and Log Sink Setup with Terraform

This repository contains a Terraform configuration and a setup script to configure Google Cloud Pub/Sub and a Logging Sink to integrate with Wazuh.

---

## **Overview**

This setup script and Terraform configuration will:
1. Create a Pub/Sub topic and subscription.
2. Configure a logging sink to route logs to the Pub/Sub topic.

---

## **Prerequisites**

Before running the script, ensure the following:
1. **Google Cloud SDK (`gcloud`) is installed and authenticated**:
   - Install the SDK: https://cloud.google.com/sdk/docs/install
   - Authenticate with your GCP account:
     ```bash
     gcloud auth login
     ```
2. **Enable required APIs in your GCP project**:
   - Cloud Pub/Sub API
   - Cloud Logging API
   ```bash
   gcloud services enable pubsub.googleapis.com logging.googleapis.com
   ```

3. **Create a service account with the required roles**:
   - Roles:
     - Pub/Sub Admin
     - Logging Admin
   - Download the JSON private key for the service account.

4. **Prepare the following inputs**:
   - GCP Project ID
   - Pub/Sub Topic Name
   - Log Sink Name
   - Path to the service account JSON key

---

## **Usage**

### **Step 1**: Clone this repository
```bash
git clone https://github.com/example/gcp-wazuh-integration.git
cd gcp-wazuh-integration
```

### **Step 2**: Run the setup script
```bash
./setup.sh
```

### **Step 3**: Follow the prompts
The script will ask for the following:
- GCP Project ID
- Pub/Sub Topic Name
- Log Sink Name
- Path to your service account JSON key

#### Example Output
```plaintext
Enter your GCP Project ID: my-gcp-project-id
Enter Pub/Sub Topic Name: wazuh-topic
Enter Log Sink Name: wazuh-sink
Enter path to your Service Account JSON key: ./my-service-account-key.json

Validating prerequisites...
Prerequisites validated successfully.

Initializing Terraform...
Terraform initialized successfully.

Applying Terraform configuration...
Terraform applied successfully!

Outputs:
topic_name = "wazuh-topic"
subscription_id = "wazuh-topic-subscription"
sink_name = "wazuh-sink"
```

### **Step 4**: Verify Resources in GCP
- Navigate to **Pub/Sub** in the GCP Console to confirm the topic and subscription.
- Check **Log Router** to confirm the logging sink.

---

## **Cleaning Up**

To remove all resources, run:
```bash
terraform destroy -auto-approve
rm -rf .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup
```

---

## **Troubleshooting**

### Common Errors
1. **Missing permissions**:
   - Ensure the service account has the `Pub/Sub Admin` and `Logging Admin` roles.

2. **API not enabled**:
   - Run the following to enable required APIs:
     ```bash
     gcloud services enable pubsub.googleapis.com logging.googleapis.com
     ```

3. **Invalid destination error**:
   - Ensure the sink destination is in the format:
     ```
     pubsub.googleapis.com/projects/[PROJECT_ID]/topics/[TOPIC_NAME]
     ```

For additional help, open an issue or contact support.

---
