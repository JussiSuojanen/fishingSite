//
//  DoubleExtension.swift
//  App
//
//  Created by Jussi Suojanen on 06/10/2019.
//

import Foundation

extension Double {
    func roundTo2Decimal() -> Double {
        return (self * 100).rounded() / 100
    }
}
