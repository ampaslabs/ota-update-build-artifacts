#!/bin/sh

#================================================
# Docker Container Update Workflow Script. 
# Artifact Registry: AWS Registry or Docker Hub.
#================================================

# Set AWS credentials
AWS_ACCESS_KEY_ID="ABCDEFGHIJKLMNOPQ"                                                 
AWS_SECRET_ACCESS_KEY="AbcDeFgh1234pqRstUvW6789xyZ" 
AWS_REGISTRY_ADDRESS="123456789012.dkr.ecr.us-east-2.amazonaws.com"                        

# AWS (Elastic Container Registry) ECR login/logout commands 
AWS_ECR_LOGIN_COMMAND="docker login --username ${AWS_ACCESS_KEY_ID} --password-stdin  ${AWS_REGISTRY_ADDRESS}"
AWS_ECR_LOGOUT_COMMAND="docker logout ${AWS_REGISTRY_ADDRESS}"

# Set Docker Hub credentials
DOCKER_HUB_USERNAME="dockerhub-username"
DOCKER_HUB_ACCESS_TOKEN="75fa718c-9ec3-11ec-b909-0242ac120002"

# Docker Hub container registry login/logout commands
DOCKER_HUB_LOGIN_COMMAND="docker login --username ${DOCKER_HUB_USERNAME} --password-stdin"
DOCKER_HUB_LOGOUT_COMMAND="docker logout"

# Log debugs
debug_log() {
    echo "$(date "%Y-%m-%d %H:%M:%S.%N"): $1"
}

# Clean Up
cleanup() {
   debug_log "Cleaning up..."
   # Logout of the docker image registry: DockerHub or AWS ECR
   $DOCKER_HUB_LOGOUT_COMMAND                                                                  
   # $AWS_ECR_LOGOUT_COMMAND                                                                  
   rm /tmp/update.sh  
   debug_log "Clean up done!"                                                     
}

# Log error and exit
debug_error_exit() {
    echo "$(date "%Y-%m-%d %H:%M:%S.%N"): Error: $1"
    cleanup
    exit 1
}

# Restore previously running container
restore_from_backup() {
    DOCKER_RUN_COMMAND=$1
    CONTAINER_NAME=$2

    debug_log "Stopping and removing failed container: ${CONTAINER_NAME}" 
    docker rm --force ${CONTAINER_NAME}

    debug_log "Restoring from backup: $DOCKER_RUN_COMMAND"
    eval $1
         if [ $? -eq 0 ]; then                                                                   
            debug_log "Docker run command executed: ${DOCKER_RUN_COMMAND}"                                      
         else                                                                                    
            debug_error_exit "Docker run command failed!: ${DOCKER_RUN_COMMAND}"
         fi
    # Sleep 30 seconds before checking the status
    sleep 30
    CONTAINER_RUNNING_STATUS="$(docker inspect --format "{{.State.Running}}" --type container "${CONTAINER_NAME}")"
        if [ $? -eq 0 ]; then                                                                         
            debug_log "Container running status: ${CONTAINER_RUNNING_STATUS}"                                               
        else                                                                                          
            debug_error_exit "Failed retrieving container running status!: ${CONTAINER_NAME}"                                                    
        fi 

    if [[ "$CONTAINER_RUNNING_STATUS" == "true" ]]; then
        debug_log "Restoration successful: ${CONTAINER_NAME}"
    else 
        debug_error_exit "Restoration failed: ${CONTAINER_NAME}"    
    fi  
}

#============================================
# Workflow Begins.
#============================================  

# Get the container name and the latest image name from the command line args                             
container=$1                                                         
echo "Container name: ${container}" 
LATEST_IMAGE_NAME=$2
echo "Image name: ${LATEST_IMAGE_NAME}"

# Login to the docker image registry: DockerHub or AWS ECR
echo "${DOCKER_HUB_ACCESS_TOKEN}" | $($DOCKER_HUB_LOGIN_COMMAND)
# echo "${AWS_SECRET_ACCESS_KEY}" | $($AWS_ECR_LOGIN_COMMAND)  


# To update a list of containers, add a for loop to the following code block, as shown below:
#
# CONTAINERS=$1
# LATEST_IMAGE_NAMES=$2
#
# for i in ${!CONTAINERS[@]}; do 
#   container=${CONTAINERS[i]}
#   LATEST_IMAGE_NAME=${LATEST_IMAGE_NAMES[i]}
#   ...
#   ...
# done

# Update Begin                                                                                                
echo "\n+++ Begin updating container: ${container} +++\n"
RUNNING_IMAGE_HASH="$(docker inspect --format "{{.Image}}" --type container "${container}")"       
    if [ $? -eq 0 ]; then                                                                         
    debug_log "Running container's image hash: ${RUNNING_IMAGE_HASH}"                                                   
    else                                                                                          
    debug_error_exit "Failed retrieving running container's image hash: ${container}"                                                      
    fi                                                                                            

# Pull in the latest version of the container and get the hash                                    
docker pull "${LATEST_IMAGE_NAME}"                                                              
    if [ $? -eq 0 ]; then                                                                         
    debug_log "docker pull of latest image successful: ${LATEST_IMAGE_NAME}"                                                   
    else                                                                                          
    debug_error_exit "docker pull of latest image failed: ${LATEST_IMAGE_NAME}"                                                        
    fi              

# Get the latest image hash                                                                              
LATEST_IMAGE_HASH="$(docker inspect --format "{{.Id}}" --type image "${LATEST_IMAGE_NAME}")"         
    if [ $? -eq 0 ]; then                                                                         
    debug_log "Latest image hash: ${LATEST_IMAGE_HASH}"                                                     
    else                                                                                          
    debug_error_exit "Failed retrieving the latest image's hash: ${LATEST_IMAGE_NAME}"                                                       
    fi                                                                                            

# Create a new container using the latest image, if the image is different                                             
if [[ "${RUNNING_IMAGE_HASH}" != "${LATEST_IMAGE_HASH}" ]]; then                                        
    debug_log "Updating container ${container} with latest image ${LATEST_IMAGE_NAME}"                                        

    # Delete the running container first                                                
    docker rm --force "${container}"                                                            
        if [ $? -eq 0 ]; then                                                                   
        debug_log "docker rm: ${container}"                                                         
        else                                                                                    
        debug_error_exit "docker rm failed!: ${container}"                                                        
        fi    

    # Create a new container using the latest image
    DOCKER_RUN_COMMAND="docker run -d --name ${container}"  
    eval "${DOCKER_RUN_COMMAND} ${LATEST_IMAGE_NAME}"                                                               
        if [ $? -eq 0 ]; then                                                                   
        debug_log "docker run command executed: ${DOCKER_RUN_COMMAND} ${LATEST_IMAGE_NAME}"                                      
        else                                                                                    
        debug_log "docker run command failed!: ${DOCKER_RUN_COMMAND} ${LATEST_IMAGE_NAME}" 
        restore_from_backup "$(${DOCKER_RUN_COMMAND} ${RUNNING_IMAGE_HASH})" "${container}"
        fi 

    # Sleep 30 seconds before checking the container status
    sleep 30
    CONTAINER_RUNNING_STATUS="$(docker inspect --format "{{.State.Running}}" --type container "${container}")"
        if [ $? -eq 0 ]; then                                                                         
          debug_log "Container running status: ${CONTAINER_RUNNING_STATUS}"                                               
        else                                                                                          
          debug_log "Failed retrieving container running status!: ${container}" 
          restore_from_backup "${DOCKER_RUN_COMMAND} ${RUNNING_IMAGE_HASH}" "${container}"
        fi

    if [[ "$CONTAINER_RUNNING_STATUS" == "true"  ]]; then
        debug_log "Container update successful: ${container}"
    else
        debug_log "Container update failed: ${container}"
        restore_from_backup "${DOCKER_RUN_COMMAND} ${RUNNING_IMAGE_HASH}" "${container}"
    fi

    # Remove the old image                                                                                     
    docker rmi "${RUNNING_IMAGE_HASH}"                                                               
        if [ $? -eq 0 ]; then                                                                   
        debug_log "docker rmi: ${RUNNING_IMAGE_HASH}"                                                    
        else                                                                                    
        debug_error_exit "docker rmi failed!: ${RUNNING_IMAGE_HASH}"                                                       
        fi                                                                                      
else                                                                                          
  echo "Running image same as the latest image. Not updating ${container} with latest image ${LATEST_IMAGE_NAME}"                
fi

echo "\n+++ End updating container: ${container} +++\n"

# Finally clean up
cleanup