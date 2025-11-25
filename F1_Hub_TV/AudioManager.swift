import AVFoundation
import SwiftUI

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    private var backgroundMusicPlayer: AVAudioPlayer?
    @Published var isMusicPlaying = false
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        #if os(tvOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Failed to set up audio session: \(error.localizedDescription)")
        }
        #endif
    }
    
    // MARK: - Background Music
    
    func playBackgroundMusic(fileName: String = "background_music", fileExtension: String = "mp3", volume: Float = 0.3) {
        guard let soundURL = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            print("⚠️ Background music file '\(fileName).\(fileExtension)' not found. Add it to your project.")
            return
        }
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: soundURL)
            backgroundMusicPlayer?.numberOfLoops = -1 // Loop indefinitely
            backgroundMusicPlayer?.volume = volume
            backgroundMusicPlayer?.prepareToPlay()
            backgroundMusicPlayer?.play()
            isMusicPlaying = true
            print("🎵 Background music playing!")
        } catch {
            print("❌ Error playing background music: \(error.localizedDescription)")
        }
    }
    
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
        isMusicPlaying = false
        print("🔇 Background music stopped")
    }
    
    func pauseBackgroundMusic() {
        backgroundMusicPlayer?.pause()
        isMusicPlaying = false
    }
    
    func resumeBackgroundMusic() {
        backgroundMusicPlayer?.play()
        isMusicPlaying = true
    }
    
    func setBackgroundMusicVolume(_ volume: Float) {
        backgroundMusicPlayer?.volume = min(max(volume, 0.0), 1.0)
    }
}
