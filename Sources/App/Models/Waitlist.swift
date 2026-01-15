import Fluent
import Vapor

final class Waitlist: Model, Content {
    static let schema = "waitlists"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "email")
    var email: String

    @Field(key: "is_joined")
    var isJoined: Bool

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() { }

    init(id: UUID? = nil, name: String, email: String, isJoined: Bool = false, createdAt: Date? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.isJoined = isJoined
        self.createdAt = createdAt
    }
}