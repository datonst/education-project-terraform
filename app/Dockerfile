# Use official Node.js runtime as base image
FROM node:18-alpine

# Set working directory in container
WORKDIR /app

# Install wget for SSL certificate download
RUN apk add --no-cache wget

# Define build arguments that can be passed during build
ARG MONGODB_URI
ARG PORT=3000
ARG NODE_ENV=production

# Set environment variables from build arguments (commented out to use .env file)
# ENV MONGODB_URI=${MONGODB_URI}
# ENV PORT=${PORT}
# ENV NODE_ENV=${NODE_ENV}

# Copy package files first for better Docker layer caching
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy application source code (now includes .env file)
COPY . .

# Download AWS DocumentDB SSL certificate and create non-root user
RUN wget https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem -O global-bundle.pem && \
    chmod 644 global-bundle.pem && \
    addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose port that the application will run on
EXPOSE 3000

# Start the application
CMD ["npm", "start"] 