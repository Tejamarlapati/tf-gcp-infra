#! /bin/bash

# Start the Google Ops Agent
sudo systemctl start google-cloud-ops-agent

# Check if the startup script has already been completed. Skip if file exists.
if [ -f /opt/webapp_startup_completed ]; then
    echo "Startup script already completed. Skipping."
    exit 0
fi

# Write the environment variables to the .env file
{
    echo "PORT=80"
    echo "SSL=true"
    echo "DB_NAME=${name}"
    echo "DB_USER=${username}"
    echo "DB_PASSWORD=${password}"
    echo "DB_HOST=${host}"
    echo "DB_PORT=5432"
    echo "DB_TIMEOUT=10000"
    echo "LOG_FOLDER=/var/log/webapp"
    echo "LOG_LEVEL=${loglevel}"
    echo "PUBSUB_TOPIC=${topicname}"
    echo "EMAIL_EXPIRY_MINUTES=2"
} > /opt/webapp/dist/.env

# Change the ownership of the /opt/webapp/dist/.env file to the csye6225 user
chown csye6225:csye6225 /opt/webapp/dist/.env

# Create the webapp_startup_completed file to indicate that the startup script has been completed once.
# Set the read permissions for all users for the webapp_startup_completed file
touch /opt/webapp_startup_completed
chmod 744 /opt/webapp_startup_completed
