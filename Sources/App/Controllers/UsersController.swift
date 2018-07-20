import Vapor
import Crypto

struct UsersController: RouteCollection {
    func boot(router: Router) throws {
        // No authentication for creating user
        let usersRoute = router.grouped("api", "users")
        usersRoute.post(use: createHandler)
        
        // Basic authentication for login
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware, guardAuthMiddleware)
        basicAuthGroup.post("login", use: loginHandler)
        
        // Token authentication for getting one, getting all, updating and deleting
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let tokenAuthGroup = usersRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.get(User.parameter, use: getHandler)
        tokenAuthGroup.get(use: getAllHandler)
        tokenAuthGroup.put(User.parameter, use: updateHandler)
        tokenAuthGroup.delete(User.parameter, use: deleteHandler)
    }
    
    func createHandler(_ req: Request) throws -> Future<User.Public> {
        // `req.content.decode(User.self)` means obtaining the user from JSON body
        return try req.content.decode(User.self).flatMap { user in
            user.password = try BCrypt.hash(user.password)
            return user.save(on: req).toPublic()
        }
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[User.Public]> {
        return User.query(on: req).decode(User.Public.self).all()
    }
    
    func getHandler(_ req: Request) throws -> Future<User.Public> {
        // `req.parameters.next(User.self)` means fetching the user with id from db
        return try req.parameters.next(User.self).toPublic()
    }
    
    func updateHandler(_ req: Request) throws -> Future<User.Public> {
        let authedUser = try req.requireAuthenticated(User.self)
        
        // `flatMap` here means waiting both of `req.parameter.next` and
        // `req.content.decode` finish and then executing the closure
        return try flatMap(to: User.Public.self, req.parameters.next(User.self), req.content.decode(User.self)) { (user, updatedUser) in
            guard authedUser.id == user.id else {
                throw Abort(.unauthorized)
            }
            
            user.name = updatedUser.name
            user.username = updatedUser.username
            user.password = try BCrypt.hash(updatedUser.password)
            return user.save(on: req).toPublic()
        }
    }
    
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        let authedUser = try req.requireAuthenticated(User.self)
        return try req.parameters.next(User.self).flatMap { (user) in
            guard authedUser.id == user.id else {
                throw Abort(.unauthorized)
            }
            
            // `transform(to: HTTPStatus.noContent)` means converting
            // `Future<User>` to `Future<HTTPStatus>` with the value `noContent`
            return user.delete(on: req).transform(to: HTTPStatus.noContent)
        }
    }
    
    func loginHandler(_ req: Request) throws -> Future<Token> {
        let user = try req.requireAuthenticated(User.self) // This saves the user’s identity in the request’s authentication cache
        let token = try Token.generate(for: user)
        return token.save(on: req)
    }
}
