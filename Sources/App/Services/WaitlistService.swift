import Vapor
import Fluent

protocol WaitlistServiceProtocol {
    func createWaitlistEntry(_ request: CreateWaitlistRequest, on req: Request) async throws -> WaitlistResponse
    func getWaitlistEntry(id: UUID, on req: Request) async throws -> WaitlistResponse
    func getAllWaitlistEntries(on req: Request) async throws -> [WaitlistResponse]
    func updateWaitlistEntry(id: UUID, _ request: UpdateWaitlistRequest, on req: Request) async throws -> WaitlistResponse
    func deleteWaitlistEntry(id: UUID, on req: Request) async throws
}

final class WaitlistService: WaitlistServiceProtocol {
    func createWaitlistEntry(_ request: CreateWaitlistRequest, on req: Request) async throws -> WaitlistResponse {
        // Validate email format
        guard request.email.isValidEmail else {
            throw Abort(.badRequest, reason: "Invalid email format")
        }

        // Check if email already exists
        if try await Waitlist.query(on: req.db)
            .filter(\.$email == request.email)
            .first() != nil {
            throw Abort(.conflict, reason: "Email already exists in waitlist")
        }

        let waitlistEntry = Waitlist(
            name: request.name,
            email: request.email,
            isJoined: request.isJoined ?? false
        )

        try await waitlistEntry.save(on: req.db)
        return try WaitlistResponse(from: waitlistEntry)
    }

    func getWaitlistEntry(id: UUID, on req: Request) async throws -> WaitlistResponse {
        guard let waitlistEntry = try await Waitlist.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Waitlist entry not found")
        }
        return try WaitlistResponse(from: waitlistEntry)
    }

    func getAllWaitlistEntries(on req: Request) async throws -> [WaitlistResponse] {
        let waitlistEntries = try await Waitlist.query(on: req.db)
            .sort(\.$createdAt, .ascending)
            .all()

        return try waitlistEntries.map { try WaitlistResponse(from: $0) }
    }

    func updateWaitlistEntry(id: UUID, _ request: UpdateWaitlistRequest, on req: Request) async throws -> WaitlistResponse {
        guard let waitlistEntry = try await Waitlist.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Waitlist entry not found")
        }

        // Validate email if provided
        if let email = request.email {
            guard email.isValidEmail else {
                throw Abort(.badRequest, reason: "Invalid email format")
            }

            // Check if email already exists (excluding current entry)
            if try await Waitlist.query(on: req.db)
                .filter(\.$email == email)
                .filter(\.$id != id)
                .first() != nil {
                throw Abort(.conflict, reason: "Email already exists in waitlist")
            }

            waitlistEntry.email = email
        }

        if let name = request.name {
            waitlistEntry.name = name
        }

        if let isJoined = request.isJoined {
            waitlistEntry.isJoined = isJoined
        }

        try await waitlistEntry.save(on: req.db)
        return try WaitlistResponse(from: waitlistEntry)
    }

    func deleteWaitlistEntry(id: UUID, on req: Request) async throws {
        guard let waitlistEntry = try await Waitlist.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Waitlist entry not found")
        }

        try await waitlistEntry.delete(on: req.db)
    }
}

// Email validation extension
extension String {
    var isValidEmail: Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
}