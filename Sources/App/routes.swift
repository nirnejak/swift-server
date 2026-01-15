import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "Hello, World!"
    }

    app.get("hello", ":name") { req async throws -> String in
        let name = req.parameters.get("name")!
        return "Hello, \(name)!"
    }

    app.post("data") { req async throws -> String in
        let data = try req.content.decode(MyData.self)
        return "Received: \(data.message)"
    }

    // Waitlist routes
    let waitlistController = WaitlistController()
    let waitlistRoutes = app.grouped("waitlist")

    waitlistRoutes.get(use: waitlistController.getAllWaitlistEntries)
    waitlistRoutes.post(use: waitlistController.createWaitlistEntry)
    waitlistRoutes.get(":id", use: waitlistController.getWaitlistEntry)
    waitlistRoutes.put(":id", use: waitlistController.updateWaitlistEntry)
    waitlistRoutes.delete(":id", use: waitlistController.deleteWaitlistEntry)
}

struct MyData: Content {
    let message: String
}