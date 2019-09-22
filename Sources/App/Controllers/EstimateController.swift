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
        protectedRoutes.get("deleteEstimate", Estimate.parameter, use: deleteEstimateHandler)
        protectedRoutes.get("singleEvent", "editEstimate", Estimate.parameter, use: editEstimateHandler)
        protectedRoutes.post("singleEvent", "editEstimate", Estimate.parameter, use: editEstimatePostHandler)
    }

    func estimateHandler(_ req: Request) throws -> Future<View> {
        return try req
            .parameters
            .next(Event.self)
            .flatMap(to: View.self) { event in
                return try req
                    .view()
                    .render(
                        "estimate",
                        EstimateContext(
                            event: event,
                            message: req.query[String.self, at: "message"]
                        )
                )
        }
    }

    func postEstimateHandler(_ req: Request, data: PostEstimateData) throws -> Future<Response> {
        do {
            try data.validate()
        } catch (let error) {
            let message: String = (error as? ValidationError)?.extractUrlQueryComponent() ?? "Unknown+error"
            return req.future(req.redirect(to: "/singleEvent/\(data.eventId)/estimate?message=\(message)"))
        }

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

    func deleteEstimateHandler(_ req: Request) throws -> Future<Response> {
        return try req
            .parameters
            .next(Estimate.self)
            .flatMap(to: Response.self) { estimate in
                return estimate
                    .delete(on: req)
                    .map(to: Response.self) { _ in
                        return req.redirect(to: "/singleEvent/\(estimate.eventId)")
                }
        }
    }

    func editEstimateHandler(_ req: Request) throws -> Future<View> {
        return try req
            .parameters
            .next(Estimate.self)
            .flatMap { estimate in
                return try req
                    .view()
                    .render("editEstimate", EditEstimateContext(estimate: estimate))
        }
    }


    func editEstimatePostHandler(_ req: Request) throws -> Future<Response> {
        return try flatMap(
            to: Response.self,
            req.parameters.next(Estimate.self),
            req.content.decode(Estimate.self)
        ) { estimate, data in

            estimate.guesserName = data.guesserName
            estimate.graylingInCm = data.graylingInCm
            estimate.graylingInKg = data.graylingInKg
            estimate.troutInCm = data.troutInKg
            estimate.troutInKg = data.troutInKg
            estimate.salmonInCm = data.salmonInCm
            estimate.salmonInKg = data.salmonInKg
            estimate.charInCm = data.charInCm
            estimate.charInKg = data.charInKg

            return estimate.save(on: req).map { _ in
                return req.redirect(to: "/singleEvent/\(estimate.eventId)")
            }
        }
    }
}

struct EstimateContext: Encodable {
    let event: Event
    let message: String?
    let userLoggedIn = true // for unauthenticated view is not accessible

    init(event: Event, message: String? = nil) {
        self.event = event
        self.message = message
    }
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

extension PostEstimateData: Validatable, Reflectable {
    static func validations() throws
        -> Validations<PostEstimateData> {
            var validations = Validations(PostEstimateData.self)
            try validations.add(\.name, .alphanumeric && .count(2...))

            return validations
    }
}


struct EditEstimateContext: Encodable {
    let estimate: Estimate
    let userLoggedIn = true // for unauthenticated view is not accessible
}
