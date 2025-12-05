import SwiftUI

@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
    
    var child: Child?
    var preferences: Preferences?
    var welcomeMessage: String?
    var unitName: String?
    var lessonName: String?
    var showTutorial: Bool = false
}
