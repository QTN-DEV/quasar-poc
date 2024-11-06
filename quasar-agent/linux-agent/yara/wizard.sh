#!/bin/bash

# Function to rebuild the Docker image
rebuild_docker_image() {
    read -p "Please provide the path to the Dockerfile directory: " DOCKERFILE_PATH
    read -p "Please enter the name for the Docker image: " DOCKER_IMAGE
    docker build -t $DOCKER_IMAGE $DOCKERFILE_PATH
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

# Function to run Docker container with Wazuh and YARA
run_docker_container_yara() {
    read -p "Please enter the Wazuh Manager IP: " WAZUH_MANAGER
    if [[ -z "$WAZUH_MANAGER" ]]; then
        echo "Error: Wazuh Manager IP cannot be empty."
        exit 1
    fi

    read -p "Please enter the Wazuh Agent Name: " WAZUH_AGENT_NAME
    if [[ -z "$WAZUH_AGENT_NAME" ]]; then
        echo "Error: Wazuh Agent Name cannot be empty."
        exit 1
    fi

    read -p "Do you want to include YARA in this setup? (y/n): " INSTALL_YARA

    DOCKER_IMAGE="your_docker_image_yara"

    verify_docker_image

    DOCKER_CMD="docker run -e WAZUH_MANAGER=$WAZUH_MANAGER -e WAZUH_AGENT_NAME=$WAZUH_AGENT_NAME $DOCKER_IMAGE"

    if [[ "$INSTALL_YARA" == "y" || "$INSTALL_YARA" == "Y" ]]; then
        DOCKER_CMD="$DOCKER_CMD -e INSTALL_YARA=true"
    fi

    echo "The following Docker command will be executed:"
    echo "$DOCKER_CMD"

    read -p "Do you want to proceed? (y/n): " CONFIRM
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        eval $DOCKER_CMD
        if [ $? -eq 0 ]; then
            echo "Docker container ran successfully with YARA and Wazuh."
        else
            echo "Failed to run Docker container."
        fi
    else
        echo "Operation cancelled by the user."
    fi
}

# Function to verify if a Docker image exists
verify_docker_image() {
    if [[ "$DOCKER_IMAGE" == "your_docker_image" ]]; then
        echo "Error: 'your_docker_image' is still a placeholder."
        read -p "Please enter the actual Docker image name (e.g., wazuh-yara-image): " DOCKER_IMAGE
    fi

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

# Function to show Wazuh operations menu
show_wazuh_menu() {
    echo "--------------------------------------------"
    echo " Wazuh Operations"
    echo "--------------------------------------------"
    echo "1. Run Wazuh only"
    echo "2. Run Wazuh with Suricata"
    echo "3. Run Wazuh with YARA"
    echo "4. Go back to main menu"
    echo "--------------------------------------------"
}

# Function to show the main menu
show_main_menu() {
    echo "--------------------------------------------"
    echo " Main Menu"
    echo "--------------------------------------------"
    echo "1. Docker Image Operations"
    echo "2. Docker Container Operations"
    echo "3. Wazuh Operations"
    echo "4. Exit"
    echo "--------------------------------------------"
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
                show_wazuh_menu
                read -p "Select Wazuh Operation (1-4): " WAZUH_CHOICE
                case $WAZUH_CHOICE in
                    1) run_docker_container "wazuh" ;;
                    2) run_docker_container "wazuh_suricata" ;;
                    3) run_docker_container_yara ;;
                    4) break ;;
                    *) echo "Invalid option. Please choose between 1 and 4." ;;
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