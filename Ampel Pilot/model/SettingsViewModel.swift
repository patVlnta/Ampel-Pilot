//
//  SettingsViewModel.swift
//  Ampel Pilot
//
//  Created by Patrick Valenta on 16.10.17.
//  Copyright © 2017 Patrick Valenta. All rights reserved.
//

import AVFoundation

class SettingsViewModel {
    typealias BoundFunction = (()->())?
    
    let dataManager: DataManager
    private var settings: Settings? {
        didSet {
            confidenceThreshold.value = settings?.confidenceThreshold ?? 0
            iouThreshold.value = settings?.iouThreshold ?? 0
            sound.value = settings?.sound ?? false
            vibrate.value = settings?.vibrate ?? false
            cPreset.value = settings?.resolution ?? AVCaptureSession.Preset.hd1920x1080
            zoom.value = settings?.zoom ?? 1.5
            livePreview.value = settings?.livePreview ?? false
            
            if let settings = settings {
               dataManager.saveSettings(settings)
            }
        }
    }
    
    private var captureDevice: AVCaptureDevice?
    
    public var capturePreset: AVCaptureSession.Preset {
        return settings?.resolution ?? .hd1920x1080
    }
    
    public var cPreset: Box<AVCaptureSession.Preset> = Box(AVCaptureSession.Preset.hd1920x1080)
    
    public var zoom: Box<Float> = Box(0)
    
    public var livePreview: Box<Bool> = Box(false)
    
    public var confidenceThreshold: Box<Float> = Box(0)
    
    public var iouThreshold: Box<Float> = Box(0)
    
    public var sound: Box<Bool> = Box(false)
    
    public var vibrate: Box<Bool> = Box(false)
    
    public var availableResolutions: [SelectionCellViewModel] {
        
        guard let captureDevice = self.captureDevice else {
            return []
        }
        
        var cells = [SelectionCellViewModel(title: "HD 1080p", value: AVCaptureSession.Preset.hd1920x1080, selected: true)]
        
        if captureDevice.supportsSessionPreset(AVCaptureSession.Preset.hd1280x720) {
            cells.append(SelectionCellViewModel(title: "HD 720p", value: AVCaptureSession.Preset.hd1280x720, selected: false))
        }
        
        if captureDevice.supportsSessionPreset(AVCaptureSession.Preset.hd4K3840x2160) {
            cells.append(SelectionCellViewModel(title: "4K", value: AVCaptureSession.Preset.hd4K3840x2160, selected: false))
        }
        
        if captureDevice.supportsSessionPreset(AVCaptureSession.Preset.vga640x480) {
            cells.append(SelectionCellViewModel(title: "VGA", value: AVCaptureSession.Preset.vga640x480, selected: false))
        }
        
        cells = cells.map {
            var selected = $0.selected
            if let res = $0.value as? AVCaptureSession.Preset {
                selected = cPreset.value == res ? true : false
            }
            return SelectionCellViewModel(title: $0.title, value: $0.value, selected: selected)
        }
        
        return cells
    }
    
    public var availableZoomLevels: [SelectionCellViewModel] {
        let levels: [Float] = [1.0, 1.25, 1.5, 1.75, 2]
        let cells = levels.map { (float) -> SelectionCellViewModel in
            let selected = float == zoom.value ? true : false            
            return SelectionCellViewModel(title: self.formatZoomToText(zoom: float), value: float, selected: selected)
        }
        
        return cells
    }
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        
        self.captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
    }
    
    func initFetch() {
        self.dataManager.fetchSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.settings = settings
            }
        }
    }
    
    func reset() {
        Settings.removeKeys()
        self.initFetch()
    }
}

extension SettingsViewModel {
    func updateConfidenceThreshold(new: Float) {
        settings?.confidenceThreshold = new
    }
    
    func updateIOUThreshold(new: Float) {
        settings?.iouThreshold = new
    }
    
    func updateSound(new: Bool) {
        settings?.sound = new
    }
    
    func updateVibrate(new: Bool) {
        settings?.vibrate = new
    }
    
    func updateCapturePreset(new: AVCaptureSession.Preset) {
        settings?.resolution = new
    }
    
    func updateZoomLevel(new: Float) {
        settings?.zoom = new
    }
    
    func updateLivePreview(new: Bool) {
        settings?.livePreview = new
    }
}

extension SettingsViewModel {
    func formatCapturePresetToText(preset: AVCaptureSession.Preset) -> String {
        switch preset {
        case AVCaptureSession.Preset.vga640x480:
            return "VGA"
        case AVCaptureSession.Preset.hd1280x720:
            return "HD 720p"
        case AVCaptureSession.Preset.hd1920x1080:
            return "HD 1080p"
        case AVCaptureSession.Preset.hd4K3840x2160:
            return "4K"
        default:
            return "unbekannt"
        }
    }
    
    func formatZoomToText(zoom: Float) -> String {
        return "\(zoom)x"
    }
}
