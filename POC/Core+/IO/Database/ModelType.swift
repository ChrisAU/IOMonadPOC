//
//  ModelType.swift
//  POC
//
//  Created by Chris Nevin on 09/03/2019.
//  Copyright © 2019 Chris Nevin. All rights reserved.
//

import Foundation
import Core
import RealmSwift

protocol ModelType: RealmConvertible, DatabaseDeletable, DatabaseWritable, DatabaseObjectsObservable { }
protocol RealmType: ModelConvertible & Object { }

protocol ModelConvertible {
    associatedtype M: ModelType
    func asModel() -> M
}

protocol RealmConvertible {
    associatedtype R: RealmType
    func asRealm() -> R
}

extension ModelType {
    static func objects(matching query: Query<R>) -> Result<[R.M], ReadError> {
        return realmObjects(matching: query).map { $0.map { $0.asModel() } }
    }

    static func recurringObjects(matching query: Query<R>) -> Signal<[R.M], ReadError> {
        return realmRecurringObjects(matching: query).map { $0.map { $0.asModel() } }
    }

    static func canRead() -> Bool {
        return realm() != nil
    }

    static func delete(for id: String) -> Bool {
        return read(id: id)?.delete() ?? false
    }

    static func read(id: String) -> R.M? {
        return realmRead(type: R.self, id: id)?.asModel()
    }

    func write(for id: String) -> Bool {
        return realmAdd(asRealm())
    }

    func delete() -> Bool {
        return realmDelete(asRealm())
    }
}

private let realmURL = URL(for: .documentDirectory, "POC.realm")
private let realmConfig = Realm.Configuration(fileURL: realmURL, schemaVersion: 1, objectTypes: [UserObject.self])

private func realm() -> Realm? {
    return try? Realm(configuration: realmConfig)
}

private func tryRealm() -> Try<Realm> {
    return Try { try Realm(configuration: realmConfig) }
}

private func tryRealmWrite(_ closure: @escaping (Realm) throws -> Void) -> Try<Void> {
    return tryRealm().flatMap { realm in Try { try realm.write { try closure(realm) } } }
}

private func realmRead<T: Object>(type: T.Type, id: String) -> T? {
    return tryRealm()
        .map { $0.object(ofType: T.self, forPrimaryKey: id) }
        .throwIfNull()
        .materialize()
}

private func realmAdd<T: Object>(_ object: T) -> Bool {
    return tryRealmWrite({ $0.add(object, update: true) }).didSucceed()
}

private func realmDelete<T: Object>(_ object: T) -> Bool {
    return tryRealmWrite({ $0.delete(object) }).didSucceed()
}

private extension Results {
    func applying(_ query: Query<Element>) -> Results<Element> {
        let filtered = query.predicate.map(self.filter) ?? self
        let sorted = query.sort.map { ($0.key, $0.ascending) }.map(filtered.sorted) ?? filtered
        return sorted
    }
}

private func realmObjects<T: Object>(matching query: Query<T>) -> Result<[T], ReadError> {
    guard let realm = realm() else { return .failure(.notReadable) }
    return .success(Array(realm.objects(T.self).applying(query)))
}

private func realmRecurringObjects<T: Object>(matching query: Query<T>) -> Signal<[T], ReadError> {
    guard let realm = realm() else { return .error(.notReadable) }
    return Signal { (observer) -> Disposable in
        let token = realm.objects(T.self).applying(query).observe({ (change) in
            func send(_ results: Results<T>?) {
                guard let results = results else { return observer.next([]) }
                observer.next(Array(results))
            }
            switch change {
            case .initial(let initial):
                send(initial)
            case .update(let collection, _, _, _):
                send(collection)
            case .error:
                send(nil)
            }
        })
        return AnonymousDisposable {
            token.invalidate()
        }
    }
}

private extension URL {
    init(for directory: FileManager.SearchPathDirectory, _ pathComponent: String = "") {
        guard let url = FileManager.default.urls(for: directory, in: .userDomainMask).first else { fatalError() }
        self = pathComponent.isEmpty ? url : url.appendingPathComponent(pathComponent)
    }
}
