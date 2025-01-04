#!/bin/bash

PROJECT_NAME=$1

# Add User DTOs
mkdir -p "Contracts"
printf "%s" "using System.ComponentModel.DataAnnotations;

namespace ${PROJECT_NAME}.Contracts
{
    public class CreateUserDto
    {
        [Required]
        public string Username { get; set; } = string.Empty;
        
        [Required]
        public string Email { get; set; } = string.Empty;
    }

    public class UpdateUserDto
    {
        [Required]
        public string Username { get; set; } = string.Empty;
        
        [Required]
        public string Email { get; set; } = string.Empty;
    }

    public class UserDto
    {
        public int Id { get; set; }
        public string Username { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
    }
}" > "Contracts/UserDto.cs"

# Add User repository
mkdir -p "Repositories"
printf "%s" "using Microsoft.EntityFrameworkCore;
using ${PROJECT_NAME}.DataModel;
using ${PROJECT_NAME}.DataModel.Entities;

namespace ${PROJECT_NAME}.Repositories
{
    public interface IUserRepository
    {
        Task<IEnumerable<User>> GetAll();
        Task<User> GetById(int id);
        Task Add(User user);
        Task Update(User user);
        Task Delete(User user);
    }

    public class UserRepository : IUserRepository
    {
        private readonly ApplicationDbContext _context;

        public UserRepository(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<User>> GetAll()
        {
            return await _context.Users.ToListAsync();
        }

        public async Task<User> GetById(int id)
        {
            return await _context.Users.FindAsync(id);
        }

        public async Task Add(User user)
        {
            await _context.Users.AddAsync(user);
            await _context.SaveChangesAsync();
        }

        public async Task Update(User user)
        {
            _context.Users.Update(user);
            await _context.SaveChangesAsync();
        }

        public async Task Delete(User user)
        {
            _context.Users.Remove(user);
            await _context.SaveChangesAsync();
        }
    }
}" > "Repositories/UserRepository.cs"

# Add User service
mkdir -p "Services"
printf "%s" "using ${PROJECT_NAME}.Contracts;
using ${PROJECT_NAME}.DataModel.Entities;
using ${PROJECT_NAME}.Repositories;

namespace ${PROJECT_NAME}.Services
{
    public interface IUserService
    {
        Task<IEnumerable<UserDto>> GetAllUsers();
        Task<UserDto> GetUserById(int id);
        Task<UserDto> CreateUser(CreateUserDto createUserDto);
        Task<bool> UpdateUser(int id, UpdateUserDto updateUserDto);
        Task<bool> DeleteUser(int id);
    }

    public class UserService : IUserService
    {
        private readonly IUserRepository _userRepository;

        public UserService(IUserRepository userRepository)
        {
            _userRepository = userRepository;
        }

        private static UserDto MapToDto(User user)
        {
            return new UserDto 
            { 
                Id = user.Id, 
                Username = user.Username, 
                Email = user.Email 
            };
        }

        public async Task<IEnumerable<UserDto>> GetAllUsers()
        {
            var users = await _userRepository.GetAll();
            return users.Select(MapToDto);
        }

        public async Task<UserDto> GetUserById(int id)
        {
            var user = await _userRepository.GetById(id);
            return user == null ? null : MapToDto(user);
        }

        public async Task<UserDto> CreateUser(CreateUserDto createUserDto)
        {
            var user = new User 
            { 
                Username = createUserDto.Username, 
                Email = createUserDto.Email 
            };
            
            await _userRepository.Add(user);
            return MapToDto(user);
        }

        public async Task<bool> UpdateUser(int id, UpdateUserDto updateUserDto)
        {
            var user = await _userRepository.GetById(id);
            if (user == null) return false;

            user.Username = updateUserDto.Username;
            user.Email = updateUserDto.Email;

            await _userRepository.Update(user);
            return true;
        }

        public async Task<bool> DeleteUser(int id)
        {
            var user = await _userRepository.GetById(id);
            if (user == null) return false;

            await _userRepository.Delete(user);
            return true;
        }
    }
}" > "Services/UserService.cs"

# Add User controller
mkdir -p "Controllers"
printf "%s" "using Microsoft.AspNetCore.Mvc;
using ${PROJECT_NAME}.Services;
using ${PROJECT_NAME}.Contracts;

namespace ${PROJECT_NAME}.Controllers
{
    [ApiController]
    [Route(\"api/[controller]\")]
    public class UserController : ControllerBase
    {
        private readonly IUserService _userService;

        public UserController(IUserService userService)
        {
            _userService = userService;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<UserDto>>> GetUsers()
        {
            var users = await _userService.GetAllUsers();
            return Ok(users);
        }

        [HttpGet(\"{id}\")]
        public async Task<ActionResult<UserDto>> GetUser(int id)
        {
            var user = await _userService.GetUserById(id);
            if (user == null)
            {
                return NotFound();
            }
            return Ok(user);
        }

        [HttpPost]
        public async Task<ActionResult<UserDto>> CreateUser(CreateUserDto createUserDto)
        {
            var user = await _userService.CreateUser(createUserDto);
            return CreatedAtAction(nameof(GetUser), new { id = user.Id }, user);
        }

        [HttpPut(\"{id}\")]
        public async Task<IActionResult> UpdateUser(int id, UpdateUserDto updateUserDto)
        {
            var result = await _userService.UpdateUser(id, updateUserDto);
            if (!result)
            {
                return NotFound();
            }
            return NoContent();
        }

        [HttpDelete(\"{id}\")]
        public async Task<IActionResult> DeleteUser(int id)
        {
            var result = await _userService.DeleteUser(id);
            if (!result)
            {
                return NotFound();
            }
            return NoContent();
        }
    }
}" > "Controllers/UserController.cs" 