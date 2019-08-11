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

extension EventUserPivot: Migration {}
extension EventUserPivot: ModifiablePivot {}
