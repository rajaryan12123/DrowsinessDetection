//
//  FaceDetectorFilter.swift
//  DrowsinessDetection
//
//  Created by Raj Aryan on 19/04/23.
//

import UIKit

enum EyesStatus {
    case nothing
    case blinking
    case left
    case right
}

protocol FaceDetectorFilterDelegate {
    func faceDetected()
    func faceUnDetected()
    func faceEyePosition(left: CGPoint, right: CGPoint)
    func cancel()
    func blinking(image: UIImage?)
    func leftWinking()
    func rightWinking()
}

extension FaceDetectorFilterDelegate {
    func leftWinking() {
        
    }
    func rightWinking(){
        
    }
}

class FaceDetectorFilter: FaceDetectorDelegate {
    
    let faceDetector: FaceDetector!
    var delegate: FaceDetectorFilterDelegate!

    var eyesStatus: EyesStatus = .nothing
    //TODO: ADD CACHED eyesStatus !!!
    var startBlinking: CFAbsoluteTime?
    var startWinking: CFAbsoluteTime?
    
    func cgPointAdd(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        return CGPoint(x: a.x + b.x, y: a.y + b.y)
    }
    
    func cgPointDivide(_ a: CGPoint, _ i: Int) -> CGPoint {
        return CGPoint(x: a.x / CGFloat(i), y: a.y / CGFloat(i))
    }
    
    var leftEyeSmoother: SequenceSmoother<CGPoint>!
    var rightEyeSmoother: SequenceSmoother<CGPoint>!
    
    init(faceDetector: FaceDetector, delegate: FaceDetectorFilterDelegate) {
        self.faceDetector = faceDetector
        self.delegate = delegate
        
        leftEyeSmoother = SequenceSmoother<CGPoint>(emptyElement:CGPoint(x: 0, y: 0), addFunc: cgPointAdd, divideFunc: cgPointDivide)
        rightEyeSmoother = SequenceSmoother<CGPoint>(emptyElement: CGPoint(x: 0, y: 0), addFunc: cgPointAdd, divideFunc: cgPointDivide)
    }
    
    func faceDetectorEvent(_ events: [FaceDetectorEvent], image: UIImage?) {
        if events.contains(.noFaceDetected) {
            startBlinking = nil
            startWinking = nil
            eyesStatus = .nothing
            DispatchQueue.main.async {
                self.delegate.faceUnDetected()
            }
        }
        
        if events.contains(.faceDetected) {
           leftEyeSmoother.resetCache()
           rightEyeSmoother.resetCache()
            
            startBlinking = nil
            startWinking = nil
            eyesStatus = .nothing
            DispatchQueue.main.async {
                self.delegate.faceDetected()
            }
        }
        
        if self.faceDetector.faceDetected {
            if let leftPos = self.faceDetector.leftEyePosition, let rightPos = self.faceDetector.rightEyePosition {
                let smoothLeftPos = leftEyeSmoother.smooth(leftPos)
                let smoothRightPos = rightEyeSmoother.smooth(rightPos)
                
                DispatchQueue.main.async {
                    self.delegate.faceEyePosition(left: smoothLeftPos, right: smoothRightPos)
                }
            }
            
            if events.contains(.blinking) {
                startBlinking = CFAbsoluteTimeGetCurrent()
                eyesStatus = .blinking
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300), execute: {
                    if self.eyesStatus == .blinking && self.startBlinking != nil && CFAbsoluteTimeGetCurrent() - self.startBlinking! > 0.2  {
                        self.delegate.blinking(image: image)
                    }
                })
            }
            else if events.contains(.notBlinking) {
                startBlinking = nil
                eyesStatus = .nothing
                DispatchQueue.main.async {
                    self.delegate.cancel()
                }
            }
            else if events.contains(.winking) {
                startWinking = CFAbsoluteTimeGetCurrent()
                if events.contains(.leftEyeClosed) {
                    eyesStatus = .left
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300), execute: {
                        if self.eyesStatus == .left && self.startWinking != nil && CFAbsoluteTimeGetCurrent() - self.startWinking! > 0.2  {
                            self.delegate.leftWinking()
                        }
                    })
                }
                else if events.contains(.rightEyeClosed) {
                    eyesStatus = .right
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300), execute: {
                        if self.eyesStatus == .right && self.startWinking != nil && CFAbsoluteTimeGetCurrent() - self.startWinking! > 0.2  {
                            self.delegate.rightWinking()
                        }
                    })
                }
            }
            else if events.contains(.notWinking) {
                startWinking = nil
                eyesStatus = .nothing
                DispatchQueue.main.async {
                    self.delegate.cancel()
                }
            }
            else {
                if  (eyesStatus == .blinking && !self.faceDetector.isBlinking) ||
                    (eyesStatus == .left && !self.faceDetector.leftEyeClosed) ||
                    (eyesStatus == .right && !self.faceDetector.rightEyeClosed) {
                    startBlinking = nil
                    startWinking = nil
                    eyesStatus = .nothing
                    DispatchQueue.main.async {
                        self.delegate.cancel()
                    }
                }
            }
        }
    }
}

