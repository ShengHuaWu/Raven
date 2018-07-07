import Foundation
import Vapor
import FluentSQLite

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
extension User: SQLiteUUIDModel {}

// MARK: - Content
extension User: Content {}

// MARK: - Migration
extension User: Migration {}

// MARK: - Parameter
extension User: Parameter {}
