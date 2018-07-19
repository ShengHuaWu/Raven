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
        let receivedUser = try app.getResponse(to: usersURI, method: .POST, headers: ["Content-Type": "application/json"], data: user, decodeTo: User.Public.self, loggedInRequest: true)
        
        XCTAssertEqual(receivedUser.name, usersName)
        XCTAssertEqual(receivedUser.username, usersUsername)
        XCTAssertNotNil(receivedUser.id)
        
        // Fetch users to verify
        let users = try app.getResponse(to: usersURI, decodeTo: [User.Public].self, loggedInRequest: true)

        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(users[1].name, usersName)
        XCTAssertEqual(users[1].username, usersUsername)
        XCTAssertEqual(users[1].id, receivedUser.id)
    }
    
    func testGettingASingleUserFromAPI() throws {
        let user = try User.create(name: usersName, username: usersUsername, on: conn)
        let receivedUser = try app.getResponse(to: "\(usersURI)\(user.id!)", decodeTo: User.Public.self, loggedInRequest: true)
        
        XCTAssertEqual(receivedUser.name, usersName)
        XCTAssertEqual(receivedUser.username, usersUsername)
        XCTAssertEqual(receivedUser.id, user.id)
    }
    
    func testUsersCanBeRetrievedFromAPI() throws {
        let user = try User.create(name: usersName, username: usersUsername, on: conn)
        _ = try User.create(on: conn)
        
        let users = try app.getResponse(to: usersURI, decodeTo: [User.Public].self, loggedInRequest: true)
        
        XCTAssertEqual(users.count, 3)
        XCTAssertEqual(users[1].name, usersName)
        XCTAssertEqual(users[1].username, usersUsername)
        XCTAssertEqual(users[1].id, user.id)
    }
    
    func testUserCanBeDeletedByAPI() throws {
        // Generate a user and send a delete request
        let userToBeDeleted = try User.create(on: conn)
        let _ = try app.sendRequest(to: "\(usersURI)\(userToBeDeleted.id!)", method: .DELETE, loggedInRequest: true)
        
        // Fetch users to verify
        let users = try app.getResponse(to: usersURI, decodeTo: [User.Public].self, loggedInRequest: true)

        XCTAssertEqual(users.count, 1)
    }
    
    func testUserCanBeUpdatedByAPI() throws {
        let userToBeUpdated = try User.create(on: conn)
        userToBeUpdated.name = usersName
        userToBeUpdated.username = usersUsername
        
        let user = try app.getResponse(to: "\(usersURI)\(userToBeUpdated.id!)", method: .PUT, headers: ["Content-Type": "application/json"], data: userToBeUpdated, decodeTo: User.Public.self, loggedInRequest: true)
        
        XCTAssertEqual(user.name, usersName)
        XCTAssertEqual(user.username, usersUsername)
        XCTAssertEqual(user.id, userToBeUpdated.id)
    }
    
    static var allTests = [
        ("testUserCanBeSavedWithAPI", testUserCanBeSavedWithAPI),
        ("testGettingASingleUserFromAPI", testGettingASingleUserFromAPI),
        ("testUsersCanBeRetrievedFromAPI", testUsersCanBeRetrievedFromAPI),
        ("testUserCanBeDeletedByAPI", testUserCanBeDeletedByAPI),
        ("testUserCanBeUpdatedByAPI", testUserCanBeUpdatedByAPI)
    ]
}
