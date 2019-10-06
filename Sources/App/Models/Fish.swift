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
    var lengthInCm: Double
    var weightInKg: Double
    var fisherman: String
    var createdByUserId: Int?
    var editedByUserId: Int?
    var createdAt: Date?
    var updatedAt: Date?

    init(eventId: Int,
         fishType: String,
         lengthInCm: Double,
         weightInKg: Double,
         fisherman: String,
         createdByUserId: Int?)
    {
        self.eventId = eventId
        self.fishType = fishType
        self.lengthInCm = lengthInCm
        self.weightInKg = weightInKg
        self.fisherman = fisherman
        self.createdByUserId = createdByUserId
    }

    init(id: Int?,
         eventId: Int,
         fishType: String,
         lengthInCm: Double,
         weightInKg: Double,
         fisherman: String,
         createdByUserId: Int?)
    {
        self.id = id
        self.eventId = eventId
        self.fishType = fishType
        self.lengthInCm = lengthInCm
        self.weightInKg = weightInKg
        self.fisherman = fisherman
        self.createdByUserId = createdByUserId
    }
}

extension Fish: MySQLModel {
    static let createdAtKey: TimestampKey? = \.createdAt
    static let updatedAtKey: TimestampKey? = \.updatedAt
}

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
