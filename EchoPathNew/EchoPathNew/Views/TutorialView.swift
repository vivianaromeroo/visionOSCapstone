import SwiftUI
import AVKit
import Combine

struct TutorialView: View {
    let animal: String
    @State private var player: AVPlayer?
    @State private var isVideoFinished: Bool = false
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 1) {
                    Spacer()
                    
                    if let player = player {
                        VideoPlayer(player: player)
                            .frame(width: 800, height: 600)
                            .cornerRadius(30)
                            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                    } else {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 800, height: 600)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            )
                    }
                    
                    if isVideoFinished {
                        NavigationLink(destination: GameView(animal: animal)) {
                            Text("Continue")
                                .frame(maxWidth: .infinity)
                                .font(.system(size: 35))
                        }
                        .buttonStyle(PastelPrimaryButtonStyle())
                        .padding(.horizontal, 40)
                        .padding(.bottom, 60)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 10)
            }
        }
        .onAppear {
            loadVideo()
        }
        .onDisappear {
            player?.pause()
            cancellables.removeAll()
        }
    }
    
    private func loadVideo() {
        guard let videoURL = Bundle.main.url(forResource: "Tutorial-VEED", withExtension: "mp4") else {
            print("❌ Tutorial video not found")
            isVideoFinished = true
            return
        }
        
        player = AVPlayer(url: videoURL)
        
        if let currentItem = player?.currentItem {
            NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: currentItem)
                .sink { _ in
                    isVideoFinished = true
                }
                .store(in: &cancellables)
        }
        
        player?.play()
    }
}

#Preview {
    TutorialView(animal: "Dog")
}

