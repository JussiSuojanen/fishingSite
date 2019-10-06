//
//  FishController.swift
//  App
//
//  Created by Jussi Suojanen on 17/08/2019.
//

import Vapor
import Authentication

struct FishController: RouteCollection {
    func boot(router: Router) throws {
        let authSessionRoutes =
            router.grouped(User.authSessionsMiddleware())
        
        let protectedRoutes = authSessionRoutes.grouped(RedirectMiddleware<User>(path: "/login"))
        protectedRoutes.get("singleEvent", Event.parameter, "fish", use: fishHandler)
        protectedRoutes.post(PostFishData.self, at: "addFish", use: postFishHandler)
        protectedRoutes.get(Fish.parameter, "delete", use: deleteFishHandler)
        protectedRoutes.get("singleEvent", "edit", Fish.parameter, use: editFishHandler)
        protectedRoutes.post("singleEvent", "edit", Fish.parameter, use: editFishPostHandler)
    }

    func fishHandler(_ req: Request) throws -> Future<View> {
        let user = try req.requireAuthenticated(User.self)
        return try req
            .parameters
            .next(Event.self)
            .flatMap(to: View.self) { event in
                return try req
                    .view()
                    .render(
                        "fish",
                        FishContext(
                            event: event,
                            message: req.query[String.self, at: "message"],
                            showFishingEvents: user.hasEvents(req: req)
                        )
                )
        }
    }

    func postFishHandler(_ req: Request, data: PostFishData) throws -> Future<Response> {
        do {
            try data.validate()
        } catch (let error) {
            let message: String = (error as? ValidationError)?.extractUrlQueryComponent() ?? "Unknown+error"
            return req.future(req.redirect(to: "/singleEvent/\(data.eventId)/fish?message=\(message)"))
        }
        let user = try req.requireAuthenticated(User.self)

        return Event
            .query(on: req)
            .filter(\.id == data.eventId)
            .first()
            .flatMap(to: Response.self) { event in
                guard let unwrappedEvent: Event = event else {
                    throw Abort(.badRequest, reason: "Internal server error, matching event not found!")
                }
                return Fish(eventId: data.eventId,
                            fishType: data.fishType,
                            lengthInCm: data.lengthInCm?.toDoubleWith2Decimal() ?? 0,
                            weightInKg: data.weightInKg?.toDoubleWith2Decimal() ?? 0,
                            fisherman: data.fisherman,
                            createdByUserId: user.id
                    )
                    .save(on: req)
                    .flatMap(to: Response.self) { fish in
                        return unwrappedEvent.fishes.attach(fish, on: req).map(to: Response.self) { _ in
                            return req.redirect(to: "singleEvent/\(data.eventId)")
                        }
                }
        }
    }

    func deleteFishHandler(_ req: Request) throws -> Future<Response> {
        return try req
            .parameters
            .next(Fish.self)
            .flatMap(to: Response.self) { fish in
                return fish
                    .delete(on: req)
                    .map(to: Response.self) { _ in
                        return req.redirect(to: "/singleEvent/\(fish.eventId)")
                }
            }
    }

    func editFishHandler(_ req: Request) throws -> Future<View> {
        let user = try req.requireAuthenticated(User.self)
        return try req
            .parameters
            .next(Fish.self)
            .flatMap { fish in
                return try req
                    .view()
                    .render("editFish", EditFishContext(
                        fish: fish,
                        showFishingEvents: user.hasEvents(req: req)
                        )
                )
        }
    }

    func editFishPostHandler(_ req: Request) throws -> Future<Response> {
        let user = try req.requireAuthenticated(User.self)

        return try flatMap(
            to: Response.self,
            req.parameters.next(Fish.self),
            req.content.decode(Fish.self)
        ) { fish, data in
            fish.fishType = data.fishType
            fish.lengthInCm = data.lengthInCm
            fish.weightInKg = data.weightInKg
            fish.fisherman = data.fisherman
            fish.editedByUserId = user.id
            return fish.save(on: req).map { _ in
                return req.redirect(to: "/singleEvent/\(fish.eventId)")
            }
        }
    }
}

struct FishContext: Encodable {
    let event: Event
    let message: String?
    let userLoggedIn = true // for unauthenticated view is not accessible
    let showFishingEvents: Future<Bool>

    init(event: Event, message: String? = nil, showFishingEvents: Future<Bool>) {
        self.event = event
        self.message = message
        self.showFishingEvents = showFishingEvents
    }
}

struct PostFishData: Content {
    let eventId: Int
    let fishType: String
    let lengthInCm: String?
    let weightInKg: String?
    let fisherman: String
}

struct EditFishContext: Encodable {
    let fish: Fish
    let userLoggedIn = true // for unauthenticated view is not accessible
    let showFishingEvents: Future<Bool>
}

extension PostFishData: Validatable, Reflectable {
    static func validations() throws
        -> Validations<PostFishData> {
            var validations = Validations(PostFishData.self)
            try validations.add(\.fishType, .characterSet(.alphanumerics + .whitespaces) && .count(2...))
            try validations.add(\.fisherman, .characterSet(.alphanumerics + .whitespaces) && .count(2...))

            return validations
    }
}
