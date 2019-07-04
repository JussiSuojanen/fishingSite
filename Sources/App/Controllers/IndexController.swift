import Vapor
import Leaf

struct IndexController: RouteCollection {

    func boot(router: Router) throws {
        router.get(use: indexHandler)
    }

    func indexHandler(_ req: Request) throws -> Future<View> {
        return try req.view().render("index")
    }
}
