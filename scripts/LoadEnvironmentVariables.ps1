param (
    [Parameter(Mandatory = $false)]
    [string]$envFilePath
)

if ([string]::IsNullOrEmpty($envFilePath)) {
    $dir = $PSScriptRoot
    $dataPath = Resolve-Path "$dir/../data"
    $envFilePath = "$dataPath/.env"
}

# Read the .env file
$envFileContent = Get-Content -Path $envFilePath

# Loop through each line in the .env file
foreach ($line in $envFileContent) {
    # Split the line into a name and a value
    $name, $value = $line -split '=', 2

    # remove the quotes from the value
    $value = $value.Trim('"')

    # Set the environment variable
    [Environment]::SetEnvironmentVariable($name, $value, "Process")
}