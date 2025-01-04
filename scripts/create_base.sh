#!/bin/bash

PROJECT_NAME=$1

# Create base repository
mkdir -p "Repositories"
printf "%s" "namespace ${PROJECT_NAME}.Repositories
{
    public interface IBaseRepository
    {
        // Add base repository methods if needed
    }

    public class BaseRepository : IBaseRepository
    {
        // Implement base repository methods
    }
}" > "Repositories/BaseRepository.cs"

# Create base service
mkdir -p "Services"
printf "%s" "namespace ${PROJECT_NAME}.Services
{
    public interface IBaseService
    {
        // Add base service methods if needed
    }

    public class BaseService : IBaseService
    {
        // Implement base service methods
    }
}" > "Services/BaseService.cs" 