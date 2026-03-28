import Foundation
import SwiftUI
import UserNotifications

@MainActor
final class PhoneNotificationOverlayStore: ObservableObject {
    private let holdDuration: Duration = .seconds(5)
    private let fadeDuration: Duration = .seconds(1)

    @Published private(set) var currentMessage: String?
    @Published private(set) var isVisible = false
    @Published private(set) var presentationID = UUID()

    private var dismissTask: Task<Void, Never>?
    private var activeToken = UUID()

    deinit {
        dismissTask?.cancel()
    }

    func present(from content: UNNotificationContent) {
        let title = content.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = content.body.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = [title, body]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !message.isEmpty else { return }

        dismissTask?.cancel()

        let token = UUID()
        activeToken = token
        presentationID = UUID()
        currentMessage = message
        isVisible = false

        Task { @MainActor [weak self] in
            await Task.yield()
            guard let self, self.activeToken == token else { return }
            self.isVisible = true
        }

        dismissTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: self.holdDuration)
            guard !Task.isCancelled else { return }
            await self.dismiss(using: token)
        }
    }

    func dismissIfVisible() {
        guard currentMessage != nil else { return }
        dismissTask?.cancel()

        let token = activeToken
        dismissTask = Task { [weak self] in
            guard let self else { return }
            await self.dismiss(using: token)
        }
    }

    private func dismiss(using token: UUID) async {
        await MainActor.run {
            guard self.activeToken == token else { return }
            self.isVisible = false
        }

        try? await Task.sleep(for: fadeDuration)
        guard !Task.isCancelled else { return }
        await MainActor.run {
            guard self.activeToken == token else { return }
            self.currentMessage = nil
        }
    }
}
