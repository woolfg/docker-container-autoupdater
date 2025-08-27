#!/bin/bash

echo "=== Docker Autoupdater Update Test ==="
echo "This test simulates an outdated local image scenario by:"
echo "1. Tagging an older Alpine version as 'latest' locally"
echo "2. Starting a container with this outdated 'latest'"
echo "3. Triggering the autoupdater to detect and update to real latest"
echo ""

docker_compose="$(which docker) compose"

echo "=== Setting up test environment ==="
mkdir -p /tmp/docker-autoupdater-test
cp ./tests/docker-compose.test.yaml /tmp/docker-autoupdater-test/docker-compose.test.yaml

echo "=== Simulating outdated local image ==="
echo "Pulling Alpine 3.17 and tagging as 'latest' locally..."
docker pull alpine:3.17 > /dev/null 2>&1
docker tag alpine:3.17 alpine:latest

echo "=== Starting test container with outdated image ==="
$docker_compose -f /tmp/docker-autoupdater-test/docker-compose.test.yaml up -d

echo "=== Starting autoupdater services ==="
make up 

echo "=== Waiting for initialization ==="
sleep 10

before_image=$(docker inspect docker-autoupdater-test-service1-1 --format "{{.Image}}" | cut -c8-19)
echo "Container before update: $before_image"

echo "=== Triggering update ==="
make test-request

echo "=== Waiting for update to complete ==="
sleep 20

# Check if container still exists and get new image
if docker inspect docker-autoupdater-test-service1-1 > /dev/null 2>&1; then
    updated_image=$(docker inspect docker-autoupdater-test-service1-1 --format "{{.Image}}" | cut -c8-19)
    echo "Container after update: $updated_image"
else
    echo "Container not found after update - checking all test containers:"
    docker ps --filter "name=docker-autoupdater-test" --format "table {{.Names}}\t{{.Image}}\t{{.CreatedAt}}"
    # Try to get the new container ID
    updated_image=$(docker ps --filter "name=docker-autoupdater-test-service1" --format "{{.Image}}" | head -1 | cut -c8-19)
    echo "New container image: $updated_image"
fi

echo ""
echo "=== Update process from logs ==="
make logs 2>/dev/null | grep -A 15 -B 5 "Updating docker-autoupdater-test-service1" | head -20

if [ "$before_image" != "$updated_image" ]; then
    echo "✅ SUCCESS: Container was updated (image ID changed)"
    echo "✅ Real alpine:latest was pulled and container recreated"
else
    echo "❌ FAILED: Container was not updated (image ID unchanged)"
    echo "Debug: before=$before_image, after=$updated_image"
fi

echo "Doing some cleanup..."
$docker_compose -f /tmp/docker-autoupdater-test/docker-compose.test.yaml down > /dev/null 2>&1
make down > /dev/null 2>&1

echo "=== Test completed ==="
