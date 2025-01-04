#!/bin/bash
# main.sh

# Make all scripts executable
chmod +x "$SCRIPT_DIR/scripts/"*.sh
chmod +x "$SCRIPT_DIR/scripts/features/"*.sh

# Show usage if no arguments provided
if [ -z "$1" ]
then
    echo "Please provide required arguments"
    echo "Usage: ./main.sh ProjectName [options]"
    echo "Options:"
    echo "  --run              Run the project after creation"
    echo "  --with-user       Add User functionality (repository, service, controller)"
    echo "  --help            Show this help message"
    exit 1
fi

PROJECT_NAME=$1
RUN_PROJECT=false
WITH_USER=false

# Parse command line arguments
shift # Remove first argument (PROJECT_NAME)
while [[ $# -gt 0 ]]; do
    case $1 in
        --run)
            RUN_PROJECT=true
            shift
            ;;
        --with-user)
            WITH_USER=true
            shift
            ;;
        --help)
            echo "Usage: ./main.sh ProjectName [options]"
            echo "Options:"
            echo "  --run              Run the project after creation"
            echo "  --with-user        Add User functionality (repository, service, controller)"
            echo "  --help             Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create a directory for the project and move into it
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Create the project using dotnet new
dotnet new webapi

# Create base directory structure in the project directory
mkdir -p DataModel/Entities
mkdir -p Repositories
mkdir -p Services
mkdir -p Contracts

# Create base interfaces and classes
source "$SCRIPT_DIR/scripts/create_base.sh" "$PROJECT_NAME"

# Create data model with user parameter
source "$SCRIPT_DIR/scripts/create_data_model.sh" "$PROJECT_NAME" "$WITH_USER"

# Add User functionality if requested
if [ "$WITH_USER" = true ]; then
    echo "Adding User functionality..."
    source "$SCRIPT_DIR/scripts/features/add_user.sh" "$PROJECT_NAME"
fi

# Update existing Program.cs
source "$SCRIPT_DIR/scripts/finalize_project.sh" "$PROJECT_NAME" "$WITH_USER"

echo "Solution and project $PROJECT_NAME created successfully!"

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
