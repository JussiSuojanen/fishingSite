//
//  FishController.swift
//  App
//
//  Created by Jussi Suojanen on 17/08/2019.
//

import Vapor

struct FishController: RouteCollection {
    func boot(router: Router) throws {
        let authSessionRoutes =
            router.grouped(User.authSessionsMiddleware())

        authSessionRoutes.post("singleEvent", Event.parameter, use: addNewRowHandler)
        authSessionRoutes.get("singleEvent", Event.parameter, "fish", use: fishHandler)
        authSessionRoutes.post(PostFishData.self, at: "addFish", use: postFishHandler)
        authSessionRoutes.get(Fish.parameter, "delete", use: deleteFishHandler)
    }

    func fishHandler(_ req: Request) throws -> Future<View> {
        return try req
            .parameters
            .next(Event.self)
            .flatMap(to: View.self) { event in
                return try req.view().render("fish", FishContext(event: event))
        }
    }

    func postFishHandler(_ req: Request, data: PostFishData) throws -> Future<Response> {
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
                            lengthInCm: data.lengthInCm,
                            weightInKg: data.weightInKg,
                            fisherman: data.fisherman)
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

    func addNewRowHandler(_ req: Request) throws -> Future<View> {
        //let user = try req.requireAuthenticated(User.self)
        return try req
            .parameters
            .next(Event.self)
            .flatMap(to: View.self) { event in
                return try Fish(eventId: event.requireID(),
                                fishType: "what kind of a fish?",
                                lengthInCm: 0,
                                weightInKg: 0,
                                fisherman: "who caught the fish?"
                    )
                    .save(on: req)
                    .flatMap(to: View.self) { fish in
                        return event
                            .fishes
                            .attach(fish, on: req)
                            .flatMap(to: View.self) { _ in
                                return try req
                                    .view()
                                    .render("singleEvent",
                                            SingleEventContext(
                                                event: event,
                                                fishes: event.fishes.query(on: req).all()
                                        )
                                )
                        }
                }
    }
}

struct FishContext: Encodable {
    let event: Event
}

struct PostFishData: Content {
    let eventId: Int
    let fishType: String
    let lengthInCm: Float?
    let weightInKg: Float?
    let fisherman: String
}
