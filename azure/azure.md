# Scoutid Keycloak Azure config

## Deploying manually

To manually deploy the ScoutID Keycloak application, start by copying the
example .bicepparam file and fill it out:
```bash
cp main.bicepparam.example main.bicepparam
```

Then deploy the application using the Azure CLI:
```bash
az deployment group create \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --resource-group <your-resource-group>
```

## Initializing the database

After having deployed Keycloak for the first time we must initialize the
database. This is done in four steps:
1. Gaining access to the private VNet.
2. Connecting to the database
3. Creating a user for the managed identity of the app service.
4. Granting access to the public schema of the keycloak database.

Before starting, make sure you have the following values ready to go:
- The host of the PostgreSQL database
- The name of the app service
- The email of the configured admin user (`entraAdminPrincipalName` in the Bicep parameters)

### 1. Gaining access to the private VNet.

This is most easily done by creating a jumpbox VM and connecting to it through a
bastion.

### 2. Connecting to the database

In your local terminal where you've got the Azure CLI installed, obtain an
access token that can be used to access the PostgreSQL database:
```bash
az account get-access-token --resource https://ossrdbms-aad.database.windows.net --query accessToken --output tsv
```

Then in your jumpbox VM, install psql, set your access token and connect to the
database using the configured admin user:
```bash
sudo apt install postgresql-client

export PGPASSWORD="<your access token>"

psql -h psql-scoutid-prod-sec-xxxxxxxxxxxxx.postgres.database.azure.com -p 5432 -U configured.admin.user@scouterna.se postgres
```

### 3. Creating a user for the managed identity of the app service.

After you've successfully connected to the database you must create a user for
the managed identity of the app service. It must have the exact same name as the
app service:
```sql
SELECT * FROM pgaadauth_create_principal('app-scoutid-prod-sec-xxxxxxxxxxxxx', false, false);
```

### 4. Granting access to the public schema of the keycloak database.

Finally after the user has been created, grant access to the keycloak database:
```sql
-- Grant full access to the database
GRANT ALL PRIVILEGES ON DATABASE keycloak TO "app-scoutid-prod-sec-xxxxxxxxxxxxx";

-- Switch to the database as the admin user
\c keycloak "configured.admin.user@scouterna.se"

-- Grant full access to the public schema
GRANT ALL ON SCHEMA public TO "app-scoutid-prod-sec-xxxxxxxxxxxxx";
```

Now Keycloak should be able to successfully connect to and migrate the database.
