import Foundation
import Vision

final class RepCounter {
    enum Stage {
        case up
        case down
    }

    private(set) var count = 0
    private(set) var stage: Stage = .up
    private var shoulderAtTop: CGFloat?
    private var lastRepDate = Date.distantPast
    private var missingFrames = 0

    private let downAngle: CGFloat = 95
    private let upAngle: CGFloat = 160
    private let minimumShoulderTravel: CGFloat = 0.10

    var detectedBody: Bool {
        missingFrames < 30
    }

    func process(_ observation: VNHumanBodyPoseObservation) -> Bool {
        guard let side = preferredSide(observation) else {
            missingFrames += 1
            return false
        }
        missingFrames = 0

        guard let shoulder = point(observation, side.shoulder),
              let elbow = point(observation, side.elbow),
              let wrist = point(observation, side.wrist) else {
            missingFrames += 1
            return false
        }

        let angle = Self.angle(shoulder, elbow, wrist)
        switch stage {
        case .up:
            if angle < downAngle {
                stage = .down
                shoulderAtTop = shoulder.y
            }
        case .down:
            if angle > upAngle {
                let travel = abs((shoulderAtTop ?? shoulder.y) - shoulder.y)
                let now = Date()
                let fastEnough = now.timeIntervalSince(lastRepDate) > 0.45
                if travel >= minimumShoulderTravel && fastEnough {
                    count += 1
                    lastRepDate = now
                    stage = .up
                    return true
                }
                stage = .up
            }
        }
        return false
    }

    struct JointSet {
        let shoulder: VNHumanBodyPoseObservation.JointName
        let elbow: VNHumanBodyPoseObservation.JointName
        let wrist: VNHumanBodyPoseObservation.JointName
    }

    private func preferredSide(_ observation: VNHumanBodyPoseObservation) -> JointSet? {
        let right = JointSet(shoulder: .rightShoulder, elbow: .rightElbow, wrist: .rightWrist)
        let left = JointSet(shoulder: .leftShoulder, elbow: .leftElbow, wrist: .leftWrist)
        if confidence(observation, right) >= confidence(observation, left) {
            return confidence(observation, right) > 0 ? right : nil
        }
        return confidence(observation, left) > 0 ? left : nil
    }

    private func confidence(_ observation: VNHumanBodyPoseObservation, _ set: JointSet) -> Float {
        guard let points = try? observation.recognizedPoints(.all) else { return 0 }
        let values = [set.shoulder, set.elbow, set.wrist].compactMap { points[$0]?.confidence }
        return values.reduce(0, +)
    }

    private func point(_ observation: VNHumanBodyPoseObservation, _ joint: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
        guard let points = try? observation.recognizedPoints(.all),
              let recognized = points[joint], recognized.confidence > 0.3 else { return nil }
        return CGPoint(x: recognized.location.x, y: recognized.location.y)
    }

    static func angle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGFloat {
        let ab = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        let cb = CGVector(dx: c.x - b.x, dy: c.y - b.y)
        let dot = ab.dx * cb.dx + ab.dy * cb.dy
        let magnitude = sqrt(ab.dx * ab.dx + ab.dy * ab.dy) * sqrt(cb.dx * cb.dx + cb.dy * cb.dy)
        guard magnitude > 0 else { return 180 }
        let cosine = max(-1, min(1, dot / magnitude))
        return acos(cosine) * 180 / .pi
    }
}
