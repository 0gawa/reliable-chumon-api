# Contributing to Restaurant Order Management API

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## 🚀 Getting Started

### Prerequisites
- Docker & Docker Compose
- Git
- Basic knowledge of Ruby on Rails and REST APIs

### Setup Development Environment

1. **Fork and Clone**
   ```bash
   git clone https://github.com/YOUR_USERNAME/reliable-chumon-api.git
   cd reliable-chumon-api
   ```

2. **Build and Setup**
   ```bash
   docker-compose build
   docker-compose run --rm web rails db:create db:migrate
   docker-compose run --rm web rails db:seed
   ```

3. **Start Services**
   ```bash
   docker-compose up
   ```

4. **Run Tests**
   ```bash
   docker-compose exec web rspec
   ```

## 💡 How to Contribute

### Reporting Bugs
- Use GitHub Issues
- Check if the issue already exists
- Provide clear steps to reproduce
- Include error messages and logs
- Specify your environment (OS, Docker version)

### Suggesting Features
- Open an issue with the `enhancement` label
- Describe the use case and expected behavior
- Consider implementation approaches

### Submitting Pull Requests

1. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Your Changes**
   - Write clean, readable code
   - Follow existing code patterns
   - Add tests for new functionality
   - Update documentation as needed

3. **Test Your Changes**
   ```bash
   # Run all tests
   docker-compose exec web rspec
   
   # Run RuboCop (linter)
   docker-compose exec web rubocop
   
   # Check specific test
   docker-compose exec web rspec spec/path/to/your_spec.rb
   ```

4. **Update API Documentation (if applicable)**
   ```bash
   # If you modified API endpoints, update integration specs
   # Then regenerate OpenAPI spec
   docker-compose exec web rails rswag:specs:swaggerize
   
   # Verify Swagger UI at http://localhost:3000/api-docs
   ```

5. **Commit Your Changes**
   ```bash
   git add .
   git commit -m "feat: Add your feature description"
   ```
   
   Follow [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat:` - New feature
   - `fix:` - Bug fix
   - `docs:` - Documentation only
   - `style:` - Code style changes (formatting)
   - `refactor:` - Code refactoring
   - `test:` - Adding tests
   - `chore:` - Maintenance tasks

6. **Push and Create PR**
   ```bash
   git push origin feature/your-feature-name
   ```
   
   Then open a Pull Request on GitHub with:
   - Clear description of changes
   - Link to related issue (if exists)
   - Screenshots (if UI changes)
   - Test results

## 📐 Code Style Guidelines

### Ruby Style
- Follow [Ruby Style Guide](https://rubystyle.guide/)
- Use RuboCop for automated style checking
- Keep lines under 120 characters
- Use meaningful variable and method names

### Architecture Patterns
This project follows specific patterns. Please maintain consistency:

#### Service Objects
Extract business logic into service objects:
```ruby
# app/services/your_service.rb
class YourService
  def initialize(params)
    @params = params
  end

  def call
    # Business logic here
  end
end
```

#### Validators
Input validation should be in separate validator classes:
```ruby
# app/validators/your_validator.rb
class YourValidator
  def validate(params)
    # Validation logic
    # Return array of error messages
  end
end
```

#### Controllers
Keep controllers thin - delegate to services:
```ruby
class YourController < ApplicationController
  def create
    service = YourService.new(params)
    result = service.call
    
    if service.success?
      render json: result, status: :created
    else
      render_validation_error(service.errors)
    end
  end
end
```

### Database
- Add migrations for schema changes
- Include indexes for frequently queried columns
- Use foreign keys for referential integrity
- Write reversible migrations when possible

### Testing

#### Test Coverage
- Maintain 100% test pass rate
- Write tests for all new features
- Include edge cases and error scenarios
- Test both success and failure paths

#### Test Types
- **Model specs**: Validations, associations, scopes
- **Service specs**: Business logic, calculations
- **Request specs**: API endpoints, integration
- **Validator specs**: Input validation

#### Example Test Structure
```ruby
RSpec.describe YourService do
  describe '#call' do
    context 'when valid input' do
      it 'returns expected result' do
        # Test success case
      end
    end

    context 'when invalid input' do
      it 'returns appropriate error' do
        # Test failure case
      end
    end
  end
end
```

### API Documentation

When adding or modifying API endpoints:

1. **Create/Update Integration Spec**
   ```ruby
   # spec/integration/admin/your_endpoint_spec.rb
   require 'swagger_helper'

   RSpec.describe 'Your API' do
     path '/api/v1/your/endpoint' do
       get 'Description' do
         tags 'Your Tag'
         produces 'application/json'
         
         response '200', 'success' do
           run_test!
         end
       end
     end
   end
   ```

2. **Regenerate OpenAPI Spec**
   ```bash
   docker-compose exec web rails rswag:specs:swaggerize
   ```

3. **Verify Swagger UI**
   - Visit http://localhost:3000/api-docs
   - Test the endpoint interactively

## 🔍 Code Review Process

### What We Look For
- ✅ Code follows style guidelines
- ✅ Tests are comprehensive and passing
- ✅ Documentation is updated
- ✅ Commits are clear and atomic
- ✅ No unnecessary dependencies added
- ✅ Performance considerations addressed

### Review Timeline
- Initial review within 2-3 days
- Feedback provided constructively
- May request changes before merging

## 📝 Documentation

### When to Update Documentation
- New API endpoints → Update integration specs
- Configuration changes → Update README
- Deployment changes → Update deployment docs
- New features → Add usage examples

### Documentation Standards
- Clear, concise language
- Include code examples
- Explain the "why", not just the "what"
- Keep examples up-to-date

## 🎯 Development Workflow

### Typical Flow
1. Pick an issue or create one
2. Comment on issue to claim it
3. Create feature branch
4. Implement feature with tests
5. Update documentation
6. Submit PR
7. Address review feedback
8. Merge!

### Docker Commands Reference
```bash
# Start services
docker-compose up

# Run tests
docker-compose exec web rspec

# Rails console
docker-compose exec web rails console

# Database migrations
docker-compose exec web rails db:migrate

# RuboCop (auto-fix)
docker-compose exec web rubocop -A

# Generate OpenAPI spec
docker-compose exec web rails rswag:specs:swaggerize

# View logs
docker-compose logs -f web

# Rebuild containers
docker-compose build
```

## 🐛 Debugging Tips

### Common Issues

**Tests Failing**:
```bash
# Reset test database
docker-compose exec web rails db:test:prepare

# Run specific test with backtrace
docker-compose exec web rspec spec/path/to/spec.rb --backtrace
```

**Database Issues**:
```bash
# Drop and recreate
docker-compose exec web rails db:drop db:create db:migrate

# Check migrations
docker-compose exec web rails db:migrate:status
```

**Container Issues**:
```bash
# Stop all containers
docker-compose down

# Remove volumes
docker-compose down -v

# Rebuild from scratch
docker-compose build --no-cache
```

## 🤝 Community

### Communication
- Open and respectful communication
- Constructive feedback
- Help others when possible
- Share knowledge

### Recognition
Contributors will be acknowledged in:
- Pull request comments
- Release notes
- Project README (if substantial contribution)

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## ❓ Questions?

- Open an issue for general questions
- Check existing issues and PRs
- Review documentation
- Ask in pull request comments

---

**Thank you for contributing! 🎉**

Every contribution, no matter how small, is valued and appreciated!
