//
//  EventEstimatePivot.swift
//  App
//
//  Created by Jussi Suojanen on 15/09/2019.
//
import Vapor
import FluentMySQL

/// Combines Events and Estimates | Sibling - One-to-Many relationship
final class EventEstimatePivot: MySQLPivot {
    var id: Int?
    var estimateId: Estimate.ID
    var eventId: Event.ID

    typealias Left = Estimate
    typealias Right = Event

    static let leftIDKey: LeftIDKey = \.estimateId
    static let rightIDKey: RightIDKey = \.eventId

    init(_ estimate: Estimate, _ event: Event) throws {
        self.estimateId = try estimate.requireID()
        self.eventId = try event.requireID()
    }
}

extension EventEstimatePivot: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(
                from: \.estimateId,
                to: \Estimate.id,
                onDelete: .cascade)

            builder.reference(
                from: \.eventId,
                to: \Event.id,
                onDelete: .cascade)
        }
    }
}
extension EventEstimatePivot: ModifiablePivot {}

