//
//  DeeplinkExampleHandler.swift
//  CladsExamples
//
//  Handles deeplinks for the CLADS examples feature.
//

import CoreContracts
import Foundation
import UIKit

/// Handles deeplinks for the examples feature.
/// Example URLs:
/// - ghost://dashboard/examples/sheet?title=Hello&message=World
/// - ghost://dashboard/examples/sheet?title=Welcome
public final class DeeplinkExampleHandler: DeeplinkHandler {

    // MARK: - Properties

    public let feature = "examples"

    private weak var navigationService: NavigationService?

    // MARK: - Initialization

    public init(navigationService: NavigationService) {
        self.navigationService = navigationService
    }

    // MARK: - DeeplinkHandler

    @MainActor
    public func handle(_ deeplink: Deeplink) async -> Bool {
        print("[ExamplesDeeplink] Handling deeplink: \(deeplink)")

        guard deeplink.action == "sheet" else {
            print("[ExamplesDeeplink] Unknown action: \(deeplink.action ?? "nil")")
            return false
        }

        let title = deeplink.parameter("title") ?? "Deeplink Sheet"
        let message = deeplink.parameter("message") ?? "This sheet was opened via a deeplink!"

        print("[ExamplesDeeplink] Presenting sheet with title: \(title)")

        // Get the current view controller (tab switch already completed by router)
        guard let viewController = navigationService?.currentViewController else {
            print("[ExamplesDeeplink] No current view controller to present on")
            return false
        }

        let sheetVC = DeeplinkSheetViewController(title: title, message: message)

        if let sheet = sheetVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }

        viewController.present(sheetVC, animated: true)
        return true
    }
}
