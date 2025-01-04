# create_data_model.sh
#!/bin/bash
PROJECT_NAME=$1
WITH_USER=$2

# Create base DbContext
mkdir -p "DataModel/Entities"

if [ "$WITH_USER" = true ]; then
    # Create User entity
    printf "%s" "using System.ComponentModel.DataAnnotations;

namespace ${PROJECT_NAME}.DataModel.Entities
{
    public class User
    {
        public int Id { get; set; }
        
        [Required]
        public string Username { get; set; } = string.Empty;
        
        [Required]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string PasswordHash { get; set; } = string.Empty;
    }
}" > "DataModel/Entities/User.cs"
fi

# Create DbContext
printf "%s" "using Microsoft.EntityFrameworkCore;
using ${PROJECT_NAME}.DataModel.Entities;

namespace ${PROJECT_NAME}.DataModel
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        $(if [ "$WITH_USER" = true ]; then
        echo "public DbSet<User> Users { get; set; }"
        fi)

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            $(if [ "$WITH_USER" = true ]; then
            echo "modelBuilder.Entity<User>().HasKey(u => u.Id);
            modelBuilder.Entity<User>().HasIndex(u => u.Username).IsUnique();
            
            // Seed some data
            modelBuilder.Entity<User>().HasData(
                new User { 
                    Id = 1, 
                    Username = \"user1\", 
                    Email = \"user1@example.com\",
                    PasswordHash = \"AQAAAAIAAYagAAAAELbHLYHoYyLgK+nqcqLZK5KHAUPvXZr6OxHPCYz8HGSyZvw+WVGQmH/+FyUyX1B/vw==\" // Password: Test123!
                }
            );"
            fi)
        }
    }
}" > "DataModel/ApplicationDbContext.cs"
