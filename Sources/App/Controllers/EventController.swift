//
//  EventController.swift
//  App
//
//  Created by Jussi Suojanen on 07/08/2019.
//

import Vapor
import FluentMySQL

struct EventController: RouteCollection {
    func boot(router: Router) throws {
        let authSessionRoutes =
            router.grouped(User.authSessionsMiddleware())

        authSessionRoutes.get("event", use: eventHandler)
        authSessionRoutes.post(EventPostData.self, at: "event", use: eventPostHandler)
        authSessionRoutes.get("eventList", use: eventListHandler)
        authSessionRoutes.get("singleEvent", Event.parameter, use: singleEventHandler)
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

                guard let eventId = event.id else {
                    throw Abort(.badRequest, reason: "Could not create event: \(event.name)")
                }
                return try UserEvent(userId: user.requireID(), eventId: eventId)
            }
            .save(on: req)
            .map(to: Response.self) { userEvent in
                // TODO: change / to the event created page with correct content!
                return req.redirect(to: "/")
        }
    }

    func eventListHandler(_ req: Request) throws -> Future<View> {
        let user = try req.requireAuthenticated(User.self)

        return try UserEvent
            .query(on: req)
            .filter(\.userId == user.requireID())
            .all()
            .flatMap(to: View.self) { userEvents in
                return userEvents
                    .map { userEvent -> Future<Event?> in
                        return Event.query(on: req)
                            .filter(\.id == userEvent.id)
                            .first()
                    }.flatMap(to: View.self, on: req) { events in
                        return try req.view().render("eventList", EventListContext(events: events.compactMap { $0 }))
                }
        }
    }

    func singleEventHandler(_ req: Request) throws -> Future<View> {
        return try req
            .parameters
            .next(Event.self)
            .flatMap(to: View.self) { event in
                return try req
                    .view()
                    .render("singleEvent", SingleEventContext(event: event))
        }
    }

}

struct EventContext: Encodable {
    let title = "Create new event"
}

struct EventPostData: Content {
    let name: String
    let code: String
}

struct EventListContext: Encodable {
    let title = "My events"
    let events: [Event]
}

struct SingleEventContext: Encodable {
    let event: Event
}
