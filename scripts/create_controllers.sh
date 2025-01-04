# create_controllers.sh
#!/bin/bash
PROJECT_NAME=$1

cat > Controllers/UsersController.cs << EOF
using Microsoft.AspNetCore.Mvc;
using $PROJECT_NAME.Contracts;
using $PROJECT_NAME.Services;

namespace $PROJECT_NAME.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class UsersController : ControllerBase
    {
        private readonly UserService _userService;

        public UsersController(UserService userService)
        {
            _userService = userService;
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<UserDto>> Get(int id)
        {
            var user = await _userService.GetUserByIdAsync(id);
            if (user == null) return NotFound();
            return user;
        }
    }
}
EOF