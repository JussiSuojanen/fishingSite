//
//  UserController.swift
//  App
//
//  Created by Jussi Suojanen on 27/06/2019.
//

import Vapor
import Crypto

struct UserController: RouteCollection {
    func boot(router: Router) throws {
        let usersRoute = router.grouped("api", "users")
        usersRoute.get(use: getAllHandler)
        usersRoute.get(User.parameter, use: getOneHandler)
        usersRoute.post(use: createHandler)
        usersRoute.put(User.parameter, use: updateHandler)
        usersRoute.delete(User.parameter, use: deleteHandler)
    }

    func createHandler(_ req: Request) throws -> Future<User> {
        return try req.content.decode(User.self).flatMap { (user) in
            user.password = try BCrypt.hash(user.password)
            return user.save(on: req)
        }
    }

    func updateHandler(_ req: Request) throws -> Future<User> {
        return try flatMap(to: User.self, req.parameters.next(User.self), req.content.decode(User.self)) { (user, updatedUser) in
            user.username = updatedUser.username
            user.password = try BCrypt.hash(updatedUser.password)
            return user.save(on: req)
        }
    }

    func getAllHandler(_ req: Request) throws -> Future<[User.Public]> {
        return User.query(on: req).decode(data: User.Public.self).all()
    }

    func getOneHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.parameters.next(User.self).toPublic()
    }

    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(User.self).flatMap { (user) in
            return user.delete(on: req).transform(to: HTTPStatus.noContent)
        }
    }
}
