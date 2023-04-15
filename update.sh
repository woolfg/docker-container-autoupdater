#!/bin/bash

docker=$(which docker)

platform="amd64"
os="linux"

# list all services with label autoupdater=true
services=$($docker service ls --filter label=docker_swarm_autoupdater.enable=true --format "{{.Name}}")

#loop through services
for service in $services; do

    echo "===================="
    echo "Checking $service"

    # get current used digest of image
    # out is in the form of mysql:8.0@sha256:f496c25da703053a6e0717f1d52092205775304ea57535cc9fcaa6f35867800b
    image_long=$($docker service inspect $service --format "{{.Spec.TaskTemplate.ContainerSpec.Image}}")
    image_digest=${image_long##*@}
    image_name_version=${image_long%@*}
    echo "Current image: $image_name_version"
    echo "Current digest: $image_digest"

    # if image digest or name is empty, skip service
    if [ -z "$image_digest" ] || [ -z "$image_name_version" ]; then
        echo "Skipping $service as there is problem with image name or digest"
        continue
    fi    

    # fetch manifest of image
    manifest=$($docker manifest inspect $image_name_version)

    # filter manifest by platform.architecture and get new matching digest
    new_digest=$(echo $manifest | jq -r ".manifests[] | select(.platform.architecture == \"$platform\" and .platform.os == \"$os\") | .digest")
    echo "New digest: $new_digest"

    # the digest might be different even though it is the same image
    # as repo digests also depend on the manifest and additional metadata
    # thus, the service might be updated, even though the image is the same
    # this should happen just once, as from then on the digests should match

    # if new digest is empty, skip service
    if [ -z "$new_digest" ]; then
        echo "Skipping $service as there is no matching digest"
        continue
    fi

    # compare digests and update service if needed
    if [ "$image_digest" != "$new_digest" ]; then
        echo "Updating $service"
        $docker service update --image $image_name_version@$new_digest $service
    else
        echo "No update needed"
    fi

done