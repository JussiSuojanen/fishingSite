import FluentMySQL
import Vapor

public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    try services.register(FluentMySQLProvider())

    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)


    var middlewares = MiddlewareConfig()
    middlewares.use(ErrorMiddleware.self)
    services.register(middlewares)

    var databases = DatabasesConfig()
    let databaseConfig = MySQLDatabaseConfig(
        hostname: Environment.get("DB_HOSTNAME")!,
        username: Environment.get("DB_USER")!,
        password: Environment.get("DB_PASSWORD")!,
        database: Environment.get("DB_DATABASE")!
    )

    let database = MySQLDatabase(config: databaseConfig)
    databases.add(database: database, as: .mysql)
    services.register(database)

    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .mysql)
    services.register(migrations)
}
