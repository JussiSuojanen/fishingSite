import Vapor
import Leaf
import Authentication

struct IndexController: RouteCollection {

    func boot(router: Router) throws {
        let authSessionRoutes =
            router.grouped(User.authSessionsMiddleware())

        authSessionRoutes.get(use: indexHandler)
        authSessionRoutes.get("login", use: loginHandler)
        authSessionRoutes.post(LoginPostData.self, at: "login",
                               use: loginPostHandler)
        authSessionRoutes.post("logout", use: logoutHandler)
        authSessionRoutes.get("register", use: registerHandler)
        authSessionRoutes.post(RegisterData.self, at: "register",
                               use: registerPostHandler)
    }

    func indexHandler(_ req: Request) throws -> Future<View> {
        let userLoggedIn = try req.isAuthenticated(User.self)
        let showCookieMessage =
            req.http.cookies["cookies-accepted"] == nil
        let context = IndexContext(
            title: "Fishing site!",
            userLoggedIn: userLoggedIn,
            showCookieMessage: showCookieMessage)

        return try req.view().render("index", context)
    }

    func loginHandler(_ req: Request) throws -> Future<View> {
        let context: LoginContext

        if req.query[Bool.self, at: "error"] != nil {
            context = LoginContext(loginError: true)
        } else {
            context = LoginContext()
        }

        return try req.view().render("login", context)
    }

    func loginPostHandler(_ req: Request, userData: LoginPostData) throws -> Future<Response> {
        return User.authenticate(
            username: userData.username,
            password: userData.password,
            using: BCryptDigest(),
            on: req).map(to: Response.self) { user in
                guard let user = user else {
                    return req.redirect(to: "/login?error")
                }
                try req.authenticateSession(user)

                return req.redirect(to: "/")
        }
    }

    func logoutHandler(_ req: Request) throws -> Response {
        try req.unauthenticateSession(User.self)

        return req.redirect(to: "/")
    }

    func registerHandler(_ req: Request) throws -> Future<View> {
        let context = RegisterContext()
        return try req.view().render("register", context)
    }

    func registerPostHandler(_ req: Request, data: RegisterData) throws -> Future<Response> {
        let password = try BCrypt.hash(data.password)
        let user = User(username: data.username, password: password)

        return user.save(on: req).map(to: Response.self) { user in
            try req.authenticateSession(user)

            return req.redirect(to: "/")
        }
    }
}

struct IndexContext: Encodable {
    let title: String
    let userLoggedIn: Bool
    let showCookieMessage: Bool
}

struct LoginContext: Encodable {
    let title = "Log in"
    let loginError: Bool

    init(loginError: Bool = false) {
        self.loginError = loginError
    }
}

struct LoginPostData: Content {
    let username: String
    let password: String
}

struct RegisterContext: Encodable {
    let title = "Register"
}

struct RegisterData: Content {
    let username: String
    let password: String
    let confirmPassword: String
}
