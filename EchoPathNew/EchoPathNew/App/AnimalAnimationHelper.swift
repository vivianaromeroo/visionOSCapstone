//
//  AnimalAnimationHelper.swift
//  EchoPathNew
//
//  Helper for animating animal entities with transform-based animations
//

import Foundation
import RealityKit

struct AnimalAnimationHelper {
    /// Animate an entity's transform over time using interpolation
    static func animateTransform(
        entity: Entity,
        targetTransform: Transform,
        duration: TimeInterval
    ) async {
        let startTransform = entity.transform
        let steps = 60 // 60 steps per second for smooth animation
        let stepDuration = duration / Double(steps)
        
        for i in 0...steps {
            let progress = Double(i) / Double(steps)
            let t = easeInOut(progress) // Smooth easing
            
            // Interpolate position
            let startPos = startTransform.translation
            let targetPos = targetTransform.translation
            let currentPos = startPos + (targetPos - startPos) * Float(t)
            
            // Interpolate rotation (slerp)
            let currentRotation = simd_slerp(
                startTransform.rotation,
                targetTransform.rotation,
                Float(t)
            )
            
            // Interpolate scale
            let startScale = startTransform.scale
            let targetScale = targetTransform.scale
            let currentScale = startScale + (targetScale - startScale) * Float(t)
            
            // Apply transform
            entity.transform = Transform(
                scale: currentScale,
                rotation: currentRotation,
                translation: currentPos
            )
            
            try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
        }
    }
    
    /// Ease in-out curve for smooth animation
    private static func easeInOut(_ t: Double) -> Double {
        return t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
    }
}

