import AppKit

@MainActor protocol ReminderSoundPlaying {
    func play(_ sound: ReminderSound)
}

@MainActor final class ReminderSoundPlayer: ReminderSoundPlaying {
    private let invitation = NSSound(named: "Glass")
    private let completion = NSSound(named: "Tink")

    func play(_ sound: ReminderSound) {
        invitation?.stop()
        completion?.stop()
        let value = sound == .breakInvitation ? invitation : completion
        value?.volume = 0.35
        value?.play()
    }
}

@MainActor struct InactiveReminderSoundPlayer: ReminderSoundPlaying {
    func play(_ sound: ReminderSound) {}
}
