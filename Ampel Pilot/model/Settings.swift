//
//  Settings.swift
//  Ampel Pilot
//
//  Created by Patrick Valenta on 16.10.17.
//  Copyright © 2017 Patrick Valenta. All rights reserved.
//

import Foundation
import AVFoundation

struct Settings {
    // Detection
    var sound: Bool
    var vibrate: Bool
    
    // Yolo
    var confidenceThreshold: Float
    var iouThreshold: Float
    
    // Camera
    var resolution: AVCaptureSession.Preset
    
    static func initDefaults() {
        if !Defaults.hasKey("sound") {
            Defaults[DefaultsKey<Bool>("sound")] = true
        }
        
        if !Defaults.hasKey("vibrate") {
            Defaults[DefaultsKey<Bool>("vibrate")] = true
        }
        
        if !Defaults.hasKey("confidenceThreshold") {
            Defaults[DefaultsKey<Double>("confidenceThreshold")] = 0.3
        }
        
        if !Defaults.hasKey("iouThreshold") {
            Defaults[DefaultsKey<Double>("iouThreshold")] = 0.5
        }
        
        if !Defaults.hasKey("resolution") {
            Defaults[DefaultsKey<Any?>("resolution")] = AVCaptureSession.Preset.hd1920x1080
        }
    }
    
    static func fetch() -> Settings {
        let sound = Defaults[DefaultsKey<Bool>("sound")]
        let vibrate = Defaults[DefaultsKey<Bool>("vibrate")]
        let cThresh = Float(Defaults[DefaultsKey<Double>("confidenceThreshold")])
        let iouThresh = Float(Defaults[DefaultsKey<Double>("iouThreshold")])
        let resolution = Defaults[DefaultsKey<Any?>("resolution")] as! AVCaptureSession.Preset
        
        return Settings(sound: sound, vibrate: vibrate, confidenceThreshold: cThresh, iouThreshold: iouThresh, resolution: resolution)
    }
    
    func save() {
        Defaults[DefaultsKey<Bool>("sound")] = self.sound
        Defaults[DefaultsKey<Bool>("vibrate")] = self.vibrate
        Defaults[DefaultsKey<Double>("confidenceThreshold")] = Double(self.confidenceThreshold)
        Defaults[DefaultsKey<Double>("iouThreshold")] = Double(self.iouThreshold)
        Defaults[DefaultsKey<Any?>("resolution")] = self.resolution
    }
}
