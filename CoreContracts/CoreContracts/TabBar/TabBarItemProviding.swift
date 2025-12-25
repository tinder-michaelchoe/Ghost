//
//  TabBarItemProviding.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/24/25.
//

/// Protocol for contributions that provide tab bar item metadata.
public protocol TabBarItemProviding {
    var tabBarTitle: String? { get }
    var tabBarIconSystemName: String? { get }
}
