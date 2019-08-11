//
//  Event.swift
//  App
//
//  Created by Jussi Suojanen on 01/08/2019.
//

import Vapor
import FluentMySQL

final class Event: Codable {
    var id: Int?
    var name: String
    // Code is used to join an event. Unique in db
    var code: String

    init(name: String, code: String) {
        self.name = name
        self.code = code
    }

    init(id: Int?, name: String, code: String) {
        self.id = id
        self.name = name
        self.code = code
    }
}

extension Event {
    var users: Siblings<Event, User, EventUserPivot> {
        return siblings()
    }
}

extension Event: MySQLModel {}
extension Event: Parameter {}
extension Event: Content {}

extension Event: Migration {
    static func prepare(on conn: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: conn) { builder in
            try addProperties(to: builder)
            builder.unique(on: \.name)
        }
    }
}
