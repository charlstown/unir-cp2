# Use official Nginx image
FROM nginx:latest

# Copy generated HTML files to Nginx's web root
COPY site/ /usr/share/nginx/html/

# Expose port 80
EXPOSE 80
