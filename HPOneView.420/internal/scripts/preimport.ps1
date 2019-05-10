# Add all things you want to run before importing the main code

# Load the strings used in messages
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\strings.ps1"

# Load all the runtime variables
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\variables.ps1"