# create_data_model.sh
#!/bin/bash
PROJECT_NAME=$1

cat > DataModel/Entities/User.cs << EOF
namespace $PROJECT_NAME.DataModel.Entities
{
    public class User
    {
        public int Id { get; set; }
        public string Username { get; set; }
        public string Email { get; set; }
    }
}
EOF

cat > DataModel/ApplicationDbContext.cs << EOF
using Microsoft.EntityFrameworkCore;
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
                new User { Id = 1, Username = "user1", Email = "user1@example.com" },
                new User { Id = 2, Username = "user2", Email = "user2@example.com" }
            );
        }
    }
}
EOF