import Vapor
import Fluent
import FluentPostgresDriver

func configure(_ app: Application) throws {
    // Database configuration
    guard let databaseURL = Environment.get("DATABASE_URL") else {
        fatalError("DATABASE_URL environment variable is required")
    }
    try app.databases.use(.postgres(url: databaseURL), as: .psql)

    // Migrations
    app.migrations.add(CreateWaitlist())

    try routes(app)
}