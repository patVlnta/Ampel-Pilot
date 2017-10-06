//
//  ViewController.swift
//  Ampel Pilot
//
//  Created by Patrick Valenta on 03.10.17.
//  Copyright © 2017 Patrick Valenta. All rights reserved.
//

import UIKit
import Vision
import AVFoundation
import CoreMedia
import VideoToolbox

class DetectionViewController: UIViewController {

    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var resultsView: UIView!
    
    let yolo = YOLO()
    var lightPhaseManager: LightPhaseManager!
    
    var videoCapture: VideoCapture!
    var request: VNCoreMLRequest!
    var startTimes: [CFTimeInterval] = []
    
    var boundingBoxes = [BoundingBox]()
    var colors: [UIColor] = []
    
    let ciContext = CIContext()
    
    var framesDone = 0
    var frameCapturingStartTime = CACurrentMediaTime()
    let semaphore = DispatchSemaphore(value: 2)
    
    lazy var zoomInButton: UIView = {
        let btn = UIButton(type: .system)
        btn.layer.cornerRadius = 5
        btn.layer.masksToBounds = true
        btn.backgroundColor = .white
        btn.tintColor = .black
        
        btn.layer.borderColor = UIColor.black.cgColor
        btn.layer.borderWidth = 0.4
        
        btn.setImage(#imageLiteral(resourceName: "plus_filled"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        
        btn.addTarget(self, action: #selector(zoomInBtnPressed), for: .touchUpInside)
        btn.isEnabled = true
        btn.alpha = 1.0
        
        return btn
        
    }()
    
    lazy var zoomOutButton: UIView = {
        let btn = UIButton(type: .system)
        btn.layer.cornerRadius = 5
        btn.layer.masksToBounds = true
        btn.backgroundColor = .white
        btn.tintColor = .black
        
        btn.layer.borderColor = UIColor.black.cgColor
        btn.layer.borderWidth = 0.4
        
        btn.setImage(#imageLiteral(resourceName: "minus_filled"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        
        btn.addTarget(self, action: #selector(zoomOutBtnPressed), for: .touchUpInside)
        btn.isEnabled = true
        btn.alpha = 1.0
        
        return btn
        
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timeLabel.text = ""
        lightPhaseManager = LightPhaseManager(confidenceThreshold: 0, maxDetections: YOLO.maxBoundingBoxes, minIOU: 0.3)
        
        setUpBoundingBoxes()
        setupView()
        setUpVision()
        setUpCamera()
        
        frameCapturingStartTime = CACurrentMediaTime()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print(#function)
    }
    
    // MARK: - UI Interactions
    
    @objc func zoomInBtnPressed() {
        self.videoCapture.zoomIn()
    }
    
    @objc func zoomOutBtnPressed() {
        self.videoCapture.zoomOut()
    }
    
    // MARK: - Initialization
    
    func setupView() {
        view.addSubview(zoomInButton)
        view.addSubview(zoomOutButton)
        
        zoomOutButton.bottomAnchor.constraint(equalTo: resultsView.topAnchor, constant: -20).isActive = true
        zoomOutButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -12).isActive = true
        zoomOutButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        zoomOutButton.widthAnchor.constraint(equalTo: zoomOutButton.heightAnchor, constant: 0).isActive = true
        
        zoomInButton.bottomAnchor.constraint(equalTo: zoomOutButton.topAnchor, constant: -12).isActive = true
        zoomInButton.rightAnchor.constraint(equalTo: zoomOutButton.rightAnchor, constant: 0).isActive = true
        zoomInButton.heightAnchor.constraint(equalTo: zoomOutButton.heightAnchor, constant: 0).isActive = true
        zoomInButton.widthAnchor.constraint(equalTo: zoomOutButton.widthAnchor, constant: 0).isActive = true
    }
    
    func setUpBoundingBoxes() {
        for _ in 0..<YOLO.maxBoundingBoxes {
            boundingBoxes.append(BoundingBox())
        }
        
        // Make colors for the bounding boxes. There is one color for each class,
        // 20 classes in total.
        colors.append(.red)
        colors.append(.green)
    }
    
    func setUpVision() {

        guard let visionModel = try? VNCoreMLModel(for: yolo.model.model) else {
            print("Error: could not create Vision model")
            return
        }
        
        request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
        
        // NOTE: If you choose another crop/scale option, then you must also
        // change how the BoundingBox objects get scaled when they are drawn.
        // Currently they assume the full input image is used.
        
        request.imageCropAndScaleOption = VNImageCropAndScaleOption.scaleFill//imageCropAndScaleOption = VNImageCropAndScaleOptionScaleFill
    }
    
    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 15
        videoCapture.setUp(sessionPreset: AVCaptureSession.Preset.hd1920x1080) { success in
            if success {
                // Add the video preview into the UI.
                if let previewLayer = self.videoCapture.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }
                
                // Add the bounding box layers to the UI, on top of the video preview.
                for box in self.boundingBoxes {
                    box.addToLayer(self.videoPreview.layer)
                }
                
                // Once everything is set up, we can start capturing live video.
                self.videoCapture.start()
            }
        }
    }
    
    // MARK: - UI stuff
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        resizePreviewLayer()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = videoPreview.bounds
    }
    
    func predictUsingVision(pixelBuffer: CVPixelBuffer) {
        // Measure how long it takes to predict a single video frame. Note that
        // predict() can be called on the next frame while the previous one is
        // still being processed. Hence the need to queue up the start times.
        startTimes.append(CACurrentMediaTime())
        
        // Vision will automatically resize the input image.
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([request])
    }
    
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
            let features = observations.first?.featureValue.multiArrayValue {
            
            let boundingBoxes = yolo.computeBoundingBoxes(features: features)
            let elapsed = CACurrentMediaTime() - startTimes.remove(at: 0)
            
            lightPhaseManager.add(predictions: boundingBoxes)

            showOnMainThread(boundingBoxes, elapsed, lightPhaseManager.determine())
        }
    }
    
    func showOnMainThread(_ boundingBoxes: [YOLO.Prediction], _ elapsed: CFTimeInterval, _ phase: LightPhaseManager.Phase) {
        DispatchQueue.main.async {
            // For debugging, to make sure the resized CVPixelBuffer is correct.
            //var debugImage: CGImage?
            //VTCreateCGImageFromCVPixelBuffer(resizedPixelBuffer, nil, &debugImage)
            //self.debugImageView.image = UIImage(cgImage: debugImage!)
            
            self.show(predictions: boundingBoxes)
            
            switch phase {
            case .red: self.resultsView.backgroundColor = UIColor.red.withAlphaComponent(0.5)
            case .green: self.resultsView.backgroundColor = UIColor.green.withAlphaComponent(0.5)
            case .none: self.resultsView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            }
            
            let fps = self.measureFPS()
            self.timeLabel.text = String(format: "Zoom \(self.videoCapture.captureDevice.videoZoomFactor)x, %.2f FPS, Phase -> \(phase.description())", fps)
            
            self.semaphore.signal()
        }
    }
    
    func measureFPS() -> Double {
        // Measure how many frames were actually delivered per second.
        framesDone += 1
        let frameCapturingElapsed = CACurrentMediaTime() - frameCapturingStartTime
        let currentFPSDelivered = Double(framesDone) / frameCapturingElapsed
        if frameCapturingElapsed > 1 {
            framesDone = 0
            frameCapturingStartTime = CACurrentMediaTime()
        }
        return currentFPSDelivered
    }
    
    func show(predictions: [YOLO.Prediction]) {
        for i in 0..<boundingBoxes.count {
            if i < predictions.count {
                let prediction = predictions[i]
                
                // The predicted bounding box is in the coordinate space of the input
                // image, which is a square image of 416x416 pixels. We want to show it
                // on the video preview, which is as wide as the screen and has a 4:3
                // aspect ratio. The video preview also may be letterboxed at the top
                // and bottom.
                let width = view.bounds.width
                let height = width * 16 / 9
                let scaleX = width / CGFloat(YOLO.inputWidth)
                let scaleY = height / CGFloat(YOLO.inputHeight)
                let top = (view.bounds.height - height) / 2
                
                // Translate and scale the rectangle to our own coordinate system.
                var rect = prediction.rect
                rect.origin.x *= scaleX
                rect.origin.y *= scaleY
                rect.origin.y += top
                rect.size.width *= scaleX
                rect.size.height *= scaleY
                
                // Show the bounding box.
                let label = String(format: "%@ %.1f", labels[prediction.classIndex], prediction.score * 100)
                let color = colors[prediction.classIndex]
                boundingBoxes[i].show(frame: rect, label: label, color: color)
            } else {
                boundingBoxes[i].hide()
            }
        }
    }

}

extension DetectionViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        // For debugging.
        //predict(image: UIImage(named: "dog416")!); return
        
        semaphore.wait()
        
        if let pixelBuffer = pixelBuffer {
            // For better throughput, perform the prediction on a background queue
            // instead of on the VideoCapture queue. We use the semaphore to block
            // the capture queue and drop frames when Core ML can't keep up.
            DispatchQueue.global().async {
                //self.predict(pixelBuffer: pixelBuffer)
                self.predictUsingVision(pixelBuffer: pixelBuffer)
            }
        }
    }
}

