#!/bin/bash

docker=$(which docker)

platform="amd64"
os="linux"

# allow docker_swarm_autoupdater docker_autoupdater
filters=("label=docker_swarm_autoupdater.enable=true" "label=docker_autoupdater.enable=true")

echo "Starting autoupdater"

# check if we are in a docker compose env or docker swarm $($docker info --format '{{.Swarm.LocalNodeState}}') == "active"
# should be true or false
if [ "$($docker info --format '{{.Swarm.LocalNodeState}}')" == "active" ]; then
  echo "Running in Docker Swarm mode"
  docker_swarm=true
else
  echo "Running in Docker Compose mode"
  docker_swarm=false
fi

# list all services with label autoupdater=true
services=""
for filter in "${filters[@]}"; do
  if [ "$docker_swarm" = true ]; then
    current_services=$($docker service ls --filter "$filter" --format "{{.Name}}")
  else
    current_services=$($docker ps --filter "$filter" --format "{{.Names}}")
  fi
  
  if [ ! -z "$current_services" ]; then
    echo "Found services with filter '$filter': $current_services"
    if [ -z "$services" ]; then
      services="$current_services"
    else
      services=$(printf "%s\n%s" "$services" "$current_services" | sort -u)
    fi
  fi
done

if [ $? -ne 0 ]; then
    echo "Failed to get services"
    exit 1
fi

# if no services found, tell it
if [ -z "$services" ]; then
    echo "No services with filters: ${filters[*]} found"
    exit 0
fi

# output all services
echo "Found services:"
for service in $services; do
    echo " - $service"
done

#loop through services
for service in $services; do

    echo "===================="
    echo "Checking $service"

    # get current used digest of image
    # out is in the form of mysql:8.0@sha256:f496c25da703053a6e0717f1d52092205775304ea57535cc9fcaa6f35867800b
    if [ "$docker_swarm" = true ]; then
      image_long=$($docker service inspect $service --format "{{.Spec.TaskTemplate.ContainerSpec.Image}}")
    else
      image_long=$($docker container inspect $service --format "{{.Config.Image}}")
    fi
    image_digest=${image_long##*@}
    image_name_version=${image_long%@*}
    echo "Current image: $image_name_version"
    echo "Current digest: $image_digest"

    # if image digest or name is empty, skip service
    if [ -z "$image_digest" ] || [ -z "$image_name_version" ]; then
        echo "Skipping $service as there is problem with image name or digest"
        continue
    fi    

    # pull image to get updated image
    $docker pull $image_name_version

    # get digest of downloaded image
    new_digest=$($docker image inspect $image_name_version --format "{{index .RepoDigests 0}}" | cut -d'@' -f2)
    echo "New digest: $new_digest"

    # if new digest is empty, skip service
    if [ -z "$new_digest" ]; then
        echo "Skipping $service as there is no matching digest"
        continue
    fi

    # compare digests and update service if needed
    if [ "$image_digest" != "$new_digest" ]; then
        echo "Updating $service"
        if [ "$docker_swarm" = true ]; then
          $docker service update --image $image_name_version@$new_digest $service
        else
          # For Docker Compose, we need to recreate the container
          echo "Stopping container $service"
          $docker stop $service
          echo "Removing container $service"
          $docker rm $service
          echo "Note: Container $service has been stopped and removed. You may need to restart your Docker Compose setup."
        fi
    else
        echo "No update needed"
    fi

done
