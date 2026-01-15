# AGENTS.md - Development Guidelines for Swift Server Project

This document provides comprehensive guidelines for development agents working on this Swift server project.

## Build, Lint, and Test Commands

### Primary Build Commands
- **Build project**: `swift build`
- **Run application**: `swift run`
- **Run tests**: `swift test`
- **Clean build artifacts**: `swift package clean`
- **Update dependencies**: `swift package update`

### Testing
- **Run all tests**: `swift test`
- **Run specific test**: `swift test --filter "TestClass.testMethod"`
- **Run tests with verbose output**: `swift test -v`
- **Run tests in release mode**: `swift test -c release`

### Linting and Formatting
- **Format code**: `swift-format format --configuration .swift-format --in-place Sources/`
- **Lint code**: `swift-format lint --configuration .swift-format Sources/`

## Code Style Guidelines

### General Swift Conventions
- **Indentation**: 4 spaces (no tabs)
- **Line length**: 120 characters maximum
- **Naming**:
  - Functions and variables: `camelCase`
  - Types (classes, structs, enums): `PascalCase`
  - Constants: `UPPER_SNAKE_CASE`
  - Private properties: Leading underscore optional but discouraged

### Import Organization
```swift
import Vapor
import Foundation
// Standard library imports first, then third-party, then local
```

### Function Declarations
```swift
// Good: Clear parameter names and return types
func processUserData(id: UUID, data: UserData) async throws -> ProcessedResult

// Avoid: Unclear abbreviations or missing documentation
func procUsrDt(id: UUID, dt: UserData) -> ProcessedResult
```

### Error Handling
- Use `throws` for recoverable errors
- Use `async throws` for asynchronous operations
- Prefer typed errors over generic `Error`
- Handle errors at appropriate levels

```swift
enum UserError: Error {
    case notFound
    case invalidData(String)
}

func fetchUser(id: UUID) async throws -> User {
    guard let user = try await database.getUser(id: id) else {
        throw UserError.notFound
    }
    return user
}
```

### Async/Await Patterns
```swift
// Good: Clear async function with proper error handling
app.get("users", ":id") { req async throws -> User in
    let id = try req.parameters.require("id", as: UUID.self)
    return try await userService.fetchUser(id: id)
}

// Avoid: Force unwrapping or poor error handling
app.get("users", ":id") { req -> User in
    let id = req.parameters.get("id")! // Force unwrap bad
    return userService.fetchUser(id: id) // No error handling
}
```

### Type Annotations
```swift
// Explicit types for clarity
let users: [User] = []
let completion: (Result<User, Error>) -> Void = { result in /* ... */ }

// Inferred types when obvious
let count = users.count
let filtered = users.filter { $0.isActive }
```

## Vapor Framework Patterns

### Route Handlers
```swift
// Standard route pattern
app.get("api", "v1", "users") { req async throws -> [User] in
    try await userController.getAllUsers(on: req)
}

// Parameter extraction
app.get("users", ":id") { req async throws -> User in
    let id = try req.parameters.require("id", as: UUID.self)
    return try await userController.getUser(id: id, on: req)
}

// Content decoding
app.post("users") { req async throws -> User in
    let createRequest = try req.content.decode(CreateUserRequest.self)
    return try await userController.createUser(from: createRequest, on: req)
}
```

### Content Types
```swift
// Content protocol for JSON serialization
struct CreateUserRequest: Content {
    let name: String
    let email: String
}

struct UserResponse: Content {
    let id: UUID
    let name: String
    let email: String
    let createdAt: Date
}
```

### Middleware and Configuration
```swift
// Configuration setup
func configure(_ app: Application) throws {
    // Database
    app.databases.use(.postgres(configuration: databaseConfig), as: .psql)

    // Middleware
    app.middleware.use(CORSMiddleware(configuration: corsConfig))
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))

    // Routes
    try routes(app)
}
```

## Testing Guidelines

### Test Structure
```swift
import XCTest
import Vapor
@testable import App

final class UserControllerTests: XCTestCase {
    var app: Application!

    override func setUp() async throws {
        app = try await Application.make(.testing)
        try await configure(app)
    }

    override func tearDown() async throws {
        try await app.asyncShutdown()
        app = nil
    }

    func testGetUser() async throws {
        // Test implementation
        try await app.test(.GET, "users/123") { res async in
            XCTAssertEqual(res.status, .ok)
            let user = try res.content.decode(User.self)
            XCTAssertEqual(user.name, "Expected Name")
        }
    }
}
```

### Test Naming
- `testFunctionName()` - Basic functionality
- `testFunctionName_withCondition_returnsExpectedResult()` - Specific scenarios
- `testFunctionName_throwsError_whenInvalidInput()` - Error cases

### Mocking and Fixtures
```swift
// Use test databases or in-memory stores for isolation
app.databases.use(.sqlite(.memory), as: .test)

// Or create protocol-based services for easy mocking
protocol UserService {
    func getUser(id: UUID) async throws -> User
}

final class MockUserService: UserService {
    var mockUser: User?

    func getUser(id: UUID) async throws -> User {
        guard let user = mockUser else {
            throw UserError.notFound
        }
        return user
    }
}
```

## Security Best Practices

### Input Validation
```swift
// Always validate input parameters
app.post("users") { req async throws -> User in
    let request = try req.content.decode(CreateUserRequest.self)

    // Validate required fields
    guard !request.name.isEmpty else {
        throw Abort(.badRequest, reason: "Name cannot be empty")
    }

    guard request.email.isValidEmail else {
        throw Abort(.badRequest, reason: "Invalid email format")
    }

    return try await userController.createUser(from: request, on: req)
}
```

### Authentication & Authorization
```swift
// Use middleware for auth
let protected = app.grouped(UserAuthenticator(), UserGuard())

protected.get("profile") { req async throws -> UserProfile in
    let user = try req.auth.require(User.self)
    return try await profileService.getProfile(for: user, on: req)
}
```

### Data Sanitization
- Never trust user input
- Use parameterized queries (ORM handles this automatically)
- Sanitize data before storage and display

## Performance Guidelines

### Database Optimization
```swift
// Use eager loading for related data
let users = try await User.query(on: req.db)
    .with(\.$posts)
    .all()

// Prefer batch operations
try await users.map { user in
    user.name = "Updated \(user.name)"
}.save(on: req.db)
```

### Memory Management
- Avoid retaining large objects in memory
- Use streaming for large data transfers
- Consider pagination for large result sets

### Caching Strategy
```swift
// Cache frequently accessed data
app.cache.memory.config = .init(initialCapacity: 100)
app.cache.memory.ttl = .minutes(5)

let cachedUsers = try await app.cache.get("users", as: [User].self)
```

## File Organization

### Directory Structure
```
Sources/
├── App/
│   ├── Controllers/     # Route handlers
│   ├── Models/         # Database models
│   ├── Services/       # Business logic
│   ├── Middleware/     # Custom middleware
│   ├── configure.swift # App configuration
│   ├── routes.swift    # Route definitions
│   └── main.swift      # Application entry point
Tests/
├── AppTests/
│   ├── ControllerTests/
│   ├── ModelTests/
│   └── ServiceTests/
```

### File Naming
- Controllers: `UserController.swift`
- Models: `User.swift`, `Post.swift`
- Services: `UserService.swift`
- Tests: `UserControllerTests.swift`

## Git Workflow

### Commit Messages
```
feat: add user authentication endpoint
fix: resolve memory leak in user service
docs: update API documentation
refactor: simplify user validation logic
test: add integration tests for user registration
```

### Branch Naming
- `feature/user-authentication`
- `fix/memory-leak-issue`
- `refactor/user-service-cleanup`

## Dependencies

### Core Dependencies
- **Vapor**: Web framework
- **Fluent**: ORM for database operations

### Adding Dependencies
```bash
swift package add <package-url>
# Example: swift package add https://github.com/vapor/fluent-postgres-driver.git
```

### Version Management
- Use semantic versioning for dependencies
- Pin major versions for stability
- Review dependency updates regularly

## Continuous Integration

### GitHub Actions (if configured)
- Build on all pushes and PRs
- Run tests in multiple Swift versions
- Check code formatting
- Security vulnerability scanning

### Local Development
- Run tests before pushing
- Format code with swift-format
- Ensure clean build before commits

---

*This document should be updated as the project evolves and new patterns emerge.*</content>
<parameter name="filePath">AGENTS.md