import Vapor
import JWT

func routes(_ app: Application) throws {
    app.get { req in
        return req.view.render("index", ["title": "Hello Vapor!"])
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    app.get("get-Descope-User-Information") { req -> TestPayload in
        let payload = try req.jwt.verify(as: TestPayload.self)
        print(payload)
        return payload
    }
}
