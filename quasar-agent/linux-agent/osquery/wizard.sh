#!/bin/bash

# Function to rebuild the Docker image with OSQUERY_KEY as a build argument
rebuild_docker_image() {
    read -p "Please provide the path to the Dockerfile directory: " DOCKERFILE_PATH
    read -p "Please enter the name for the Docker image: " DOCKER_IMAGE
    read -p "Please enter the OSQUERY_KEY (leave blank to skip): " OSQUERY_KEY

    # Check if OSQUERY_KEY is provided
    if [ -n "$OSQUERY_KEY" ]; then
        docker build -t $DOCKER_IMAGE --build-arg OSQUERY_KEY="$OSQUERY_KEY" $DOCKERFILE_PATH
    else
        docker build -t $DOCKER_IMAGE $DOCKERFILE_PATH
    fi

    if [ $? -eq 0 ]; then
        echo "Docker image '$DOCKER_IMAGE' rebuilt successfully."
    else
        echo "Failed to rebuild Docker image."
    fi
}

# Function to list Docker images
list_docker_images() {
    docker images
    if [ $? -eq 0 ]; then
        echo "Docker images listed successfully."
    else
        echo "Failed to list Docker images."
    fi
}

# Function to remove a Docker image
remove_docker_image() {
    read -p "Please enter the name or ID of the Docker image to remove: " IMAGE_NAME
    docker rmi $IMAGE_NAME
    if [ $? -eq 0 ]; then
        echo "Docker image '$IMAGE_NAME' removed successfully."
    else
        echo "Failed to remove Docker image."
    fi
}

# Function to list running Docker containers
list_running_containers() {
    docker ps
    if [ $? -eq 0 ]; then
        echo "Running Docker containers listed successfully."
    else
        echo "Failed to list running Docker containers."
    fi
}

# Function to list all Docker containers (including stopped ones)
list_all_containers() {
    docker ps -a
    if [ $? -eq 0 ]; then
        echo "All Docker containers listed successfully."
    else
        echo "Failed to list Docker containers."
    fi
}

# Function to start a stopped container
start_docker_container() {
    read -p "Please enter the name or ID of the container to start: " CONTAINER_NAME
    docker start $CONTAINER_NAME
    if [ $? -eq 0 ]; then
        echo "Docker container '$CONTAINER_NAME' started successfully."
    else
        echo "Failed to start the Docker container."
    fi
}

# Function to stop a running container
stop_docker_container() {
    read -p "Please enter the name or ID of the container to stop: " CONTAINER_NAME
    docker stop $CONTAINER_NAME
    if [ $? -eq 0 ]; then
        echo "Docker container '$CONTAINER_NAME' stopped successfully."
    else
        echo "Failed to stop the Docker container."
    fi
}

# Function to restart a container
restart_docker_container() {
    read -p "Please enter the name or ID of the container to restart: " CONTAINER_NAME
    docker restart $CONTAINER_NAME
    if [ $? -eq 0 ]; then
        echo "Docker container '$CONTAINER_NAME' restarted successfully."
    else
        echo "Failed to restart the Docker container."
    fi
}

# Function to remove a container
remove_docker_container() {
    read -p "Please enter the name or ID of the container to remove: " CONTAINER_NAME
    docker rm $CONTAINER_NAME
    if [ $? -eq 0 ]; then
        echo "Docker container '$CONTAINER_NAME' removed successfully."
    else
        echo "Failed to remove the Docker container."
    fi
}

# Function to execute a command inside a running container
exec_docker_container() {
    read -p "Please enter the name or ID of the running container: " CONTAINER_NAME
    read -p "Please enter the command you want to execute inside the container: " COMMAND
    docker exec -it $CONTAINER_NAME $COMMAND
    if [ $? -eq 0 ]; then
        echo "Command executed inside the container successfully."
    else
        echo "Failed to execute the command inside the container."
    fi
}

# Function to run Docker container with Osquery
run_docker_container_osquery() {
    read -p "Please enter the name for the Docker image (e.g., osquery-image): " DOCKER_IMAGE

    verify_docker_image

    # Run the Osquery container
    echo "Running Osquery container..."
    DOCKER_CMD="docker run -d --name osquery-container $DOCKER_IMAGE"
    eval $DOCKER_CMD

    if [ $? -eq 0 ]; then
        echo "Docker container ran successfully with Osquery."
    else
        echo "Failed to run Docker container."
    fi
}

# Function to verify if a Docker image exists
verify_docker_image() {
    if [[ -z "$(docker images -q $DOCKER_IMAGE)" ]]; then
        echo "Error: Docker image '$DOCKER_IMAGE' not found."
        read -p "Do you want to build the image now? (y/n): " BUILD_IMAGE
        if [[ "$BUILD_IMAGE" == "y" || "$BUILD_IMAGE" == "Y" ]]; then
            rebuild_docker_image
        else
            echo "Please build the Docker image manually and run this script again."
            exit 1
        fi
    fi
}

# Function to show Docker image operations menu
show_docker_image_menu() {
    echo "--------------------------------------------"
    echo " Docker Image Operations"
    echo "--------------------------------------------"
    echo "1. List Docker images"
    echo "2. Remove Docker image"
    echo "3. Go back to main menu"
    echo "--------------------------------------------"
}

# Function to show Docker container operations menu
show_docker_container_menu() {
    echo "--------------------------------------------"
    echo " Docker Container Operations"
    echo "--------------------------------------------"
    echo "1. List running Docker containers"
    echo "2. List all Docker containers"
    echo "3. Start a Docker container"
    echo "4. Stop a Docker container"
    echo "5. Restart a Docker container"
    echo "6. Remove a Docker container"
    echo "7. Execute a command in a running container"
    echo "8. Go back to main menu"
    echo "--------------------------------------------"
}

# Function to show Osquery operations menu
show_osquery_menu() {
    echo "--------------------------------------------"
    echo " Osquery Operations"
    echo "--------------------------------------------"
    echo "1. Run Osquery"
    echo "2. Check Osquery logs"
    echo "3. Go back to main menu"
    echo "--------------------------------------------"
}

# Function to show the main menu
show_main_menu() {
    echo "--------------------------------------------"
    echo " Main Menu"
    echo "--------------------------------------------"
    echo "1. Docker Image Operations"
    echo "2. Docker Container Operations"
    echo "3. Osquery Operations"
    echo "4. Exit"
    echo "--------------------------------------------"
}

# Function to check Osquery logs
check_osquery_logs() {
    echo "Displaying Osquery logs..."
    docker logs osquery-container
}

# Main logic to display nested menus and handle user input
while true; do
    show_main_menu
    read -p "Please select an operation (1-4): " MAIN_CHOICE
    case $MAIN_CHOICE in
        1)
            while true; do
                show_docker_image_menu
                read -p "Select Docker Image Operation (1-3): " IMAGE_CHOICE
                case $IMAGE_CHOICE in
                    1) list_docker_images ;;
                    2) remove_docker_image ;;
                    3) break ;;
                    *) echo "Invalid option. Please choose between 1 and 3." ;;
                esac
            done
            ;;
        2)
            while true; do
                show_docker_container_menu
                read -p "Select Docker Container Operation (1-8): " CONTAINER_CHOICE
                case $CONTAINER_CHOICE in
                    1) list_running_containers ;;
                    2) list_all_containers ;;
                    3) start_docker_container ;;
                    4) stop_docker_container ;;
                    5) restart_docker_container ;;
                    6) remove_docker_container ;;
                    7) exec_docker_container ;;
                    8) break ;;
                    *) echo "Invalid option. Please choose between 1 and 8." ;;
                esac
            done
            ;;
        3)
            while true; do
                show_osquery_menu
                read -p "Select Osquery Operation (1-3): " OSQUERY_CHOICE
                case $OSQUERY_CHOICE in
                    1) run_docker_container_osquery ;;
                    2) check_osquery_logs ;;
                    3) break ;;
                    *) echo "Invalid option. Please choose between 1 and 3." ;;
                esac
            done
            ;;
        4)
            echo "Exiting the wizard."
            exit 0
            ;;
        *)
            echo "Invalid option. Please choose between 1 and 4."
            ;;
    esac
done