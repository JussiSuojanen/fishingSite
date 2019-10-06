//
//  StringExtensions.swift
//  App
//
//  Created by Jussi Suojanen on 06/10/2019.
//

import Foundation

extension String {
    func toDoubleWith2Decimal() -> Double? {
        guard let doubleValue = NumberFormatter().number(from: self)?.doubleValue else {
            return nil
        }

        return  (doubleValue * 100).rounded() / 100;
    }
}
