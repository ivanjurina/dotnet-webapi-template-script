#!/bin/bash

if [ -z "$1" ]
then
    echo "Please provide a project name"
    echo "Usage: ./create-api.sh ProjectName"
    exit 1
fi

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

# Create files
echo "namespace $PROJECT_NAME.Contracts
{
    public class UserDto
    {
        public int Id { get; set; }
        public string Username { get; set; }
        public string Email { get; set; }
    }
}" > Contracts/UserDto.cs

echo "namespace $PROJECT_NAME.DataModel.Entities
{
    public class User
    {
        public int Id { get; set; }
        public string Username { get; set; }
        public string Email { get; set; }
    }
}" > DataModel/Entities/User.cs

echo "using Microsoft.EntityFrameworkCore;
using $PROJECT_NAME.DataModel.Entities;

namespace $PROJECT_NAME.DataModel
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
            Database.EnsureCreated();
        }

        public DbSet<User> Users { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<User>().HasKey(u => u.Id);
            
            // Seed some data
            modelBuilder.Entity<User>().HasData(
                new User { Id = 1, Username = \"user1\", Email = \"user1@example.com\" },
                new User { Id = 2, Username = \"user2\", Email = \"user2@example.com\" }
            );
        }
    }
}" > DataModel/ApplicationDbContext.cs

echo "using $PROJECT_NAME.DataModel;
using $PROJECT_NAME.DataModel.Entities;

namespace $PROJECT_NAME.Repositories
{
    public class UserRepository
    {
        private readonly ApplicationDbContext _context;

        public UserRepository(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<User> GetByIdAsync(int id)
        {
            return await _context.Users.FindAsync(id);
        }
    }
}" > Repositories/UserRepository.cs

echo "using $PROJECT_NAME.Contracts;
using $PROJECT_NAME.Repositories;

namespace $PROJECT_NAME.Services
{
    public class UserService
    {
        private readonly UserRepository _userRepository;

        public UserService(UserRepository userRepository)
        {
            _userRepository = userRepository;
        }

        public async Task<UserDto> GetUserByIdAsync(int id)
        {
            var user = await _userRepository.GetByIdAsync(id);
            if (user == null) return null;
            
            return new UserDto 
            { 
                Id = user.Id,
                Username = user.Username,
                Email = user.Email
            };
        }
    }
}" > Services/UserService.cs

echo "using Microsoft.AspNetCore.Mvc;
using $PROJECT_NAME.Contracts;
using $PROJECT_NAME.Services;

namespace $PROJECT_NAME.Controllers
{
    [ApiController]
    [Route(\"[controller]\")]
    public class UsersController : ControllerBase
    {
        private readonly UserService _userService;

        public UsersController(UserService userService)
        {
            _userService = userService;
        }

        [HttpGet(\"{id}\")]
        public async Task<ActionResult<UserDto>> Get(int id)
        {
            var user = await _userService.GetUserByIdAsync(id);
            if (user == null) return NotFound();
            return user;
        }
    }
}" > Controllers/UsersController.cs

echo "using Microsoft.EntityFrameworkCore;
using $PROJECT_NAME.DataModel;
using $PROJECT_NAME.Repositories;
using $PROJECT_NAME.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseInMemoryDatabase(\"$PROJECT_NAME\"));

builder.Services.AddScoped<UserRepository>();
builder.Services.AddScoped<UserService>();

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint(\"/swagger/v1/swagger.json\", \"$PROJECT_NAME API V1\");
    c.RoutePrefix = string.Empty;
});

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();" > Program.cs

# Add packages
dotnet add package Microsoft.EntityFrameworkCore.InMemory
dotnet add package Swashbuckle.AspNetCore

echo "Solution and project $PROJECT_NAME created successfully! Run with 'dotnet run' and visit https://localhost:5001/swagger"