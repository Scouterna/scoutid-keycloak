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

# # Fetch an access token for Azure Database for PostgreSQL from the Azure
# # Instance Metadata Service. The JDBC driver will use this token as the password
# RESOURCE_URI="https://ossrdbms-aad.database.windows.net"
# TOKEN_AUTH_URI="${IDENTITY_ENDPOINT}?resource=${RESOURCE_URI}&api-version=2019-08-01"

# export KC_DB_PASSWORD=$(curl -s -X GET \
#   -H "X-IDENTITY-HEADER: $IDENTITY_HEADER" \
#   "$TOKEN_AUTH_URI" | jq -r '.access_token')

# Run the 'exec' command as the last step of the script.
# As it replaces the current shell process, no additional shell commands will run after the 'exec' command.
exec /opt/keycloak/bin/kc.sh "$@"
