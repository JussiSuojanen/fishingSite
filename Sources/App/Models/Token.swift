//
//  Token.swift
//  App
//
//  Created by Jussi Suojanen on 27/06/2019.
//

import Foundation
import Vapor
import FluentMySQL
import Authentication

final class Token: Codable {
    var id: Int?
    var token: String
    var userID: User.ID

    init(token: String, userID: User.ID) {
        self.token = token
        self.userID = userID
    }
}

extension Token: MySQLModel {}
extension Token: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.userID, to: \User.id)
        }
    }
}
extension Token: Content {}

extension Token {
    static func generate(for user: User) throws -> Token {
        let random = try CryptoRandom().generateData(count: 16)
        return try Token(
            token: random.base64EncodedString(),
            userID: user.requireID()
        )
    }
}

extension Token: Authentication.Token {
    typealias UserType = User

    static let userIDKey: UserIDKey = \Token.userID
}

extension Token: BearerAuthenticatable {
    static let tokenKey: TokenKey = \Token.token
}
