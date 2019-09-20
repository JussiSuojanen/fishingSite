//
//  Fish.swift
//  App
//
//  Created by Jussi Suojanen on 13/08/2019.
//

import Vapor
import FluentMySQL

final class Fish: Codable {
    var id: Int?
    var eventId: Int
    var fishType: String
    var lengthInCm: Float?
    var weightInKg: Float?
    var fisherman: String

    init(eventId: Int, fishType: String, lengthInCm: Float?, weightInKg: Float?, fisherman: String) {
        self.eventId = eventId
        self.fishType = fishType
        self.lengthInCm = lengthInCm
        self.weightInKg = weightInKg
        self.fisherman = fisherman
    }

    init(id: Int?, eventId: Int, fishType: String, lengthInCm: Float?, weightInKg: Float?, fisherman: String) {
        self.id = id
        self.eventId = eventId
        self.fishType = fishType
        self.lengthInCm = lengthInCm
        self.weightInKg = weightInKg
        self.fisherman = fisherman
    }
}

extension Fish: MySQLModel {}
extension Fish: Parameter {}
extension Fish: Content {}

extension Fish: Migration {
    static func prepare(on conn: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: conn) { builder in
            try addProperties(to: builder)
            builder.reference(from: \Fish.eventId, to: \Event.id)
        }
    }
}
