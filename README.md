# Docker Swarm Autoupdater

Updates Docker Swarm Service images automatically when calling a webhook.
Can be used for deploying new versions of your application in your docker swarm cluster.

## Usage

Create a service for the autoupdater and mount the docker socket to the container.

```yaml
version: '3.7'
services:
    autoupdater:
      image: woolfg/docker-swarm-autoupdater:latest
      volumes:
        - /var/run/docker.sock:/var/run/docker.sock
      environment:
        PORT: 80
        HOOK: /update-PUT_YOUR_RANDOM_STRING_HERE
      deploy:
        placement:
          constraints:
            - node.role == manager
```

When calling the hook `/update-PUT_YOUR_RANDOM_STRING_HERE` the autoupdater will update all services
with the label `docker_swarm_autoupdater.enable=true` to the latest digest of the specified tag (e.g. `latest`).
## Design decisions

- Webhook image tags: To be as secure as possible I decided to not accept any input from the webhook. Therfore, a fixed tag (e.g. latest) is used for the image.
- Image digest without pulling the image: Unfortently, it is very difficult to receive the image digest without downloading the image. You have do an api call directly, use auth data, or use an external library/tool for it. I want to support docker hub but also private repositories. Especially specifying auth data is cumbersome and I prefer to use docker tools and reduce the dependencies. Thus, I decided to pull the image and use the digest from the local image. This is not ideal, but it a pragmatic solution.

## Contributions

Thanks to `@mre` for the input and code reviews.
