//
//  Operators.swift
//  Core
//
//  Created by Chris Nevin on 08/03/2019.
//  Copyright © 2019 Chris Nevin. All rights reserved.
//

import Foundation

precedencegroup FlatMapPrecedence {
    associativity: left
}

infix operator >>>=: FlatMapPrecedence
