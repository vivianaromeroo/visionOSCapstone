//
//  AppModel.swift
//  EchoPathNew
//
//  Created by Admin2  on 4/22/25.
//

import SwiftUI

/// Maintains app-wide state
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
    
    // User data
    var child: Child?
    var preferences: Preferences?
    var welcomeMessage: String?
}
