# finalize_project.sh
#!/bin/bash
PROJECT_NAME=$1
WITH_USER=$2

# Update appsettings.json to include JWT configuration and connection string
printf "%s" '{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "DefaultConnection": "Data Source=app.db"
  },
  "JwtConfig": {
    "Secret": "your-super-secret-key-with-at-least-32-characters",
    "Issuer": "your-api",
    "Audience": "your-clients",
    "ExpiryInMinutes": 60
  }
}' > "appsettings.json"

# Update Program.cs with SQLite configuration
printf "%s" "using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using ${PROJECT_NAME}.Configuration;
using ${PROJECT_NAME}.DataModel;
using ${PROJECT_NAME}.DataModel.Entities;
using ${PROJECT_NAME}.Repositories;
using ${PROJECT_NAME}.Services;

var builder = WebApplication.CreateBuilder(args);

// Add JWT Configuration
var jwtConfig = builder.Configuration.GetSection(\"JwtConfig\").Get<JwtConfig>();
builder.Services.AddSingleton(jwtConfig);

// Add SQLite Database
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString(\"DefaultConnection\")));

// Add JWT Authentication
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
}).AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtConfig.Issuer,
        ValidAudience = jwtConfig.Audience,
        IssuerSigningKey = new SymmetricSecurityKey(
            Encoding.ASCII.GetBytes(jwtConfig.Secret))
    };
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// Configure Swagger with JWT authentication
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc(\"v1\", new OpenApiInfo { Title = \"${PROJECT_NAME} API\", Version = \"v1\" });
    
    // Configure JWT authentication in Swagger
    c.AddSecurityDefinition(\"Bearer\", new OpenApiSecurityScheme
    {
        Description = \"JWT Authorization header using the Bearer scheme. Example: 'Bearer 12345abcdef'\",
        Name = \"Authorization\",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = \"Bearer\"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = \"Bearer\"
                }
            },
            Array.Empty<string>()
        }
    });
});

// Register base services
builder.Services.AddScoped<IBaseRepository, BaseRepository>();
builder.Services.AddScoped<IBaseService, BaseService>();

$(if [ "$WITH_USER" = true ]; then
echo '// Register User services
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IPasswordHasher<User>, PasswordHasher<User>>();'
fi)

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint(\"/swagger/v1/swagger.json\", \"${PROJECT_NAME} API V1\");
    c.RoutePrefix = string.Empty;
});

app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();" > "Program.cs"
# # Create Properties directory if it doesn't exist
# mkdir -p "Properties"

# # Create or update launchSettings.json
# printf "%s" '{
#   "profiles": {
#     "http": {
#       "commandName": "Project", 
#       "dotnetRunMessages": true,
#       "launchBrowser": true,
#       "launchUrl": "",
#       "applicationUrl": "http://localhost:5000",
#       "environmentVariables": {
#         "ASPNETCORE_ENVIRONMENT": "Development"
#       }
#     },
#     "https": {
#       "commandName": "Project",
#       "dotnetRunMessages": true,
#       "launchBrowser": true,
#       "launchUrl": "",
#       "applicationUrl": "https://localhost:5001;http://localhost:5000",
#       "environmentVariables": {
#         "ASPNETCORE_ENVIRONMENT": "Development"
#       }
#     }
#   }
# }' > "Properties/launchSettings.json"

# Add packages and ensure proper restore
dotnet add package Microsoft.EntityFrameworkCore.InMemory --no-restore
dotnet add package Swashbuckle.AspNetCore --no-restore
