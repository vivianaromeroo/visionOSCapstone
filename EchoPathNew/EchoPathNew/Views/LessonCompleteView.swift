//
//  LessonCompleteView.swift
//  EchoPathNew
//
//  Created by Admin2  on 4/28/25.
//

import SwiftUI

struct LessonCompleteView: View {
    let lessonName: String
    let hasNextLesson: Bool
    let onContinue: () -> Void
    let onExit: () -> Void
    
    var body: some View {
        ZStack {
            VStack(spacing: 40) {
                Spacer()
                
                // Congratulations message
                VStack(spacing: 25) {
                    Text("🎉")
                        .font(.system(size: 100))
                    
                    Text("Congratulations!")
                        .pastelTitle()
                        .multilineTextAlignment(.center)
                    
                    Text("You completed\n\(lessonName)!")
                        .pastelSubtitle()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 60)
                }
                .padding(.vertical, 40)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 20) {
                    if hasNextLesson {
                        Button(action: onContinue) {
                            HStack(spacing: 15) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 30))
                                Text("Continue to Next Lesson")
                                    .font(.system(size: 35, weight: .semibold, design: .rounded))
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                        }
                        .buttonStyle(PastelPrimaryButtonStyle())
                    }
                    
                    Button(action: onExit) {
                        HStack(spacing: 15) {
                            Image(systemName: hasNextLesson ? "house.fill" : "checkmark.circle.fill")
                                .font(.system(size: 30))
                            Text(hasNextLesson ? "Exit to Home" : "Finish")
                                .font(.system(size: 35, weight: .semibold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                    }
                    .buttonStyle(PastelSecondaryButtonStyle(color: hasNextLesson ? .pastelPink : .pastelPurple))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .cornerRadius(20)
        .background(LinearGradient.backgroundGradient)
    }
}

#Preview(windowStyle: .automatic) {
    LessonCompleteView(
        lessonName: "Basic Actions",
        hasNextLesson: true,
        onContinue: {},
        onExit: {}
    )
}

