@testable import App
import Vapor
import FluentPostgreSQL
import Authentication

extension Application {
    static func testable(envArgs: [String]? = nil) throws -> Application {
        var config = Config.default()
        var services = Services.default()
        var env = Environment.testing
        
        if let environmentArgs = envArgs {
            env.arguments = environmentArgs
        }
        
        try App.configure(&config, &env, &services)
        let app = try Application(config: config, environment: env, services: services)
        try App.boot(app)
        
        return app
    }
    
    static func reset() throws {
        let revertEnvironmentArgs = ["vapor", "revert", "--all", "-y"]
        
        // Create an app object to run the revert command
        try Application.testable(envArgs: revertEnvironmentArgs).asyncRun().wait()
    }
    
    func sendRequest<T>(to path: String, method: HTTPMethod, headers: HTTPHeaders = .init(), body: T? = nil, loggedInRequest: Bool = false, loggedInUser: User? = nil) throws -> Response where T: Content {
        var headers = headers
        if loggedInRequest || loggedInUser != nil {
            let username: String
            if let user = loggedInUser {
                username = user.username
            } else {
                username = "admin"
            }
            
            let credentials = BasicAuthorization(username: username, password: "password")
            var tokenHeaders = HTTPHeaders()
            tokenHeaders.basicAuthorization = credentials
            
            let tokenResponse = try sendRequest(to: "api/users/login", method: .POST, headers: tokenHeaders)
            let token = try tokenResponse.content.decode(Token.self).wait()
            headers.add(name: .authorization, value: "Bearer \(token.token)")
        }
        
        let request = HTTPRequest(method: method, url: URL(string: path)!, headers: headers)
        let wrappedRequest = Request(http: request, using: self)
        
        if let body = body {
            try wrappedRequest.content.encode(body)
        }
        
        let responder = try make(Responder.self)
        return try responder.respond(to: wrappedRequest).wait()
    }
    
    // Convenience method that sends a request without body
    func sendRequest(to path: String, method: HTTPMethod, headers: HTTPHeaders = .init(), loggedInRequest: Bool = false, loggedInUser: User? = nil) throws -> Response {
        let emptyContent: EmptyContent? = nil
        return try sendRequest(to: path, method: method, headers: headers, body: emptyContent, loggedInRequest: loggedInRequest, loggedInUser: loggedInUser)
    }
    
    // Convenience method that sends a request and we don't care about the response
    func sendRequest<T>(to path: String, method: HTTPMethod, headers: HTTPHeaders, body: T, loggedInRequest: Bool = false, loggedInUser: User? = nil) throws where T: Content {
        let _ = try sendRequest(to: path, method: method, headers: headers, body: body, loggedInRequest: loggedInRequest, loggedInUser: loggedInUser)
    }
    
    func getResponse<C, T>(to path: String, method: HTTPMethod = .GET, headers: HTTPHeaders = .init(), data: C? = nil, decodeTo type: T.Type, loggedInRequest: Bool = false, loggedInUser: User? = nil) throws -> T where C: Content, T: Decodable {
        let response = try sendRequest(to: path, method: method, headers: headers, body: data, loggedInRequest: loggedInRequest, loggedInUser: loggedInUser)
        return try response.content.decode(type).wait()
    }
    
    // Convenience methods that accepts a `Decodable` type
    // to get a response without providing a body
    func getResponse<T>(to path: String, method: HTTPMethod = .GET, headers: HTTPHeaders = .init(), decodeTo type: T.Type, loggedInRequest: Bool = false, loggedInUser: User? = nil) throws -> T where T: Decodable {
        let emptyContent: EmptyContent? = nil
        return try getResponse(to: path, method: method, headers: headers, data: emptyContent, decodeTo: type, loggedInRequest: loggedInRequest, loggedInUser: loggedInUser)
    }
}

// This struct is used foe create a `nil` content,
// since `Content` has `Self` or associated type requirements,
// and we cannot define `nil` for a generic type
struct EmptyContent: Content {}
