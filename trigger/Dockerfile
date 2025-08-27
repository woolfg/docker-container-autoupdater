FROM node:19-alpine

# Use the existing node user for security (UID 1000)
# No need to create new user as node:alpine already has node user with UID 1000

# Create app directory
RUN mkdir -p /app && chown node:node /app

# Copy package files first for better Docker layer caching
COPY package.json /app/
WORKDIR /app

# Install dependencies
RUN npm install

# Copy application files
COPY index.js /app/

# Change ownership to node user
RUN chown -R node:node /app

# Switch to non-root user
USER node

# Expose port
EXPOSE 3000

# Start the application
CMD ["npm", "start"]
