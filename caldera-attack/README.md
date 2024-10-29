
# CALDERA Docker Setup

This repository provides a Dockerized setup for [CALDERA](https://github.com/mitre/caldera), an open-source adversary emulation platform designed for testing and evaluating security defenses. The setup includes an option to configure the CALDERA `API_BASE_URL` dynamically, making it flexible for deployment across different environments.

## Prerequisites

Ensure you have the following installed on your machine:

- Docker
- Git

## Installation

Follow these steps to clone and build the Dockerized CALDERA setup.

```bash
docker build -t caldera .
```

## Configuration

The `API_BASE_URL` for CALDERA is configurable, allowing you to set it based on the deployment environment. This is useful if you are deploying on a cloud server and want CALDERA to be accessible at a specific domain or IP.

### Setting the `API_BASE_URL`

The `API_BASE_URL` can be set using an environment variable when you run the container. If not specified, it will default to `http://localhost:8888`.

For example, if deploying on an AWS EC2 instance, set `API_BASE_URL` to the public DNS or IP address of the instance:

```bash
docker run -p 8888:8888 -e API_BASE_URL=http://ec2-13-214-134-xx.ap-southeast-1.compute.amazonaws.com:8888 caldera
```

This command will replace the `app.frontend.api_base_url` in `conf/default.yml` to make the CALDERA web interface accessible from the specified URL.

## Usage

Once the container is running, access the CALDERA web interface by navigating to the URL defined in `API_BASE_URL` (or `http://localhost:8888` if no custom URL was specified).

### Default Command to Run CALDERA

```bash
docker run -p 8888:8888 caldera
```

### Customizing the API Base URL

To run CALDERA with a custom API base URL, specify the `API_BASE_URL` environment variable:

```bash
docker run -p 8888:8888 -e API_BASE_URL=http://your-domain-or-ip:8888 caldera
```

### Example URLs

- **Local Development**: `http://localhost:8888`
- **AWS EC2**: `http://ec2-13-214-134-36.ap-southeast-1.compute.amazonaws.com:8888`

## Environment Variables

| Variable       | Description                                                   | Default              |
|----------------|---------------------------------------------------------------|----------------------|
| `API_BASE_URL` | The base URL for accessing CALDERA’s API and web interface    | `http://localhost:8888` |

## Troubleshooting

If you encounter issues, try the following:

1. **Ensure Docker is Running**: Make sure Docker is installed and running on your machine.
2. **Verify the URL**: If the web interface is not accessible, confirm that `API_BASE_URL` is set correctly.
3. **Check Container Logs**: Use `docker logs <container_id>` to view CALDERA logs for debugging.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request with improvements.

## License

This repository is licensed under the [MIT License](LICENSE).