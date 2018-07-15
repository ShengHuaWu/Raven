import Vapor
import Crypto

struct UsersController: RouteCollection {
    func boot(router: Router) throws {
        let usersRoute = router.grouped("api", "users")
        usersRoute.post(use: createHandler)
        usersRoute.get(use: getAllHandler)
        usersRoute.get(User.parameter, use: getHandler)
        usersRoute.put(User.parameter, use: updateHandler)
        usersRoute.delete(User.parameter, use: deleteHandler)
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
        // `flatMap` here means waiting both of `req.parameter.next` and
        // `req.content.decode` finish and then executing the closure
        return try flatMap(to: User.Public.self, req.parameters.next(User.self), req.content.decode(User.self)) { (user, updatedUser) in
            user.name = updatedUser.name
            user.username = updatedUser.username
            user.password = try BCrypt.hash(updatedUser.password)
            return user.save(on: req).toPublic()
        }
    }
    
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        // `transform(to: HTTPStatus.noContent)` means converting
        // `Future<User>` to `Future<HTTPStatus>` with the value `noContent`
        return try req.parameters.next(User.self).delete(on: req).transform(to: HTTPStatus.noContent)
    }
}
