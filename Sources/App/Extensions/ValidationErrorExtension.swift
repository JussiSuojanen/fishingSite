//
//  ValidationErrorExtension.swift
//  App
//
//  Created by Jussi Suojanen on 20/09/2019.
//

import Vapor
import Authentication

extension ValidationError {
    func extractUrlQueryComponent() -> String? {
        return self.reason.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed)
    }
}
