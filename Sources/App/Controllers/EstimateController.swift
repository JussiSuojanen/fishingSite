//
//  EstimateController.swift
//  App
//
//  Created by Jussi Suojanen on 15/09/2019.
//

import Foundation
import Authentication

struct EstimateController: RouteCollection {
    func boot(router: Router) throws {
        let authSessionRoutes =
            router.grouped(User.authSessionsMiddleware())

        let protectedRoutes = authSessionRoutes.grouped(RedirectMiddleware<User>(path: "/login"))
        protectedRoutes.get("singleEvent", Event.parameter, "estimate", use: estimateHandler)
        protectedRoutes.post(PostEstimateData.self, at: "addEstimate", use: postEstimateHandler)
    }

    func estimateHandler(_ req: Request) throws -> Future<View> {
        return try req
            .parameters
            .next(Event.self)
            .flatMap(to: View.self) { event in
                return try req.view().render("estimate", EstimateContext(event: event))
        }
    }

    func postEstimateHandler(_ req: Request, data: PostEstimateData) throws -> Future<Response> {
        return Event
            .query(on: req)
            .filter(\.id == data.eventId)
            .first()
            .flatMap(to: Response.self) { event in
                guard let unwrappedEvent: Event = event else {
                    throw Abort(.badRequest, reason: "Internal server error, matching event not found!")
                }
                return Estimate(eventId: data.eventId,
                                guesserName: data.name,
                                graylingInCm: data.graylingInCm,
                                graylingInKg: data.graylingInKg,
                                troutInCm: data.troutInCm,
                                troutInKg: data.troutInKg,
                                salmonInCm: data.salmonInCm,
                                salmonInKg: data.salmonInKg,
                                charInCm: data.charInCm,
                                charInKg: data.charInKg)
                    .save(on: req)
                    .flatMap(to: Response.self) { estimate in
                        return unwrappedEvent.estimates.attach(estimate, on: req).map(to: Response.self) { _ in
                            return req.redirect(to: "singleEvent/\(data.eventId)")
                        }
                }
        }
    }
}

struct EstimateContext: Encodable {
    let event: Event
}

struct PostEstimateData: Content {
    let eventId: Int
    let name: String
    let graylingInCm: Float?
    let graylingInKg: Float?
    let troutInCm: Float?
    let troutInKg: Float?
    let salmonInCm: Float?
    let salmonInKg: Float?
    let charInCm: Float?
    let charInKg: Float?
}
