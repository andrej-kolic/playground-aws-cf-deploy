# Use the official AWS CLI image as the base image
FROM amazon/aws-cli:latest

# Set the working directory (optional, but good practice)
WORKDIR /app

# Copy the rest of the application code
COPY . .

# override entrypoint
# ENTRYPOINT []

# Command to display the AWS CLI version
# This command will be executed when the Docker image is built,
# and its output will be visible during the build process.
RUN echo "--- AWS CLI Version ---" && \
    aws --version

# Command to list files in the working directory
# This command will also be executed during the build process.
RUN echo "\n--- Files in Working Directory (/app) ---" && \
    ls -la

CMD ["--version"]
