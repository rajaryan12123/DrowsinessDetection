//
//  ViewController.swift
//  DrowsinessDetection
//
//  Created by Raj Aryan on 22/03/23.
//

import UIKit
import AVFoundation
import Vision
import Gifu

class ViewController: UIViewController {

    
    var faceDetectorFilter: FaceDetectorFilter!
    lazy var faceDetector: FaceDetector = {
        var detector = FaceDetector()
        self.faceDetectorFilter = FaceDetectorFilter(faceDetector: detector, delegate: self)
        detector.delegate = self.faceDetectorFilter
        return detector
    }()
    
    
    lazy var helpImage: UIImageView = {
        var temp = UIImageView(frame: CGRect(x: 0,
                                             y: 0,
                                             width: UIScreen.main.bounds.width,
                                             height: UIScreen.main.bounds.height))
        temp.contentMode = .scaleAspectFit
        temp.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        temp.alpha = 0.0
        temp.image = UIImage(named: "Ready.png")
        return temp
    }()
    
    lazy var rightEyeGif: GIFImageView = {
        let temp = GIFImageView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width / 2.1, height: UIScreen.main.bounds.height / 7.1))  //150x80
        temp.alpha = 0.0
        temp.animate(withGIFNamed: "rightEye_Opening.gif", loopCount: 1)
        temp.contentMode = .scaleAspectFit
        return temp
    }()
    
    lazy var leftEyeGif: GIFImageView = {
        let temp = GIFImageView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width / 2.1, height: UIScreen.main.bounds.height / 7.1)) //150x80
        temp.alpha = 0.0
        temp.animate(withGIFNamed: "leftEye_Opening.gif", loopCount: 1)
        temp.contentMode = .scaleAspectFit
        return temp
    }()
    
    
    internal func spaceString(_ string: String) -> String {
        return string.uppercased().map({ c in "\(c) " }).joined()
    }
    
    var blinkingNumber: Int = 0
    
    @IBOutlet weak var previewView: UIView!
    // AVCapture variables to hold camera content
    var session: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var captureDevice: AVCaptureDevice?
    
    // Layer UI for drawing Vision results
    var rootLayer: CALayer?
    private var faceLayers: [CAShapeLayer] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        self.session = self.setupAVCaptureSession()
//
//        self.session?.startRunning()
        faceDetector.beginFaceDetection()
        let cameraView = faceDetector.cameraView
        view.addSubview(cameraView)
        view.addSubview(leftEyeGif)
        view.addSubview(rightEyeGif)
        view.addSubview(helpImage)
    }

    fileprivate func setupAVCaptureSession() -> AVCaptureSession? {
        let captureSession = AVCaptureSession()
        
        do {
            let captureDevice = try self.configureFrontCamera(for: captureSession)
            self.configureVideoDataOutput(for: captureDevice, captureSession: captureSession)
            self.designatePreviewLayer(for: captureSession)
            return captureSession
        } catch let excutionError as NSError {
            print("excutionError: ", excutionError.localizedDescription)
        } catch {
            print("An unexpected failure has occured")
        }
        
        self.teardownAVCapture()

        return nil
    }
    

    fileprivate func configureFrontCamera(for captureSession: AVCaptureSession) throws -> AVCaptureDevice {
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            fatalError("No front video camera available")
        }
        
        if let deviceInput = try? AVCaptureDeviceInput(device: camera) {
            if captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
            }
            
            return camera
        }
        
        throw NSError(domain: "ViewController", code: 1, userInfo: nil)
    }
    
    fileprivate func configureVideoDataOutput(for inputDevice: AVCaptureDevice, captureSession: AVCaptureSession) {
        
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        let videoDataOutputQueue = DispatchQueue(label: "camera.queue")
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
        videoDataOutput.connection(with: .video)?.isEnabled = true
        
        if let captureConnection = videoDataOutput.connection(with: .video) {
            if captureConnection.isCameraIntrinsicMatrixDeliverySupported {
                captureConnection.isCameraIntrinsicMatrixDeliveryEnabled = true
            }
            captureConnection.videoOrientation = .portrait
        }
        
        self.captureDevice = inputDevice
    }
    
    fileprivate func designatePreviewLayer(for captureSession: AVCaptureSession) {
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer = videoPreviewLayer

        videoPreviewLayer.name = "CameraPreview"
        videoPreviewLayer.backgroundColor = UIColor.black.cgColor
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        if let previewRootLayer = self.previewView?.layer {
            self.rootLayer = previewRootLayer
            previewRootLayer.masksToBounds = true
            videoPreviewLayer.frame = previewRootLayer.bounds
            previewRootLayer.addSublayer(videoPreviewLayer)
        }
        
    }
    
    
    fileprivate func teardownAVCapture() {
        if let previewLayer = self.previewLayer {
            previewLayer.removeFromSuperlayer()
            self.previewLayer = nil
        }
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                self.faceLayers.forEach { drawing in
                    drawing.removeFromSuperlayer()
                }
                if let observations = request.results as? [VNFaceObservation] {
                    self.handleFaceDetectionObservations(observations: observations)
                }
            }
        })
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .leftMirrored, options: [:])
        
        do {
            try imageRequestHandler.perform([faceDetectionRequest])
        } catch {
            print("perform fail, error: ", error.localizedDescription)
        }
    }
    fileprivate func handleFaceDetectionObservations(observations: [VNFaceObservation]) {
        for observation in observations {
            if let previewLayer = self.previewLayer {
                let faceRectConverted = previewLayer.layerRectConverted(fromMetadataOutputRect: observation.boundingBox)
                let faceRectanglePath = CGPath(rect: faceRectConverted, transform: nil)
                
                let faceLayer = CAShapeLayer()
                faceLayer.path = faceRectanglePath
                faceLayer.fillColor = UIColor.clear.cgColor
                faceLayer.strokeColor = UIColor.yellow.cgColor
                
                self.faceLayers.append(faceLayer)
                self.view.layer.addSublayer(faceLayer)
            }
        }
    }
}


extension ViewController: FaceDetectorFilterDelegate {
    //MARK: FaceDetectorFilter Delegate
    func faceDetected() {
        cancel()
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5, animations: {
                self.leftEyeGif.alpha = 1.0
                self.rightEyeGif.alpha = 1.0
            })
        }
    }
    
    func faceUnDetected() {
        cancel()
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3, animations: {
                self.leftEyeGif.alpha = 0
                self.rightEyeGif.alpha = 0
            })
        }
    }
    
    func faceEyePosition(left: CGPoint, right: CGPoint) {
        if let leftPos = self.faceDetector.leftEyePosition, let rightPos = self.faceDetector.rightEyePosition {
            DispatchQueue.main.async {
                self.leftEyeGif.center = leftPos
                self.rightEyeGif.center = rightPos
                
                //better center eyes position based on gif file
                self.leftEyeGif.frame.origin.y -= 4
                self.rightEyeGif.frame.origin.y -= 4
            }
        }
    }
    
    func cancel() {
        rightEyeGif.animate(withGIFNamed: "rightEye_Opening.gif", loopCount: 1)
        leftEyeGif.animate(withGIFNamed: "leftEye_Opening.gif", loopCount: 1)
        
    }
    
    //MARK: Eye distance should be CGFloat(70.0)
    //MARK: if bliking is true then this method will trigger and you will receive an image here
    // Here
    func blinking(image: UIImage?) {
        if blinkingNumber == 0 {
            blinkingNumber += 1
            showBlinkNumber(helpString: "Ready.png")
        } else if blinkingNumber == 1 {
            blinkingNumber += 1
            showBlinkNumber(helpString: "Ready1.png")
        } else {
            blinkingNumber += 1
            showBlinkNumber(helpString: "Ready3.png")
        }
    }
    
    func showBlinkNumber(helpString: String){
        UIView.animate(withDuration: 0.8, animations: {
            self.helpImage.image = UIImage(named: helpString)
            self.helpImage.alpha = 1.0
            self.helpImage.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }, completion: {(_) in
            UIView.animate(withDuration: 1.0, animations: {
                self.helpImage.alpha = 0.0
                self.helpImage.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            }, completion: {(_) in
                self.helpImage.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            })
        })
    }
}
