# create_repositories.sh
#!/bin/bash
PROJECT_NAME=$1

cat > Repositories/UserRepository.cs << EOF
using $PROJECT_NAME.DataModel;
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
}
EOF