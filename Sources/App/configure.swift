import FluentPostgreSQL
import Vapor
import Authentication

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentPostgreSQLProvider())
    try services.register(AuthenticationProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    
    var middlewares = MiddlewareConfig()
    middlewares.use(ErrorMiddleware.self)
    services.register(middlewares)
    
    // Configure a database
    var databases = DatabasesConfig()
    let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
    let username = Environment.get("DATABASE_USER") ?? "vapor"
    let password = Environment.get("DATABASE_PASSWORD") ?? "password"
    
    let databaseName: String
    let databasePort: Int
    if env == .testing {
        databaseName = "vapor-test"
        if let testPort = Environment.get("DATABASE_PORT") {
            databasePort = Int(testPort) ?? 5433
        } else {
            databasePort = 5433
        }
    } else {
        databaseName = Environment.get("DATABASE_DB") ?? "vapor"
        databasePort = 5432
    }
    
    let databaseConfig = PostgreSQLDatabaseConfig(
        hostname: hostname,
        port: databasePort,
        username: username,
        database: databaseName,
        password: password)
    let database = PostgreSQLDatabase(config: databaseConfig)
    databases.add(database: database, as: .psql)
    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: Token.self, database: .psql)
    migrations.add(migration: AdminUser.self, database: .psql)
    services.register(migrations)
    
    // Command reset database
    var commandConfig = CommandConfig.default()
    commandConfig.use(RevertCommand.self, as: "revert")
    services.register(commandConfig)
}
