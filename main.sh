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
DB_BACKUP_PATH="$SCRIPT_DIR/temp_db_backup"

# Create backup directory if it doesn't exist
mkdir -p "$DB_BACKUP_PATH"

# Check if project directory exists and handle database preservation
if [ -d "$PROJECT_NAME" ]; then
    echo "⚠️  Project directory '$PROJECT_NAME' already exists."
    PRESERVE_DB=false
    
    # Check if database exists
    if [ -f "$PROJECT_NAME/app.db" ]; then
        echo "📁 Existing SQLite database found at: $PROJECT_NAME/app.db"
        read -p "Do you want to preserve the existing database? (Y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            echo "🗑️  Database will be deleted with the project."
            PRESERVE_DB=false
        else
            echo "💾 Database will be preserved."
            PRESERVE_DB=true
            # Backup the database before anything else
            echo "📦 Creating database backup..."
            cp "$PROJECT_NAME/app.db" "$DB_BACKUP_PATH/app.db"
            if [ $? -eq 0 ]; then
                echo "✅ Database backup created successfully at: $DB_BACKUP_PATH/app.db"
                ls -l "$DB_BACKUP_PATH/app.db"
            else
                echo "❌ Failed to create database backup"
                exit 1
            fi
        fi
    fi

    read -p "Do you want to delete the existing project and create a new one? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Deleting existing project directory..."
        rm -rf "$PROJECT_NAME"
        echo "✅ Project directory deleted"
    else
        if [ "$PRESERVE_DB" = true ]; then
            rm -rf "$DB_BACKUP_PATH"  # Clean up backup if we're not proceeding
        fi
        echo "❌ Operation cancelled."
        exit 1
    fi
fi

# Create project directory
echo "📁 Creating new project directory..."
mkdir -p "$PROJECT_NAME"
echo "✅ Project directory created at: $PROJECT_NAME"

# Restore database if it was preserved
if [ "$PRESERVE_DB" = true ] && [ -f "$DB_BACKUP_PATH/app.db" ]; then
    echo "🔄 Restoring database from: $DB_BACKUP_PATH/app.db"
    cp "$DB_BACKUP_PATH/app.db" "$PROJECT_NAME/app.db"
    if [ $? -eq 0 ]; then
        echo "✅ Database restored successfully"
        ls -l "$PROJECT_NAME/app.db"
    else
        echo "❌ Failed to restore database"
        exit 1
    fi
    rm -rf "$DB_BACKUP_PATH"  # Clean up backup directory
fi

# Change to project directory
cd "$PROJECT_NAME"

# Create the project using dotnet new
echo "🚀 Creating new project '$PROJECT_NAME'..."
dotnet new webapi

# Add required packages
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer
dotnet add package Microsoft.IdentityModel.Tokens
dotnet add package System.IdentityModel.Tokens.Jwt
dotnet add package Microsoft.AspNetCore.Identity
dotnet add package Microsoft.EntityFrameworkCore.Sqlite
dotnet add package Microsoft.EntityFrameworkCore.Design
dotnet add package Microsoft.EntityFrameworkCore.Tools

# Create base directory structure in the project directory
mkdir -p DataModel/Entities
mkdir -p Repositories
mkdir -p Services
mkdir -p Contracts
mkdir -p Configuration

# Create JwtConfig first
printf "%s" "namespace ${PROJECT_NAME}.Configuration
{
    public class JwtConfig
    {
        public string Secret { get; set; } = string.Empty;
        public string Issuer { get; set; } = string.Empty;
        public string Audience { get; set; } = string.Empty;
        public int ExpiryInMinutes { get; set; }
    }
}" > "Configuration/JwtConfig.cs"

# Create base interfaces and classes
source "$SCRIPT_DIR/scripts/create_base.sh" "$PROJECT_NAME"

# Create data model with user parameter
source "$SCRIPT_DIR/scripts/create_data_model.sh" "$PROJECT_NAME" "$WITH_USER"

# Add User functionality if requested
if [ "$WITH_USER" = true ]; then
    echo "Adding User functionality..."
    source "$SCRIPT_DIR/scripts/features/add_user.sh" "$PROJECT_NAME"
    source "$SCRIPT_DIR/scripts/features/add_auth.sh" "$PROJECT_NAME"
fi

# Update Program.cs and add packages
source "$SCRIPT_DIR/scripts/finalize_project.sh" "$PROJECT_NAME" "$WITH_USER"

echo "Solution and project $PROJECT_NAME created successfully!"

# Restore and build
echo "Restoring packages..."
dotnet restore --force --no-cache

echo "Building project..."
dotnet build --no-restore

# Add initial migration and create database
if [ "$WITH_USER" = true ]; then
    if [ ! -f "app.db" ] || [ ! "$PRESERVE_DB" = true ]; then
        echo "Creating database migrations..."
        dotnet ef migrations add InitialCreate
        echo "Updating database..."
        dotnet ef database update
    else
        echo "📁 Using existing database..."
        echo "Current database location: $(pwd)/app.db"
        ls -l app.db
    fi
fi

# Only run if --run flag is provided
if [ "$RUN_PROJECT" = true ]; then
    echo "Running project..."
    # Run the API and capture its output
    dotnet run > api.log 2>&1 &
    API_PID=$!

    # Wait for the application to start and get the URL
    while ! grep -q "Now listening on:" api.log; do
        sleep 1
    done

    # Extract the URL from the log
    API_URL=$(grep "Now listening on:" api.log | sed 's/.*Now listening on: \(.*\)/\1/')
    echo "🌐 API is running at: $API_URL"
    echo "📚 Swagger UI available at: $API_URL"

    # Run the test script with the correct URL
    export API_URL
    source "$SCRIPT_DIR/scripts/test_api.sh" "$PROJECT_NAME"

    # Clean up log file but keep the app running
    rm api.log

    # Wait for the app to be stopped manually
    echo -e "\n🌐 API is running at: $API_URL"
    echo "📚 Swagger UI available at: $API_URL"
    echo "Press Ctrl+C to stop."
    wait $API_PID
fi
