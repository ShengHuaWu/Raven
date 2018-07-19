import Foundation
import Vapor
import FluentPostgreSQL
import Authentication

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

// MARK: - BasicAuthenticatable
extension User: BasicAuthenticatable {
    static let usernameKey: UsernameKey = \User.username
    static let passwordKey: PasswordKey = \User.password
}

// MARK: - TokenAuthenticatable
extension User: TokenAuthenticatable {
    typealias TokenType = Token
}

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

// MARK: - Admin User
// This struct is used for seed an admin user because of authentication
struct AdminUser: Migration {
    typealias Database = PostgreSQLDatabase
    
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        // Of course, using `password` isn't appropriate for production.
        // Perhaps, change this to an environment variable.
        guard let hashedPassword = try? BCrypt.hash("password") else {
            fatalError("Fail to create admin user")
        }
        
        let user = User(name: "admin", username: "admin", password: hashedPassword)
        return user.save(on: conn).transform(to: ())
    }
    
    static func revert(on conn: PostgreSQLConnection) -> Future<Void> {
        return .done(on: conn)
    }
}
