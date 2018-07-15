import Vapor
import FluentPostgreSQL
import Authentication

final class Token: Codable {
    var id: UUID?
    var token: String
    var userID: User.ID
    
    init(token: String, userID: User.ID) {
        self.token = token
        self.userID = userID
    }
}

// MARK: - PostgreSQLUUIDModel
extension Token: PostgreSQLUUIDModel {}

// MARK: - Migration
extension Token: Migration {}

// MARK: - Content
extension Token: Content {}

// MARK: - BearerAuthenticatable
extension Token: BearerAuthenticatable {
    static let tokenKey: TokenKey = \Token.token
}

// MARK: - Token
extension Token: Authentication.Token {
    typealias UserType = User
    static let userIDKey: UserIDKey = \Token.userID
}

// MARK: - Helpers
extension Token {
    static func generate(for user: User) throws -> Token {
        let random = try CryptoRandom().generateData(count: 16)
        return try Token(token: random.base64EncodedString(), userID: user.requireID())
    }
}
