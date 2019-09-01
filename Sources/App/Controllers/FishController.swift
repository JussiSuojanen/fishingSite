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
    }

    func fishHandler(_ req: Request) throws -> Future<View> {
        return try req
            .parameters
            .next(Event.self)
            .flatMap(to: View.self) { event in
                return try req.view().render("fish", FishContext(event: event))
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
}

struct FishContext: Encodable {
    let event: Event
}
