@testable import App
import FluentPostgreSQL

extension User {
    static func create(name: String = "Luke", username: String = "luke@gmail.com", password: String = "password", on connection: PostgreSQLConnection) throws -> User {
        let user = User(name: name, username: username, password: password)
        return try user.save(on: connection).wait()
    }
}
