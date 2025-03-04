# Use a lightweight base image
FROM ubuntu:latest

# Copy the pre-compiled executable
COPY myapp /usr/bin/myapp

# Set the executable bit (important!)
RUN chmod +x /usr/bin/myapp

# Command to run when the container starts
CMD ["/usr/bin/myapp"]