# finalize_project.sh
#!/bin/bash
PROJECT_NAME=$1

cat > Program.cs << EOF
using Microsoft.EntityFrameworkCore;
using $PROJECT_NAME.DataModel;
using $PROJECT_NAME.Repositories;
using $PROJECT_NAME.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseInMemoryDatabase("$PROJECT_NAME"));

builder.Services.AddScoped<UserRepository>();
builder.Services.AddScoped<UserService>();

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "$PROJECT_NAME API V1");
    c.RoutePrefix = string.Empty;
});

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();
EOF

# Add packages and ensure proper restore
dotnet add package Microsoft.EntityFrameworkCore.InMemory --no-restore
dotnet add package Swashbuckle.AspNetCore --no-restore
