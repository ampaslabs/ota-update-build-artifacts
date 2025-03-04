#!/bin/bash

DOCKER_USER="dockerhub-username"
DOCKER_REPO="myapp"
NEW_VERSION="1.0.0"
OLD_VERSION="0.0.1"
CONTAINER_NAME="myapp"


# Function to check if a container is running and healthy
check_container_status() {
    local container_id="$1"
    local status=$(docker inspect --format='{{.State.Health.Status}}' "$container_id" 2>/dev/null)
    local state=$(docker inspect --format='{{.State.Running}}' "$container_id" 2>/dev/null)

    if [[ "$state" == "true" ]]; then
        if [[ -z "$status" ]]; then
            return 0 # Running, no healthcheck
        elif [[ "$status" == "healthy" ]]; then
            return 0 # Running and healthy
        else
            return 1 # Running, but unhealthy
        fi
    else
        return 1 # Not running
    fi
}

# Function to rollback to the previous version
rollback() {
    echo "Rolling back to version $OLD_VERSION..."

    # Stop and remove the new container
    docker stop "${CONTAINER_NAME}-${NEW_VERSION}" 2>/dev/null
    docker rm "${CONTAINER_NAME}-${NEW_VERSION}" 2>/dev/null

    # Delete the new image
    docker image rm "$DOCKER_USER/$DOCKER_REPO:$NEW_VERSION" 2>/dev/null


    # Run the old container
    docker run -d "$DOCKER_USER/$DOCKER_REPO:$OLD_VERSION"
}

# Main update process
echo "Updating to version $NEW_VERSION..."

# Pull the new image
docker pull "$DOCKER_USER/$DOCKER_REPO:$NEW_VERSION"

# Stop the old container
docker stop "$${CONTAINER_NAME}-${OLD_VERSION}" 2>/dev/null

# Run the new container
docker run -d --name ${CONTAINER_NAME}-${NEW_VERSION} "$DOCKER_USER/$DOCKER_REPO:$NEW_VERSION"

# Check container status
sleep 30 # Give the container time to start and healthcheck to run. Adjust as needed.
container_id=$(docker ps -q --filter name=${CONTAINER_NAME}-${NEW_VERSION})

if [[ -n "$container_id" ]] && check_container_status "$container_id"; then
    echo "Update successful!"
    # Clean up the old container and image
    docker rm ${CONTAINER_NAME}-${OLD_VERSION} 2>/dev/null
    docker image rm "$DOCKER_USER/$DOCKER_REPO:$OLD_VERSION" 2>/dev/null
else
    echo "Update failed! Rolling back..."
    rollback
    echo "Rollback complete."
fi

