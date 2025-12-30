//
//  HandlerCollectionImpl.swift
//  AppFoundation
//
//  Created by mexicanpizza on 12/23/25.
//

import CoreContracts

struct HandlerGroup<EventHandler>: HandlerCollection {
    var handlers: [EventHandler]
}
