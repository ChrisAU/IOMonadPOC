//
//  Database.swift
//  Core
//
//  Created by Chris Nevin on 08/03/2019.
//  Copyright © 2019 Chris Nevin. All rights reserved.
//

import Foundation

public protocol Database {
    func objects<T: DatabaseObjectsObservable>(ofType type: T.Type) -> Observable<[T], ReadError>
    func read<T: DatabaseReadable>(id: String, ofType: T.Type) -> Result<T, ReadError>
    func write<T: DatabaseWritable>(_ value: T, for id: String) -> Result<Void, WriteError>
}

public protocol DatabaseObjectsObservable: DatabaseReadable {
    static func objects() -> Observable<[Self], ReadError>
}

public protocol DatabaseReadable {
    static func canRead() -> Bool
    static func read(id: String) -> Self?
}

public protocol DatabaseWritable {
    func write(for id: String) -> Bool
}

// MARK: Laws

extension Database {
    public func writeRead<T: DatabaseReadable & DatabaseWritable & Equatable>(_ value: T, for id: String) -> Bool {
        guard case .success = write(value, for: id) else { return false }
        guard case .success(let match) = read(id: id, ofType: T.self) else { return false }
        return match == value
    }
}

