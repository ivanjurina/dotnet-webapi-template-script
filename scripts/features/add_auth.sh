#!/bin/bash

PROJECT_NAME=$1

# First, update the repository interface and implementation
printf "%s" "using Microsoft.EntityFrameworkCore;
using ${PROJECT_NAME}.DataModel;
using ${PROJECT_NAME}.DataModel.Entities;

namespace ${PROJECT_NAME}.Repositories
{
    public interface IUserRepository
    {
        Task<IEnumerable<User>> GetAll();
        Task<User> GetById(int id);
        Task<User> GetByUsername(string username);
        Task<User> GetByEmail(string email);
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

        public async Task<User> GetByUsername(string username)
        {
            return await _context.Users.FirstOrDefaultAsync(u => u.Username == username);
        }

        public async Task<User> GetByEmail(string email)
        {
            return await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
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

# Then create the Auth DTOs and Service
printf "%s" "using System.ComponentModel.DataAnnotations;

namespace ${PROJECT_NAME}.Contracts
{
    public class LoginDto
    {
        [Required]
        public string Username { get; set; } = string.Empty;

        [Required]
        public string Password { get; set; } = string.Empty;
    }

    public class RegisterDto
    {
        [Required]
        public string Username { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MinLength(6)]
        public string Password { get; set; } = string.Empty;
    }

    public class AuthResponseDto
    {
        public string Token { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
    }
}" > "Contracts/AuthDto.cs"

# Create Auth Service
printf "%s" "using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using ${PROJECT_NAME}.Configuration;
using ${PROJECT_NAME}.Contracts;
using ${PROJECT_NAME}.DataModel.Entities;
using ${PROJECT_NAME}.Repositories;

namespace ${PROJECT_NAME}.Services
{
    public interface IAuthService
    {
        Task<AuthResponseDto> Login(LoginDto loginDto);
        Task<AuthResponseDto> Register(RegisterDto registerDto);
    }

    public class AuthService : IAuthService
    {
        private readonly IUserRepository _userRepository;
        private readonly JwtConfig _jwtConfig;
        private readonly IPasswordHasher<User> _passwordHasher;

        public AuthService(IUserRepository userRepository, JwtConfig jwtConfig, IPasswordHasher<User> passwordHasher)
        {
            _userRepository = userRepository;
            _jwtConfig = jwtConfig;
            _passwordHasher = passwordHasher;
        }

        public async Task<AuthResponseDto> Login(LoginDto loginDto)
        {
            var user = await _userRepository.GetByUsername(loginDto.Username);
            if (user == null)
                throw new Exception(\"Invalid username or password\");

            var result = _passwordHasher.VerifyHashedPassword(user, user.PasswordHash, loginDto.Password);
            if (result == PasswordVerificationResult.Failed)
                throw new Exception(\"Invalid username or password\");

            var token = GenerateJwtToken(user);
            return new AuthResponseDto { Token = token, Username = user.Username };
        }

        public async Task<AuthResponseDto> Register(RegisterDto registerDto)
        {
            var existingUser = await _userRepository.GetByUsername(registerDto.Username);
            if (existingUser != null)
                throw new Exception(\"Username already exists\");

            var existingEmail = await _userRepository.GetByEmail(registerDto.Email);
            if (existingEmail != null)
                throw new Exception(\"Email already exists\");

            var user = new User
            {
                Username = registerDto.Username,
                Email = registerDto.Email
            };

            user.PasswordHash = _passwordHasher.HashPassword(user, registerDto.Password);
            await _userRepository.Add(user);

            var token = GenerateJwtToken(user);
            return new AuthResponseDto { Token = token, Username = user.Username };
        }

        private string GenerateJwtToken(User user)
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.ASCII.GetBytes(_jwtConfig.Secret);

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                    new Claim(ClaimTypes.Name, user.Username)
                }),
                Expires = DateTime.UtcNow.AddMinutes(_jwtConfig.ExpiryInMinutes),
                Issuer = _jwtConfig.Issuer,
                Audience = _jwtConfig.Audience,
                SigningCredentials = new SigningCredentials(
                    new SymmetricSecurityKey(key),
                    SecurityAlgorithms.HmacSha256Signature)
            };

            var token = tokenHandler.CreateToken(tokenDescriptor);
            return tokenHandler.WriteToken(token);
        }
    }
}" > "Services/AuthService.cs"

# Add Auth Controller
printf "%s" "using Microsoft.AspNetCore.Mvc;
using ${PROJECT_NAME}.Contracts;
using ${PROJECT_NAME}.Services;

namespace ${PROJECT_NAME}.Controllers
{
    [ApiController]
    [Route(\"api/[controller]\")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;

        public AuthController(IAuthService authService)
        {
            _authService = authService;
        }

        [HttpPost(\"login\")]
        public async Task<ActionResult<AuthResponseDto>> Login(LoginDto loginDto)
        {
            try
            {
                var response = await _authService.Login(loginDto);
                return Ok(response);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost(\"register\")]
        public async Task<ActionResult<AuthResponseDto>> Register(RegisterDto registerDto)
        {
            try
            {
                var response = await _authService.Register(registerDto);
                return Ok(response);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}" > "Controllers/AuthController.cs" 