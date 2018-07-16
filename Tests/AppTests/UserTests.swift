@testable import App
import Vapor
import XCTest
import FluentPostgreSQL

final class UserTests: XCTestCase {
    let usersName = "Alice"
    let usersUsername = "alice@gmail.com"
    let usersURI = "/api/users/"
    var app: Application!
    var conn: PostgreSQLConnection!
    
    override func setUp() {
        try! Application.reset() // Reverts database
        app = try! Application.testable()
        
        // Create a database connection with `wait()`,
        // since we don't want to deal with `Future` here
        conn = try! app.newConnection(to: .psql).wait()
    }
    
    override func tearDown() {
        conn.close()
    }
    
    func testUserCanBeSavedWithAPI() throws {
        let user = User(name: usersName, username: usersUsername, password: "password")
        let receivedUser = try app.getResponse(to: usersURI, method: .POST, headers: ["Content-Type": "application/json"], data: user, decodeTo: User.Public.self)
        
        XCTAssertEqual(receivedUser.name, usersName)
        XCTAssertEqual(receivedUser.username, usersUsername)
        XCTAssertNotNil(receivedUser.id)
        
        let users = try app.getResponse(to: usersURI, decodeTo: [User.Public].self)

        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users[0].name, usersName)
        XCTAssertEqual(users[0].username, usersUsername)
        XCTAssertEqual(users[0].id, receivedUser.id)
    }
    
    func testUserCanBeRetrievedFromAPI() throws {
        let user = try User.create(name: usersName, username: usersUsername, on: conn)
        _ = try User.create(on: conn)
        
        let users = try app.getResponse(to: usersURI, decodeTo: [User.Public].self)
        
        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(users[0].name, usersName)
        XCTAssertEqual(users[0].username, usersUsername)
        XCTAssertEqual(users[0].id, user.id)
    }
}
