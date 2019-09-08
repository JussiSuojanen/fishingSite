//
//  EventController.swift
//  App
//
//  Created by Jussi Suojanen on 07/08/2019.
//

import Vapor
import FluentMySQL
import Authentication

struct EventController: RouteCollection {
    func boot(router: Router) throws {
        let authSessionRoutes =
            router.grouped(User.authSessionsMiddleware())
        let protectedRoutes = authSessionRoutes.grouped(RedirectMiddleware<User>(path: "/login"))
        protectedRoutes.get("event", use: eventHandler)
        protectedRoutes.get("joinEvent", use: joinEventHandler)
        protectedRoutes.post(EventPostData.self, at: "event", use: eventPostHandler)
        protectedRoutes.post(EventJoinPostData.self, at: "joinEvent", use: eventJoinPostHandler)
        protectedRoutes.get("eventList", use: eventListHandler)
        protectedRoutes.get("singleEvent", Event.parameter, use: singleEventHandler)
    }

    func eventHandler(_ req: Request) throws -> Future<View> {
        return try req.view().render("event", EventContext())
    }

    func joinEventHandler(_ req: Request) throws -> Future<View> {
        return try req.view().render("joinEvent", JoinEventContext())
    }

    func eventPostHandler(_ req: Request, data: EventPostData) throws -> Future<View> {
        // TODO: Should handle unique event name error?
        let user = try req.requireAuthenticated(User.self)

        let event = Event(name: data.name, code: data.code)
        return event
            .save(on: req)
            .flatMap(to: View.self) { _ in
                return user.events
                    .attach(event, on: req)
                    .flatMap(to: View.self) { _ in
                        return try req
                            .view()
                            .render("eventList",
                                    EventListContext(events: user.events.query(on: req).all()
                            )
                        )
                }
        }
    }

    func eventJoinPostHandler(_ req: Request, data: EventJoinPostData) throws -> Future<View> {
        let user = try req.requireAuthenticated(User.self)
        return Event
            .query(on: req)
            .filter(\.code == data.code)
            .first()
            .flatMap(to: View.self) { event in
                guard let event = event else {
                    throw Abort(.internalServerError)
                }

                return user.events
                    .attach(event, on: req)
                    .flatMap(to: View.self) { _ in
                        return try req
                            .view()
                            .render("eventList",
                                    EventListContext(events: user.events.query(on: req).all())
                        )
                }
        }
    }

    func eventListHandler(_ req: Request) throws -> Future<View> {
        let user = try req.requireAuthenticated(User.self)
        return try req
            .view()
            .render(
                "eventList",
                EventListContext(
                    events: user.events.query(on: req).all())
        )
    }

    func singleEventHandler(_ req: Request) throws -> Future<View> {
        return try req
            .parameters
            .next(Event.self)
            .flatMap(to: View.self) { event in
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

struct EventContext: Encodable {
    let title = "Create new event"
}
struct JoinEventContext: Encodable {
    let title = "Join event"
}

struct EventPostData: Content {
    let name: String
    let code: String
}

struct EventJoinPostData: Content {
    let code: String
}

struct EventListContext: Encodable {
    let title = "My events"
    let events: Future<[Event]>
}

struct SingleEventContext: Encodable {
    let event: Event
    let fishes: Future<[Fish]>
}
