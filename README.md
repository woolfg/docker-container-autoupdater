# docker_swarm_autoupdater
Updates Docker Swarm Service images automatically

## Design decisions

- Webhook image tags: To be as secure as possible I decided to not accept any input from the webhook. Therfore, a fixed tag (e.g. latest) is used for the image.
- Image digest without pulling the image: Unfortently, it is very difficult to receive the image digest without downloading the image. You have do an api call directly, use auth data, or use an external library/tool for it. I want to support docker hub but also pricate repositories. Especially specifying auth data is cumbersome and I prefer to use docker tools and reduce the dependencies. Thus, I decided to pull the image and use the digest from the local image. This is not ideal, but it a pragmatic solution.
