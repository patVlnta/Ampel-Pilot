//
//  MotionManager.swift
//  Ampel Pilot
//
//  Created by Patrick Valenta on 06.10.17.
//  Copyright © 2017 Patrick Valenta. All rights reserved.
//

import Foundation
import CoreMotion

protocol MotionManagerDelegate {
    func didUpdate(withMotion: CMDeviceMotion)
}
class MotionManager: CMMotionManager {
    
    var delegate: MotionManagerDelegate?
    
    override init() {
        super.init()
        
        self.deviceMotionUpdateInterval = 0.5
    }
    
    public func start() {
        if !self.isDeviceMotionAvailable {
            print("[MotionManager]: Device motion not available")
            return
        }
        
        self.startDeviceMotionUpdates(
            to: OperationQueue.current!, withHandler: {
                (deviceMotion, error) -> Void in

                if(error == nil) {
                    if let deviceMotion = deviceMotion {
                        self.delegate?.didUpdate(withMotion: deviceMotion)
                    }
                } else {
                    //handle the error
                    print("[MotionManager]: Could not start device motion updates")
                }
        })
    }
    
    public func stop() {
        self.stopDeviceMotionUpdates()
    }
    
    public func getPitch() -> Double? {
        if let pitch = self.deviceMotion?.attitude.pitch {
            return (180 / Double.pi * pitch)/100
        }
        
        return nil
    }
}
