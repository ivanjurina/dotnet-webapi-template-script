#!/bin/bash
# main.sh

# Show usage if no arguments provided
if [ -z "$1" ]
then
    echo "Please provide required arguments"
    echo "Usage: ./main.sh ProjectName [--run]"
    echo "Options:"
    echo "  --run    Run the project after creation"
    exit 1
fi

PROJECT_NAME=$1
RUN_PROJECT=false

# Parse command line arguments
shift # Remove first argument (PROJECT_NAME)
while [[ $# -gt 0 ]]; do
    case $1 in
        --run)
            RUN_PROJECT=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


# Create base directory structure
source "$SCRIPT_DIR/scripts/create_structure.sh" "$PROJECT_NAME"

# Create project files
source "$SCRIPT_DIR/scripts/create_project.sh" "$PROJECT_NAME"

# Create data model
source "$SCRIPT_DIR/scripts/create_data_model.sh" "$PROJECT_NAME"

# Create contracts
source "$SCRIPT_DIR/scripts/create_contracts.sh" "$PROJECT_NAME"

# Create repositories
source "$SCRIPT_DIR/scripts/create_repositories.sh" "$PROJECT_NAME"

# Create services
source "$SCRIPT_DIR/scripts/create_services.sh" "$PROJECT_NAME"

# Create controllers
source "$SCRIPT_DIR/scripts/create_controllers.sh" "$PROJECT_NAME"

# Update Program.cs and add packages
source "$SCRIPT_DIR/scripts/finalize_project.sh" "$PROJECT_NAME"

echo "Solution and project $PROJECT_NAME created successfully! Run with 'dotnet run'"

# Restore and build
echo "Restoring packages..."
dotnet restore --force --no-cache

echo "Building project..."
dotnet build --no-restore

# Clean any temporary files
dotnet clean
dotnet restore

# Only run if --run flag is provided
if [ "$RUN_PROJECT" = true ]; then
    echo "Running project..."
    dotnet run
fi
