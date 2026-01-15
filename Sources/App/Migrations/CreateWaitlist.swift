import Fluent

struct CreateWaitlist: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("waitlists")
            .id()
            .field("name", .string, .required)
            .field("email", .string, .required)
            .field("is_joined", .bool, .required)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("waitlists").delete()
    }
}