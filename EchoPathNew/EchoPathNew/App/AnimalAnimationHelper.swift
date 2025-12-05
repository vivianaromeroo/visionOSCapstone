import Foundation
import RealityKit

struct AnimalAnimationHelper {
    static func animateTransform(
        entity: Entity,
        targetTransform: Transform,
        duration: TimeInterval
    ) async {
        let startTransform = entity.transform
        let steps = 60
        let stepDuration = duration / Double(steps)
        
        for i in 0...steps {
            let progress = Double(i) / Double(steps)
            let t = easeInOut(progress)
            
            let startPos = startTransform.translation
            let targetPos = targetTransform.translation
            let currentPos = startPos + (targetPos - startPos) * Float(t)
            
            let currentRotation = simd_slerp(
                startTransform.rotation,
                targetTransform.rotation,
                Float(t)
            )
            
            let startScale = startTransform.scale
            let targetScale = targetTransform.scale
            let currentScale = startScale + (targetScale - startScale) * Float(t)
            
            entity.transform = Transform(
                scale: currentScale,
                rotation: currentRotation,
                translation: currentPos
            )
            
            try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
        }
    }
    
    private static func easeInOut(_ t: Double) -> Double {
        return t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
    }
}

