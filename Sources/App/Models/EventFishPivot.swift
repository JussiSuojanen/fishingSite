//
//  EventFishPivot.swift
//  App
//
//  Created by Jussi Suojanen on 17/08/2019.
//

import Vapor
import FluentMySQL

/// Combines Events and Fishes | Sibling - Many-to-Many relationship
final class EventFishPivot: MySQLPivot {
    var id: Int?
    var fishId: Fish.ID
    var eventId: Event.ID

    typealias Left = Fish
    typealias Right = Event

    static let leftIDKey: LeftIDKey = \.fishId
    static let rightIDKey: RightIDKey = \.eventId

    init(_ fish: Fish, _ event: Event) throws {
        self.fishId = try fish.requireID()
        self.eventId = try event.requireID()
    }
}

extension EventFishPivot: Migration {}
extension EventFishPivot: ModifiablePivot {}
