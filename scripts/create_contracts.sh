# create_contracts.sh
#!/bin/bash
PROJECT_NAME=$1

cat > Contracts/UserDto.cs << EOF
namespace $PROJECT_NAME.Contracts
{
    public class UserDto
    {
        public int Id { get; set; }
        public string Username { get; set; }
        public string Email { get; set; }
    }
}
EOF