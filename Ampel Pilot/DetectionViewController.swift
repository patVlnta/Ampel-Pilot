//
//  ViewController.swift
//  Ampel Pilot
//
//  Original source by hollance on 21.06.2017 @https://github.com/hollance/YOLO-CoreML-MPSNNGraph.
//

import UIKit
import Vision
import AVFoundation
import CoreMedia
import CoreMotion
import VideoToolbox


class DetectionViewController: UIViewController {

    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var resultsView: UIView!
    @IBOutlet weak var pauseScreen: UIVisualEffectView!
    
    let visualFeedbackView = VisualFeedbackView()
    
    var viewModel: DetectionViewModel!
    
    let yolo = YOLO()
    let motionManager = MotionManager()
    var lightPhaseManager: LightPhaseManager!
    
    var videoCapture: VideoCapture?
    
    var devicePitchAcceptable = true
    var request: VNCoreMLRequest!
    var startTimes: [CFTimeInterval] = []
    
    var boundingBoxes = [BoundingBox]()
    var colors: [UIColor] = []
    
    let ciContext = CIContext()
    
    var framesDone = 0
    var frameCapturingStartTime = CACurrentMediaTime()
    let semaphore = DispatchSemaphore(value: 2)
    
    private var enteringForeground = false
    
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
    
    lazy var settingsButton: UIBarButtonItem = {
        let settingsButton = UIBarButtonItem(title: NSString(string: "\u{2699}\u{0000FE0E}") as String, style: .plain, target: self, action: #selector(settingsBtnPressed))
        let font = UIFont.systemFont(ofSize: 28) // adjust the size as required
        let attributes = [NSAttributedStringKey.font : font]
        settingsButton.setTitleTextAttributes(attributes, for: .normal)
        return settingsButton
    }()
    
    let adminOverlayView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .clear
        return v
    }()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Ampelpilot"
        navigationItem.rightBarButtonItems = [settingsButton]
        
        //NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: .UIApp, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: .UIApplicationDidEnterBackground, object: nil)
        
        videoPreview.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        
        viewModel = DetectionViewModel(dataManager: DataManager())
        
        timeLabel.text = ""
        motionManager.delegate = self
        
        setupViews()
        setUpVision()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("didAppear")
         setupViewModel()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        motionManager.stop()
        videoCapture?.stop()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print(#function)
    }
    
    @objc private func willEnterForeground() {
        print("willEnterForeground")
        enteringForeground = true
    }
    
    @objc private func didBecomeActive() {
        print("didBecomeActive")
        if enteringForeground {
          setupViewModel()
        }
        enteringForeground = false
    }
    
    @objc private func didEnterBackground() {
        print("didEnterBackground")
        motionManager.stop()
        videoCapture?.stop()
    }
    
    // MARK: - UI Interactions
    
    @objc func zoomInBtnPressed() {
        self.videoCapture?.zoomIn()
    }
    
    @objc func zoomOutBtnPressed() {
        self.videoCapture?.zoomOut()
    }
    @objc func settingsBtnPressed() {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "settingsVC") as? SettingsViewController {
            vc.viewModel = SettingsViewModel(dataManager: viewModel.dataManager)
            let nv = UINavigationController(rootViewController: vc)
            nv.view.backgroundColor = .white
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // MARK: - Initialization
    
    func setupViewModel() {
        viewModel?.initFetch {
            self.lightPhaseManager = LightPhaseManager(confidenceThreshold: 0, maxDetections: YOLO.maxBoundingBoxes, minIOU: 0.3, feedback: self.viewModel.feedback)
            
            self.setUpBoundingBoxes()
            self.setupYolo()
            
            self.visualFeedbackView.isHidden = self.viewModel.devScreen
            self.videoPreview.isHidden = !self.viewModel.devScreen
            self.resultsView.isHidden = !self.viewModel.devScreen
            
            if !Platform.isSimulator {
                self.setUpCamera()
            }
        
            self.frameCapturingStartTime = CACurrentMediaTime()
        }
    }
    
    func setupViews() {
        self.pauseScreen.isHidden = true
        
        self.adminOverlayView.isHidden = true
        self.visualFeedbackView.isHidden = true
        self.pauseScreen.layer.zPosition = 99
        
        view.addSubview(adminOverlayView)
        view.addSubview(visualFeedbackView)
        
        adminOverlayView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        adminOverlayView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        adminOverlayView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        adminOverlayView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        
        visualFeedbackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        visualFeedbackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        visualFeedbackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        visualFeedbackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
    }
    
    func setUpBoundingBoxes() {
        boundingBoxes = [BoundingBox]()
        
        for _ in 0..<YOLO.maxBoundingBoxes {
            boundingBoxes.append(BoundingBox())
        }
        
        // Make colors for the bounding boxes. There is one color for each class,
        // 20 classes in total.
        colors.append(.red)
        colors.append(.green)
    }
    
    func setupYolo() {
        self.yolo.confidenceThreshold = viewModel.confidenceThreshold
        self.yolo.iouThreshold = viewModel.iouThreshold
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
        
        request.imageCropAndScaleOption = VNImageCropAndScaleOption.scaleFill
    }
    
    func setUpCamera() {
        videoCapture = nil
        
        videoCapture = VideoCapture()
        videoCapture?.delegate = self
        videoCapture?.initialZoom = CGFloat(self.viewModel.captureZoom)
        videoCapture?.fps = 15
        
        motionManager.stop()
        
        videoCapture?.setUp(sessionPreset: viewModel.capturePreset) { success in
            if success {
                // Add the video preview into the UI.
                if let layers = self.videoPreview.layer.sublayers {
                    for layer in layers {
                        layer.removeFromSuperlayer()
                    }
                }
                
                
                if self.viewModel.devScreen {
                    if let previewLayer = self.videoCapture?.previewLayer {
                        self.videoPreview.layer.addSublayer(previewLayer)
                        self.resizePreviewLayer()
                    }
                    
                    // Add the bounding box layers to the UI, on top of the video preview.
                    for box in self.boundingBoxes {
                        box.addToLayer(self.videoPreview.layer)
                    }
                }
                
                // Once everything is set up, we can start capturing live video.
                self.videoCapture?.start()
                self.motionManager.start()
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
        videoCapture?.previewLayer?.frame = videoPreview.bounds
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
            self.updateResultsLabel(phase)
            
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
    
    func updateResultsLabel(_ phase: LightPhaseManager.Phase) {
        switch phase {
        case .red: self.resultsView.backgroundColor = UIColor.red.withAlphaComponent(0.5)
        case .green: self.resultsView.backgroundColor = UIColor.green.withAlphaComponent(0.5)
        case .none: self.resultsView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        }
        
        self.visualFeedbackView.setPhase(phase)
        
        let fps = self.measureFPS()
        self.timeLabel.text = String(format: "Zoom \(self.viewModel.captureZoom)x, %.2f FPS, Phase -> \(phase.description())", fps)
    }
    
    func show(predictions: [YOLO.Prediction]) {
        if !self.viewModel.devScreen {
            return
        }
        
        for i in 0..<boundingBoxes.count {
            if i < predictions.count {
                let prediction = predictions[i]
                
                // The predicted bounding box is in the coordinate space of the input
                // image, which is a square image of 416x416 pixels. We want to show it
                // on the video preview, which is as wide as the screen and has a 4:3
                // aspect ratio. The video preview also may be letterboxed at the top
                // and bottom.
                let width = view.bounds.width
                let height = width * (self.viewModel.capturePreset == .vga640x480 ? (4 / 3) : (16 / 9))
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
    
    func videoCaptureDidStart(_ capture: VideoCapture) {
        setView(view: self.pauseScreen, hidden: true, duration: 0.15)
        setView(view: self.adminOverlayView, hidden: false, duration: 0.15)
        
        self.show(predictions: [])
        self.lightPhaseManager.currentPhase = LightPhaseManager.Phase.none
        self.updateResultsLabel(.none)
    }
    
    func videoCaptureDidStop(_ capture: VideoCapture) {
        setView(view: self.pauseScreen, hidden: false, duration: 0.15)
        setView(view: self.adminOverlayView, hidden: true, duration: 0.15)
        
        self.lightPhaseManager.feedbackManager.stop()
    }
}

extension DetectionViewController: MotionManagerDelegate {
    func didUpdate(withMotion: CMDeviceMotion) {
        let pitch = (180 / Double.pi * withMotion.attitude.pitch)/100
        self.devicePitchAcceptable = pitch < 0.6 ? false : true
        
        if let videoCapture = self.videoCapture {
            if !self.devicePitchAcceptable && videoCapture.captureSession.isRunning {
                videoCapture.stop()
            } else if self.devicePitchAcceptable && !videoCapture.captureSession.isRunning {
                videoCapture.start()
            }
        }
    }
}

