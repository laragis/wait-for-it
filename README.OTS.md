
# Docker Image: "wait-for-it"

This Docker image is based on the `wait-for-it` tool, which is used to wait for a service to be ready before executing further commands.

## Build the Docker Image

To build the Docker image, run the following command:

```bash
docker build -t wait-for-it .
```

## Run the Docker Container

Once the image is built, you can run the container with:

```bash
docker run -it --rm wait-for-it /bin/bash
```

# Use wait-for-it to wait for the service to be ready before continuing

This will execute the `wait-for-it` script and wait for the specified service to be ready. 

```bash
wait-for-it -s <hostname>:<port> -t <timeout_in_seconds> -- <command_to_execute_after_service_is_ready>
```

For more details and full usage instructions, please refer to the README.md file