//
//  FaceDetect.swift
//  DrowsinessDetection
//
//  Created by Raj Aryan on 19/04/23.
//

import UIKit
import CoreImage
import AVFoundation
import ImageIO
import AudioToolbox

enum FaceDetectorEvent {
    case noFaceDetected
    case faceDetected
    case smiling
    case notSmiling
    case blinking
    case notBlinking
    case winking
    case notWinking
    case leftEyeClosed
    case leftEyeOpen
    case rightEyeClosed
    case rightEyeOpen
}

protocol FaceDetectorDelegate {
    func faceDetectorEvent(_ events: [FaceDetectorEvent], image: UIImage?)
}

class FaceDetector: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var delegate: FaceDetectorDelegate?
    
    var cameraView: UIView = UIView()
    var cameraViewBonds: CGRect!
    
    
    fileprivate var isLeftEyeClosed = false
       fileprivate var isRightEyeClosed = false
       fileprivate var eyeClosedTimer = 0.0
    
    
    //Private properties of the detected face that can be accessed (read-only) by other classes.
    fileprivate(set) var faceDetected  = false
    fileprivate(set) var hasSmile = false
    fileprivate(set) var isBlinking = false
    fileprivate(set) var isWinking = false
    fileprivate(set) var leftEyeClosed = false
    fileprivate(set) var rightEyeClosed = false
    fileprivate(set) var faceBounds: CGRect?
    fileprivate(set) var faceAngle: CGFloat?
    fileprivate(set) var faceAngleDifference: CGFloat?
    fileprivate(set) var leftEyePosition: CGPoint?
    fileprivate(set) var rightEyePosition: CGPoint?
    fileprivate(set) var eyesDistance: CGFloat?
    fileprivate(set) var mouthPosition: CGPoint?
    
    //Private variables that cannot be accessed by other classes in any way.
    fileprivate let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyHigh,  CIDetectorTracking: true] as [String : Any]
    fileprivate var detector : CIDetector?
    fileprivate var videoDataOutput : AVCaptureVideoDataOutput?
    fileprivate var videoDataOutputQueue : DispatchQueue?
    fileprivate var cameraPreviewLayer : AVCaptureVideoPreviewLayer?
    fileprivate var captureSession : AVCaptureSession = AVCaptureSession()
    fileprivate var currentOrientation : Int?
    
    override init()  {
        super.init()
        
        captureSetup(AVCaptureDevice.Position.front)
        detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy : CIDetectorAccuracyHigh as AnyObject])
    }
    
    //MARK: SETUP OF VIDEOCAPTURE
    func beginFaceDetection() {
        self.captureSession.startRunning()
    }
    
    func endFaceDetection() {
        self.captureSession.stopRunning()
    }
    
    fileprivate func captureSetup (_ position : AVCaptureDevice.Position) {
        var captureError : NSError?
        
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: .video, position: AVCaptureDevice.Position.front).devices
        
        if devices.count > 0 {
            let captureDevice = devices[0]
            var deviceInput : AVCaptureDeviceInput?
            do {
                deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            } catch let error as NSError {
                captureError = error
                deviceInput = nil
            }
            captureSession.sessionPreset = AVCaptureSession.Preset.high
            
            if captureError == nil {
                if captureSession.canAddInput(deviceInput!) {
                    captureSession.addInput(deviceInput!)
                }
                
                self.videoDataOutput = AVCaptureVideoDataOutput()
                self.videoDataOutput!.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: Int(kCVPixelFormatType_32BGRA)]
                self.videoDataOutput!.alwaysDiscardsLateVideoFrames = true
                self.videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue", attributes: [])
                self.videoDataOutput!.setSampleBufferDelegate(self, queue: self.videoDataOutputQueue!)
                
                if captureSession.canAddOutput(self.videoDataOutput!) {
                    captureSession.addOutput(self.videoDataOutput!)
                }
            }
            
            cameraView.frame = UIScreen.main.bounds
            cameraViewBonds = cameraView.bounds
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = UIScreen.main.bounds
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            cameraView.layer.addSublayer(previewLayer)
        }
    }
    var blinkingNumber: Int = 0
    var options : [String : AnyObject]?
    //MARK: CAPTURE-OUTPUT/ANALYSIS OF FACIAL-FEATURES
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let opaqueBuffer = Unmanaged<CVImageBuffer>.passUnretained(imageBuffer!).toOpaque()
        let pixelBuffer = Unmanaged<CVPixelBuffer>.fromOpaque(opaqueBuffer).takeUnretainedValue()
        let sourceImage = CIImage(cvPixelBuffer: pixelBuffer, options: nil)
        let image : UIImage = self.convert(cmage: sourceImage)
        //options = [CIDetectorSmile : true as AnyObject, CIDetectorEyeBlink: true as AnyObject, CIDetectorImageOrientation : 5 as AnyObject]  //6
        options = [CIDetectorEyeBlink: true as AnyObject, CIDetectorImageOrientation : 5 as AnyObject]  //6
        
        let features = self.detector!.features(in: sourceImage, options: options)
        
        var delegateEvents = [FaceDetectorEvent]()
        let systemSoundID: SystemSoundID = 1052
        // Check if left eye is closed
                if leftEyeClosed {
                    if isLeftEyeClosed {
                        // Increment timer if eye is still closed
                        eyeClosedTimer += 1.0/60.0 // Assuming video framerate is 60 fps
                        if eyeClosedTimer > 3.0 {
                            // Eyes closed for more than 3 seconds, do something
//                            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                            
                           
                            AudioServicesPlaySystemSound(systemSoundID)
                            print("Eyes closed for more than 3 seconds")
                        }
                    } else {
                        // Reset timer if eye was open previously
                        eyeClosedTimer = 0.0
                        isLeftEyeClosed = true
                        delegateEvents.append(.leftEyeClosed)
                    }
                } else {
                    eyeClosedTimer = 0.0
                    isLeftEyeClosed = false
                    delegateEvents.append(.leftEyeOpen)
                }
                
                // Check if right eye is closed
                if rightEyeClosed {
                    if isRightEyeClosed {
                        // Increment timer if eye is still closed
                        eyeClosedTimer += 1.0/60.0 // Assuming video framerate is 60 fps
                        if eyeClosedTimer > 3.0 {
                            // Eyes closed for more than 3 seconds, do something
                            
                            AudioServicesPlaySystemSound(systemSoundID)
                            
                            print("Eyes closed for more than 3 seconds")
                        }
                    } else {
                        // Reset timer if eye was open previously
                        eyeClosedTimer = 0.0
                        isRightEyeClosed = true
                        delegateEvents.append(.rightEyeClosed)
                    }
                } else {
                    eyeClosedTimer = 0.0
                    isRightEyeClosed = false
                    delegateEvents.append(.rightEyeOpen)
                }
                
        
        if features.count != 0 {
            if !faceDetected {
                faceDetected = true
                delegateEvents.append(.faceDetected)
            }
            
            //for feature in features as! [CIFaceFeature] {
            //Detect only the first face !!!
            let faceFeatures = features as! [CIFaceFeature]
            //print(faceFeatures.count)
            if faceFeatures.count > 0 {
                let feature = faceFeatures[0]
                faceBounds = transformFacialFeatureRect(feature.bounds, videoRect: sourceImage.extent, previewRect: cameraViewBonds, isMirrored: true)
                //print(faceBounds)
                if feature.hasFaceAngle {
                    //print(feature.hasFaceAngle)
                    if (faceAngle != nil) {
                        faceAngleDifference = CGFloat(feature.faceAngle) - faceAngle!
                    } else {
                        faceAngleDifference = CGFloat(feature.faceAngle)
                    }
                    //print(faceAngleDifference)
                    faceAngle = CGFloat(feature.faceAngle)
                    //print(faceAngle)
                }
                
                if feature.hasLeftEyePosition {
                    leftEyePosition = transformFacialFeaturePoint(feature.leftEyePosition, videoRect: sourceImage.extent, previewRect: cameraViewBonds, isMirrored: true)
                    //print(leftEyePosition)
                }
                
                if feature.hasRightEyePosition {
                    rightEyePosition = transformFacialFeaturePoint(feature.rightEyePosition, videoRect: sourceImage.extent, previewRect: cameraViewBonds, isMirrored: true)
                    //print(rightEyePosition)
                }
                
                if feature.hasMouthPosition {
                    mouthPosition = transformFacialFeaturePoint(feature.mouthPosition, videoRect: sourceImage.extent, previewRect: cameraViewBonds, isMirrored: true)
                }
                
                if let leftP = self.leftEyePosition, let rightP = self.rightEyePosition {
                    eyesDistance = leftP.distance(to: rightP)
                    //print(eyesDistance)
                }
                
                if hasSmile != feature.hasSmile {
                    if feature.hasSmile {
                        delegateEvents.append(.smiling)
                    } else {
                        delegateEvents.append(.notSmiling)
                    }
                }
                hasSmile = feature.hasSmile

                if feature.leftEyeClosed && feature.rightEyeClosed {
                    if !isBlinking {
                        if let distance =  eyesDistance, distance > CGFloat(70.0) {
                            blinkingNumber += 1
                            print("Blinking: eye distance \(distance)")
                            delegateEvents.append(.blinking)
                            isBlinking = true
                        }
                    }
                    if isWinking {
                        //print("isWinking")
                        delegateEvents.append(.notWinking)
                        isWinking = false
                    }
                    if !leftEyeClosed {
                        //print("leftEye Not Closed")
                        delegateEvents.append(.leftEyeClosed)
                        leftEyeClosed = true
                    }
                    if !rightEyeClosed {
                        //print("rightEye not Closed")
                        delegateEvents.append(.rightEyeClosed)
                        rightEyeClosed = true
                    }
                }
                else if feature.leftEyeClosed || feature.rightEyeClosed {
                    if !isWinking {
                        delegateEvents.append(.winking)
                        isWinking = true
                    }
                    if isBlinking {
                        delegateEvents.append(.notBlinking)
                        isBlinking = false
                    }
                    if feature.leftEyeClosed && !leftEyeClosed {
                        delegateEvents.append(.leftEyeClosed)
                        leftEyeClosed = true
                        if rightEyeClosed {
                            delegateEvents.append(.rightEyeOpen)
                            rightEyeClosed = false
                        }
                    }
                    else if feature.rightEyeClosed && !rightEyeClosed {
                        delegateEvents.append(.rightEyeClosed)
                        rightEyeClosed = true
                        if leftEyeClosed {
                            delegateEvents.append(.leftEyeOpen)
                            leftEyeClosed = false
                        }
                    }
                }
                else { //Both eyes opened
                    if isBlinking {
                        delegateEvents.append(.notBlinking)
                        isBlinking = false
                    }
                    if isWinking {
                        delegateEvents.append(.notWinking)
                        isWinking = false
                    }
                    if leftEyeClosed {
                        delegateEvents.append(.leftEyeOpen)
                        leftEyeClosed = false
                    }
                    if rightEyeClosed {
                        delegateEvents.append(.rightEyeOpen)
                        rightEyeClosed = false
                    }
                }
            }
            self.delegate?.faceDetectorEvent(delegateEvents, image: image)
        }
        else {
            if faceDetected {
                delegateEvents.append(.noFaceDetected)
                faceDetected = false
            }
            if hasSmile {
                delegateEvents.append(.notSmiling)
                hasSmile = false
            }
            if isBlinking {
                delegateEvents.append(.notBlinking)
                isBlinking = false
            }
            if isWinking {
                delegateEvents.append(.notWinking)
                isWinking = false
            }
            if leftEyeClosed {
                delegateEvents.append(.leftEyeOpen)
                leftEyeClosed = false
            }
            if rightEyeClosed {
                delegateEvents.append(.rightEyeOpen)
                rightEyeClosed = false
            }
        }
        if blinkingNumber < 1 {
            delegate?.faceDetectorEvent(delegateEvents, image: nil)
        } else if blinkingNumber == 1 {
            delegate?.faceDetectorEvent(delegateEvents, image: nil)
        } else {
            delegate?.faceDetectorEvent(delegateEvents, image: image)
        }
    }
    
    internal func transformFacialFeaturePoint(_ position: CGPoint, videoRect: CGRect, previewRect: CGRect, isMirrored: Bool) -> CGPoint {
        var featureRect = CGRect(origin: position, size: CGSize(width: 0, height: 0))
        let widthScale = previewRect.size.width / videoRect.size.height
        let heightScale = previewRect.size.height / videoRect.size.width
        
        let transform = isMirrored ? CGAffineTransform(a: 0, b: heightScale, c: -widthScale, d: 0, tx: previewRect.size.width, ty: 0) :
            CGAffineTransform(a: 0, b: heightScale, c: widthScale, d: 0, tx: 0, ty: 0)
        
        featureRect = featureRect.applying(transform)
        
        featureRect = featureRect.offsetBy(dx: previewRect.origin.x, dy: previewRect.origin.y)
        
        return featureRect.origin
    }

    internal func transformFacialFeatureRect(_ featureRect: CGRect, videoRect: CGRect, previewRect: CGRect, isMirrored: Bool) -> CGRect {
        let widthScale = previewRect.size.width / videoRect.size.height
        let heightScale = previewRect.size.height / videoRect.size.width
        
        let transform = isMirrored ? CGAffineTransform(a: 0, b: heightScale, c: -widthScale, d: 0, tx: previewRect.size.width, ty: 0) :
            CGAffineTransform(a: 0, b: heightScale, c: widthScale, d: 0, tx: 0, ty: 0)
        
        var transformedRect = featureRect.applying(transform)
        
        transformedRect = transformedRect.offsetBy(dx: previewRect.origin.x, dy: previewRect.origin.y)
        
        return transformedRect
    }
    
    // Convert CIImage to CGImage
    func convert(cmage:CIImage) -> UIImage {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
}


extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow((point.x - x), 2) + pow((point.y - y), 2))
    }
}

