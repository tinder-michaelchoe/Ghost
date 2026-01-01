//
//  HandlerCollectionImpl.swift
//  AppFoundation
//
//  Created by mexicanpizza on 12/23/25.
//

import CoreContracts

struct HandlerGroup<EventHandler>: HandlerCollection {
    private(set) var handlers: [EventHandler] = []

    init() {}

    init(handlers: [EventHandler]) {
        self.handlers = handlers
    }

    mutating func add(handler: EventHandler) {
        handlers.append(handler)
    }
}
