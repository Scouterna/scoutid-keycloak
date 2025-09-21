#!/bin/bash

# Replace APPSETTING_KC_ prefix from Azure App Service environment variables
# with KC_ prefix for Keycloak configuration.
for var in $(env | grep "APPSETTING_KC_"); do
  # Extract the variable name (e.g., APPSETTING_KC_URL=https://...)
  var_name=$(echo "$var" | cut -d '=' -f 1)

  # Check if the variable name starts with APPSETTING_KC_
  if [[ "$var_name" == APPSETTING_KC_* ]]; then
    # Get the value of the old variable
    var_value=$(eval echo \$$var_name)

    # Construct the new variable name
    new_var_name=$(echo "$var_name" | sed 's/^APPSETTING_//')

    # Export the new variable with the old value
    export "$new_var_name"="$var_value"

    echo "Set $new_var_name to value of $var_name"
  fi
done

# Fetch an access token for Azure Database for PostgreSQL from the Azure
# Instance Metadata Service. The JDBC driver will use this token as the password
export KC_DB_PASSWORD=$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fossrdbms-aad.database.windows.net' -H Metadata:true -s | jq -r '.access_token')

if [ -z "$KC_DB_PASSWORD" ]; then
  echo "Failed to get database access token."
  exit 1
fi

# Run the 'exec' command as the last step of the script.
# As it replaces the current shell process, no additional shell commands will run after the 'exec' command.
exec /opt/keycloak/bin/kc.sh "$@"
