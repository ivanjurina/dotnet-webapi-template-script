# finalize_project.sh
#!/bin/bash
PROJECT_NAME=$1
WITH_USER=$2

# Update the existing Program.cs
printf "%s" "using Microsoft.EntityFrameworkCore;
using ${PROJECT_NAME}.DataModel;
using ${PROJECT_NAME}.Repositories;
using ${PROJECT_NAME}.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseInMemoryDatabase(\"${PROJECT_NAME}\"));

// Register base services
builder.Services.AddScoped<IBaseRepository, BaseRepository>();
builder.Services.AddScoped<IBaseService, BaseService>();

$(if [ "$WITH_USER" = true ]; then
echo '// Register User services
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IUserService, UserService>();'
fi)

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint(\"/swagger/v1/swagger.json\", \"${PROJECT_NAME} API V1\");
    c.RoutePrefix = string.Empty; // Serve Swagger UI at the root
});

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();" > "Program.cs"

# Create Properties directory if it doesn't exist
mkdir -p "Properties"

# Create or update launchSettings.json
printf "%s" '{
  "profiles": {
    "http": {
      "commandName": "Project",
      "dotnetRunMessages": true,
      "launchBrowser": true,
      "launchUrl": "",
      "applicationUrl": "http://localhost:5000",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    },
    "https": {
      "commandName": "Project",
      "dotnetRunMessages": true,
      "launchBrowser": true,
      "launchUrl": "",
      "applicationUrl": "https://localhost:5001;http://localhost:5000",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    }
  }
}' > "Properties/launchSettings.json"

# Add packages and ensure proper restore
dotnet add package Microsoft.EntityFrameworkCore.InMemory --no-restore
dotnet add package Swashbuckle.AspNetCore --no-restore
