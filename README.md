# dotnet-webapi-template-script

A .NET Web API template with layered architecture and clean code structure.

## Setup

1. Save the script:
```bash
save as create-api.sh
```

2. Make executable:
```bash
chmod +x create-api.sh
```

3. Run script:
```bash
./create-api.sh YourProjectName
```

4. Navigate to project and run:
```bash
cd YourProjectName/YourProjectName
dotnet run
```

Swagger UI will open automatically at `https://localhost:5001`

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
