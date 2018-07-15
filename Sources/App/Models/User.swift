import Foundation
import Vapor
import FluentPostgreSQL

final class User: Codable {
    var id: UUID?
    var name: String
    var username: String
    var password: String
    
    init(name: String, username: String, password: String) {
        self.name = name
        self.username = username
        self.password = password
    }
    
    final class Public: Codable {
        var id: UUID?
        var name: String
        var username: String
        
        init(id: UUID?, name: String, username: String) {
            self.id = id
            self.name = name
            self.username = username
        }
    }
}

// MARK: - PostgreSQLUUIDModel
extension User: PostgreSQLUUIDModel {}

// MARK: - Content
extension User: Content {}
extension User.Public: Content {}

// MARK: - Migration
extension User: Migration {
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.unique(on: \.username) // Add a unique index to username
        }
    }
}

// MARK: - Parameter
extension User: Parameter {}

// MARK: - Helpers
extension User {
    func toPublic() -> User.Public {
        return User.Public(id: id, name: name, username: username)
    }
}

extension Future where T: User {
    func toPublic() -> Future<User.Public> {
        return map(to: User.Public.self) { (user) in
            return user.toPublic()
        }
    }
}
