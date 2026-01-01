//
//  HandlerCollection.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/23/25.
//

// Probably a good candidate for some small standard library component
public protocol HandlerCollection {
    associatedtype EventHandler

    var handlers: [EventHandler] { get }

    mutating func add(handler: EventHandler)

    func execute(_ executeClosure: (EventHandler) -> Void)
}

public extension HandlerCollection {

    func execute(_ executeClosure: (EventHandler) -> Void) {
        handlers.forEach { handler in
            executeClosure(handler)
        }
    }
}
