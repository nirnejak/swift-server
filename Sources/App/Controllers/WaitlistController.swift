import Vapor
import Fluent

final class WaitlistController {
    private let waitlistService: WaitlistServiceProtocol

    init(waitlistService: WaitlistServiceProtocol = WaitlistService()) {
        self.waitlistService = waitlistService
    }

    func getAllWaitlistEntries(req: Request) async throws -> [WaitlistResponse] {
        try await waitlistService.getAllWaitlistEntries(on: req)
    }

    func getWaitlistEntry(req: Request) async throws -> WaitlistResponse {
        let id = try req.parameters.require("id", as: UUID.self)
        return try await waitlistService.getWaitlistEntry(id: id, on: req)
    }

    func createWaitlistEntry(req: Request) async throws -> WaitlistResponse {
        let createRequest = try req.content.decode(CreateWaitlistRequest.self)
        return try await waitlistService.createWaitlistEntry(createRequest, on: req)
    }

    func updateWaitlistEntry(req: Request) async throws -> WaitlistResponse {
        let id = try req.parameters.require("id", as: UUID.self)
        let updateRequest = try req.content.decode(UpdateWaitlistRequest.self)
        return try await waitlistService.updateWaitlistEntry(id: id, updateRequest, on: req)
    }

    func deleteWaitlistEntry(req: Request) async throws -> HTTPStatus {
        let id = try req.parameters.require("id", as: UUID.self)
        try await waitlistService.deleteWaitlistEntry(id: id, on: req)
        return .noContent
    }
}