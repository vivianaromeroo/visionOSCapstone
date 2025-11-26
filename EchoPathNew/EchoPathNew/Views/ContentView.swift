//
//  ContentView.swift
//  EchoPathNew
//
//  Created by Admin2  on 4/22/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image("StartBackground")
                    .resizable()
                    .scaledToFill()
                
                VStack {
                    HStack {
                        Spacer()

                        NavigationLink(destination: LoginView()) {
                            Image("StartButton")
                                .resizable()
                                .interpolation(.none)
                                .frame(width: 200, height: 200)
                        }
                        .padding(16)
                    }
                    Spacer()
                }
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
