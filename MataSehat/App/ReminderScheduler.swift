import Foundation

@MainActor protocol ReminderScheduling {
    func schedule(after delay: TimeInterval, action: @escaping @MainActor () -> Void)
    func cancel()
}

@MainActor final class ReminderScheduler: ReminderScheduling {
    private var task: Task<Void, Never>?
    func schedule(after delay: TimeInterval, action: @escaping @MainActor () -> Void) {
        cancel()
        task = Task { @concurrent in
            do { try await Task.sleep(for: .seconds(max(0, delay))) }
            catch { return }
            guard !Task.isCancelled else { return }
            await action()
        }
    }
    func cancel() { task?.cancel(); task = nil }
}
