# Use the official Nginx image as the base (lightweight image)
FROM nginx:alpine

# Define the maintainer
LABEL maintainer="gabriel@devops.com"

# Copy a demonstration HTML file (which we will create now) to the default Nginx web directory
COPY index.html /usr/share/nginx/html/
