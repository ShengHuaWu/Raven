import Vapor

struct UsersController: RouteCollection {
    func boot(router: Router) throws {
        let usersRoute = router.grouped("api", "users")
        usersRoute.post(use: createHandler)
        usersRoute.get(use: getAllHandler)
        usersRoute.get(User.parameter, use: getHandler)
        usersRoute.put(User.parameter, use: updateHandler)
        usersRoute.delete(User.parameter, use: deleteHandler)
    }
    
    func createHandler(_ req: Request) throws -> Future<User> {
        // `req.content.decode(User.self)` means obtaining the user from JSON body
        return try req.content.decode(User.self).save(on: req)
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[User]> {
        return User.query(on: req).all()
    }
    
    func getHandler(_ req: Request) throws -> Future<User> {
        // `req.parameters.next(User.self)` means fetching the user with id from db
        return try req.parameters.next(User.self)
    }
    
    func updateHandler(_ req: Request) throws -> Future<User> {
        // `flatMap` here means waiting both of `req.parameter.next` and
        // `req.content.decode` finish and then executing the closure
        return try flatMap(to: User.self, req.parameters.next(User.self), req.content.decode(User.self)) { (user, updatedUser) in
            user.name = updatedUser.name
            user.username = updatedUser.username
            return user.save(on: req)
        }
    }
    
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        // `transform(to: HTTPStatus.noContent)` means converting
        // `Future<User>` to `Future<HTTPStatus>` with the value `noContent`
        return try req.parameters.next(User.self).delete(on: req).transform(to: HTTPStatus.noContent)
    }
}
