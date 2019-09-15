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

extension EventEstimatePivot: Migration {}
extension EventEstimatePivot: ModifiablePivot {}

