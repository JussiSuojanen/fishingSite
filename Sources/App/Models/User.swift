//
//  User.swift
//  App
//
//  Created by Jussi Suojanen on 27/06/2019.
//

import Vapor
import FluentMySQL

final class User: Codable {
    var id: Int?
    var username: String
    var password: String

    init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    init(id: Int?, username: String, password: String) {
        self.id = id
        self.username = username
        self.password = password
    }

    final class Public: Codable {
        var id: Int?
        var username: String

        init(id: Int?, username: String) {
            self.id = id
            self.username = username
        }
    }
}

extension User: MySQLModel {}
extension User: Parameter {}
extension User: Migration {}
extension User: Content {}
extension User.Public: Content {}

extension User {
    func toPublic() -> User.Public {
        return User.Public(id: id, username: username)
    }
}

extension Future where T: User {
    func toPublic() -> Future<User.Public> {
        return map(to: User.Public.self) { user in
            return user.toPublic()
        }
    }
}
