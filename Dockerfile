from node:19-alpine

# install docker environment
RUN apk add --no-cache docker bash

COPY update.sh /app/update.sh
RUN chmod +x /app/update.sh

COPY index.js /app/index.js
COPY package.json /app/package.json

WORKDIR /app
RUN npm install

EXPOSE 80
CMD [ "npm", "start" ]
