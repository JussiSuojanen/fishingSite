//
//  Estimate.swift
//  App
//
//  Created by Jussi Suojanen on 15/09/2019.
//
import Vapor
import FluentMySQL

final class Estimate: Codable {
    var id: Int?
    var eventId: Int
    var guesserName: String
    var graylingInCm: Double?
    var graylingInKg: Double?
    var troutInCm: Double?
    var troutInKg: Double?
    var salmonInCm: Double?
    var salmonInKg: Double?
    var charInCm: Double?
    var charInKg: Double?

    init(eventId: Int,
         guesserName: String,
         graylingInCm: Double?,
         graylingInKg: Double?,
         troutInCm: Double?,
         troutInKg: Double?,
         salmonInCm: Double?,
         salmonInKg: Double?,
         charInCm: Double?,
         charInKg: Double?)
    {
        self.eventId = eventId
        self.guesserName = guesserName
        self.graylingInCm = graylingInCm
        self.graylingInKg = graylingInKg
        self.troutInCm = troutInCm
        self.troutInKg = troutInKg
        self.salmonInCm = salmonInCm
        self.salmonInKg = salmonInKg
        self.charInCm = charInCm
        self.charInKg = charInKg
    }

    init(id: Int?,
         eventId: Int,
         guesserName: String,
         graylingInCm: Double?,
         graylingInKg: Double?,
         troutInCm: Double?,
         troutInKg: Double?,
         salmonInCm: Double?,
         salmonInKg: Double?,
         charInCm: Double?,
         charInKg: Double?)
    {
        self.id = id
        self.eventId = eventId
        self.guesserName = guesserName
        self.graylingInCm = graylingInCm
        self.graylingInKg = graylingInKg
        self.troutInCm = troutInCm
        self.troutInKg = troutInKg
        self.salmonInCm = salmonInCm
        self.salmonInKg = salmonInKg
        self.charInCm = charInCm
        self.charInKg = charInKg
    }
}

extension Estimate: MySQLModel {}
extension Estimate: Parameter {}
extension Estimate: Content {}

extension Estimate: Migration {
    static func prepare(on conn: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: conn) { builder in
            try addProperties(to: builder)
            builder.reference(from: \Estimate.eventId, to: \Event.id)
        }
    }
}
