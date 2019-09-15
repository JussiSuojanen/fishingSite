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
    }

    func estimateHandler(_ req: Request) throws -> Future<View> {
        return try req
            .parameters
            .next(Event.self)
            .flatMap(to: View.self) { event in
                return try req.view().render("estimate", EstimateContext(event: event))
        }
    }
}

struct EstimateContext: Encodable {
    let event: Event
}

