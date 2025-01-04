# create_structure.sh
#!/bin/bash
PROJECT_NAME=$1

# Create directory for solution
mkdir $PROJECT_NAME
cd $PROJECT_NAME

# Create solution and project
dotnet new sln -n $PROJECT_NAME
dotnet new webapi -n $PROJECT_NAME
dotnet sln add $PROJECT_NAME/$PROJECT_NAME.csproj

cd $PROJECT_NAME

# Create directory structure
mkdir -p Contracts
mkdir -p Controllers
mkdir -p DataModel/Entities
mkdir -p Repositories
mkdir -p Services