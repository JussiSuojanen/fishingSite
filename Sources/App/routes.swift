import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    let indexController = IndexController()
    try router.register(collection: indexController)

    let userController = UserController()
    try router.register(collection: userController)

    let eventController = EventController()
    try router.register(collection: eventController)

    let fishController = FishController()
    try router.register(collection: fishController)
}
