//
//  UserEvent.swift
//  App
//
//  Created by Jussi Suojanen on 05/08/2019.
//

import Vapor
import FluentMySQL

/// Combines User to Events
final class UserEvent: Codable {
    var id: Int?
    var userId: Int
    var eventId: Int

    init(userId: Int, eventId: Int) {
        self.userId = userId
        self.eventId = eventId
    }

    init(id: Int?, userId: Int, eventId: Int) {
        self.id = id
        self.userId = userId
        self.eventId = eventId
    }
}

extension UserEvent: MySQLModel {}
extension UserEvent: Parameter {}
extension UserEvent: Content {}
extension UserEvent: Migration {
    static func prepare(on conn: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: conn) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.userId, to: \User.id)
            builder.reference(from: \.eventId, to: \Event.id)
        }
    }
}

