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
        authSessionRoutes.get("event", use: eventHandler)
        authSessionRoutes.post(EventPostData.self, at: "event", use: eventPostHandler)
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
            username: userData.email,
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
        let context: RegisterContext
        if let message = req.query[String.self, at: "message"] {
            context = RegisterContext(message: message)
        } else {
            context = RegisterContext()
        }

        return try req.view().render("register", context)
    }

    func registerPostHandler(_ req: Request, data: RegisterData) throws -> Future<Response> {
        do {
            try data.validate()
        } catch (let error) {
            let redirect: String
            if let error = error as? ValidationError,
                let message = error.reason.addingPercentEncoding(
                    withAllowedCharacters: .urlQueryAllowed) {
                redirect = "/register?message=\(message)"
            } else {
                redirect = "/register?message=Unknown+error"
            }
            return req.future(req.redirect(to: redirect))
        }

        let password = try BCrypt.hash(data.password)
        let user = User(email: data.email, username: data.username, password: password)

        return user.save(on: req).map(to: Response.self) { user in
            try req.authenticateSession(user)

            return req.redirect(to: "/")
        }
    }

    func eventHandler(_ req: Request) throws -> Future<View> {
        return try req.view().render("event", EventContext())
    }

    func eventPostHandler(_ req: Request, data: EventPostData) throws -> Future<Response> {
        // TODO: Should handle unique event name error?
        let user = try req.requireAuthenticated(User.self)

        let event = Event(name: data.name, code: data.code)
        return event
            .save(on: req)
            .map(to: UserEvent.self) { event in
                guard let userId = user.id, let eventId = event.id else {
                    throw Abort(.badRequest, reason: "Could not create event: \(event.name)")
                }
                return UserEvent(userId: userId, eventId: eventId)
            }
            .save(on: req)
            .map(to: Response.self) { userEvent in
                // TODO: change / to the event created page with correct content!
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
    let userLoggedIn: Bool

    init(loginError: Bool = false, userLoggedIn: Bool = false) {
        self.loginError = loginError
        self.userLoggedIn = userLoggedIn
    }
}

struct LoginPostData: Content {
    let email: String
    let password: String
}

struct RegisterContext: Encodable {
    let title = "Register"
    let message: String?
    let userLoggedIn: Bool

    init(message: String? = nil, userLoggedIn: Bool = false) {
        self.message = message
        self.userLoggedIn = userLoggedIn
    }
}

struct RegisterData: Content {
    let email: String
    let username: String
    let password: String
    let confirmPassword: String
}

extension RegisterData: Validatable, Reflectable {
    static func validations() throws
        -> Validations<RegisterData> {
            var validations = Validations(RegisterData.self)
            try validations.add(\.email, .email)
            try validations.add(\.username,
                .alphanumeric && .count(2...))
            try validations.add(\.password, .count(5...))

            validations.add("passwords match") { model in
                guard model.password == model.confirmPassword else {
                    throw BasicValidationError("passwords don’t match")
                }
            }
            return validations
    }
}

struct EventContext: Encodable {
    let title = "Create new event"
}

struct EventPostData: Content {
    let name: String
    let code: String
}
