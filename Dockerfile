from node:19-alpine

# install docker environment
RUN apk add --no-cache docker bash

COPY update.sh /app/update.sh
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/update.sh /app/entrypoint.sh

COPY index.js /app/index.js
COPY package.json /app/package.json

WORKDIR /app
RUN npm install

EXPOSE 80

# Use the entrypoint script to manage both npm start and update.sh
CMD ["/app/entrypoint.sh"]
