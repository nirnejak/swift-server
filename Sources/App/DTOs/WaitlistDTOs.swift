import Vapor

// Request DTOs
struct CreateWaitlistRequest: Content {
    let name: String
    let email: String
    let isJoined: Bool?
}

struct UpdateWaitlistRequest: Content {
    let name: String?
    let email: String?
    let isJoined: Bool?
}

// Response DTOs
struct WaitlistResponse: Content {
    let id: UUID
    let name: String
    let email: String
    let isJoined: Bool
    let createdAt: Date?

    init(from waitlist: Waitlist) throws {
        guard let id = waitlist.id else {
            throw Abort(.internalServerError, reason: "Waitlist missing ID")
        }
        self.id = id
        self.name = waitlist.name
        self.email = waitlist.email
        self.isJoined = waitlist.isJoined
        self.createdAt = waitlist.createdAt
    }
}