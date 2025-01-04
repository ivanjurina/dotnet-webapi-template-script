# dotnet-webapi-template-script

A .NET Web API template with layered architecture and clean code structure.

## Setup
To set up and run the project:

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/dotnet-webapi-template-script.git
   cd dotnet-webapi-template-script
   ```

2. Make the script executable:
   ```bash
   chmod +x main.sh
   ```

3. Run the setup script with available options:

   Basic usage:
   ```bash
   ./main.sh <project-name>
   ```

   Available options:
   
   - `--with-user`: Generates additional user authentication and authorization features
     ```bash
     ./main.sh --with-user
     ```
     This will:
     - Create Entity, Dto, Repository, Service and Controller for User
     - CRUD endpoints on User Controller
     - Register Repository and Service with DI in Program.cs
     - Register User entity in DbContext

   - `--run`: Automatically builds and runs the project after setup
     ```bash
     ./main.sh --run
     ```
     This will:
     - Complete the setup process
     - Build the solution
     - Start the API server
     - Open Swagger UI in default browser

   Combine options:
   ```bash
   ./main.sh <project-name> --with-user --run
   ```

4. After completion, if you didn't use --run, start the API manually:
   ```bash
   cd <project-name>
   dotnet run
   ```

5. Access Swagger UI at:
   ```
   https://localhost:5001/swagger
   ```

Note: Make sure you have .NET SDK installed on your system before running the script.


## Project Structure

```
├── Controllers/
│   └── UsersController.cs
├── Services/
│   └── UserService.cs
├── Repositories/
│   └── UserRepository.cs
├── DataModel/
│   ├── ApplicationDbContext.cs
│   └── Entities/
│       └── User.cs
└── Contracts/
    └── UserDto.cs
```

## Features

- Clean layered architecture pattern
- Entity Framework Core with InMemory database
- Swagger UI configured as default page
- Pre-configured User entity with basic CRUD
- Ready-to-use project structure

## Architecture

- **Controllers**: API endpoints and request handling
- **Services**: Business logic implementation
- **Repositories**: Data access layer
- **DataModel**: Database context and entities
- **Contracts**: Data transfer objects (DTOs)
