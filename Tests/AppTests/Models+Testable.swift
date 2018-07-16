@testable import App
import FluentPostgreSQL
import Crypto

extension User {
    static func create(name: String = "Luke", username: String? = nil, on connection: PostgreSQLConnection) throws -> User {
        let createUsername: String
        if let suppliedUsername = username {
            createUsername = suppliedUsername
        } else {
            createUsername = UUID().uuidString // Ensure username is unique
        }
        
        let password = try BCrypt.hash("password")
        let user = User(name: name, username: createUsername, password: password)
        return try user.save(on: connection).wait()
    }
}
