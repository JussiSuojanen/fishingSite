//
//  EventUserPivot.swift
//  App
//
//  Created by Jussi Suojanen on 05/08/2019.
//

import Vapor
import FluentMySQL

/// Combines Events ands Users | Sibling - Many-to-Many relationship
final class EventUserPivot: MySQLPivot {
    var id: Int?
    var userId: User.ID
    var eventId: Event.ID

    typealias Left = User
    typealias Right = Event

    static let leftIDKey: LeftIDKey = \.userId
    static let rightIDKey: RightIDKey = \.eventId

    init(_ user: User, _ event: Event) throws {
        self.userId = try user.requireID()
        self.eventId = try event.requireID()
    }
}

extension EventUserPivot: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(
                from: \.userId,
                to: \User.id,
                onDelete: .cascade)

            builder.reference(
                from: \.eventId,
                to: \Event.id,
                onDelete: .cascade)
        }
    }
}
extension EventUserPivot: ModifiablePivot {}
