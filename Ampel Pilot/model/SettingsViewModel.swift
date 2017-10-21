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
            
            if let settings = settings {
               dataManager.saveSettings(settings)
            }
        }
    }
    
    public var capturePreset: AVCaptureSession.Preset {
        return settings?.resolution ?? .hd1920x1080
    }
    
    public var cPreset: Box<AVCaptureSession.Preset> = Box(AVCaptureSession.Preset.hd1920x1080)
    
    public var confidenceThreshold: Box<Float> = Box(0)
    
    public var iouThreshold: Box<Float> = Box(0)
    
    public var sound: Box<Bool> = Box(false)
    
    public var vibrate: Box<Bool> = Box(false)
    
    public var availableResolutions: [SelectionCellViewModel] {
        var cells = [SelectionCellViewModel(title: "HD", value: AVCaptureSession.Preset.hd1920x1080, selected: true),
                     SelectionCellViewModel(title: "4K", value: AVCaptureSession.Preset.hd4K3840x2160, selected: false)]
        
        cells = cells.map {
            var selected = $0.selected
            if let res = $0.value as? AVCaptureSession.Preset {
                selected = cPreset.value == res ? true : false
            }
            return SelectionCellViewModel(title: $0.title, value: $0.value, selected: selected)
        }
        
        return cells
    }
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    func initFetch() {
        self.dataManager.fetchSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.settings = settings
            }
        }
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
}

extension SettingsViewModel {
    func formatCapturePresetToText(preset: AVCaptureSession.Preset) -> String {
        switch preset {
        case AVCaptureSession.Preset.hd1920x1080:
            return "HD"
        case AVCaptureSession.Preset.hd4K3840x2160:
            return "4K"
        default:
            return "unbekannt"
        }
    }
}
