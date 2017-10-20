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
            
            if let settings = settings {
               dataManager.saveSettings(settings)
            }
        }
    }
    
    public var capturePreset: AVCaptureSession.Preset {
        return settings?.resolution ?? .hd1920x1080
    }
    
    public var confidenceThreshold: Box<Float> = Box(0)
    
    public var iouThreshold: Box<Float> = Box(0)
    
    public var sound: Box<Bool> = Box(false)
    
    public var vibrate: Box<Bool> = Box(false)
    
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
}
