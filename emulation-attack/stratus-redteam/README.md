# Stratus Red Team Cloud Attack Emulation

This project sets up a Dockerized environment to perform attack emulation on cloud platforms using **Stratus Red Team**. It supports AWS and GCP, allowing users to execute and analyze attack simulations in a controlled environment.

## Features
- Interactive selection of cloud providers (AWS or GCP).
- Automated setup for AWS CLI, GCP CLI, and Stratus Red Team.
- Supports dynamic attack selection for both AWS and GCP.
- Provides an optional cleanup step to ensure no lingering resources post-attack.

## Prerequisites
1. Docker installed on your machine.
2. AWS and/or GCP sandbox accounts (DO NOT use production accounts).
3. Basic understanding of red team attack emulation and cloud security.

## Getting Started

### Build the Docker Image
To build the Docker image, run:
```bash
docker build -t stratus-cloud-emulator .
```

### Run the Container
Start the container interactively:
```bash
docker run -it --rm stratus-cloud-emulator
```

### Operating the Script
1. The container prompts you to choose between AWS and GCP.
2. Follow the on-screen prompts to configure the cloud CLI tools.
3. Select an attack from the available options and execute it.
4. Optionally clean up the infrastructure created by the emulation.

### Manual Debugging
To manually debug or execute commands:
```bash
docker run -it stratus-cloud-emulator /bin/bash
```

### Example Workflow
#### AWS
- Select AWS as the cloud provider.
- Configure AWS CLI credentials.
- Choose an attack, such as `aws.credential-access.ec2-get-password-data`.
- Observe the attack execution and cleanup if required.

#### GCP
- Select GCP as the cloud provider.
- Authenticate GCP CLI and provide the project ID.
- Choose an attack, such as `gcp.persistence.create-service-account-key`.
- Observe the attack execution and cleanup if required.

## Cleanup
To ensure no infrastructure remains, the container will prompt you to clean up:
```bash
./stratus cleanup --all
```

## Notes
- This project is for educational and testing purposes only.
- Always use sandbox environments and never execute attacks on production systems.

## Contributions
Feel free to fork, modify, and contribute to this project.

---

Happy Hacking!