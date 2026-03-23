# Build stage (optional here as it's static HTML, but good for future growth)
FROM alpine:3.19 AS builder
WORKDIR /app
COPY src/ /app/src/

# Run stage
FROM nginx:1.25-alpine

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy static content
COPY --from=builder /app/src/ /usr/share/nginx/html/

# Create necessary directories and set permissions for non-root execution
RUN mkdir -p /tmp/client_temp /tmp/proxy_temp_path /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp && \
    chown -R nginx:nginx /tmp/client_temp /tmp/proxy_temp_path /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp && \
    chown -R nginx:nginx /usr/share/nginx/html /etc/nginx/nginx.conf /var/cache/nginx /var/log/nginx /run

# Switch to non-root user
USER nginx

# Expose port 8080 (non-privileged port)
EXPOSE 8080

# Run nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
