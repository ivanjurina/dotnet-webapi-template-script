# create_services.sh
#!/bin/bash
PROJECT_NAME=$1

cat > Services/UserService.cs << EOF
using $PROJECT_NAME.Contracts;
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
}
EOF