import Foundation
import Vapor
import FluentPostgreSQL

final class User: Codable {
    var id: UUID?
    var name: String
    var username: String
    
    init(name: String, username: String) {
        self.name = name
        self.username = username
    }
}

// MARK: - SQLiteUUIDModel
extension User: PostgreSQLUUIDModel {}

// MARK: - Content
extension User: Content {}

// MARK: - Migration
extension User: Migration {}

// MARK: - Parameter
extension User: Parameter {}
