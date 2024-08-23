using './main.bicep'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME')
param locationPrimary = readEnvironmentVariable('AZURE_LOCATION_PRIMARY')
param locationSecondary = readEnvironmentVariable('AZURE_LOCATION_SECONDARY')
param georeplicate = bool(readEnvironmentVariable('AZURE_SERVICEBUS_GEO_REPLICATE'))

