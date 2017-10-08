//
//  FeedbackManager.swift
//  Ampel Pilot
//
//  Created by Patrick Valenta on 08.10.17.
//  Copyright © 2017 Patrick Valenta. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

import AudioToolbox.AudioServices

class FeedbackManager {
    private var hapticTimer: Timer?
    private var speechTimer: Timer?
    
    private var speechSynthesizer: AVSpeechSynthesizer?
    private var speechVoice: AVSpeechSynthesisVoice?
    
    //private var generator: UISelectionFeedbackGenerator!
    
    init() {
        self.hapticTimer = Timer()
        self.speechTimer = Timer()
        
        self.speechSynthesizer = AVSpeechSynthesizer()
        self.speechVoice = AVSpeechSynthesisVoice(language: "de-DE")
    
//        self.generator = UISelectionFeedbackGenerator()
//        self.generator.prepare()
    }
    
    public func start(withFeedbackType type: UINotificationFeedbackType, text: String, withInterval interval: TimeInterval) {
        DispatchQueue.main.async {
            self.doHapticFeedback()
            self.speekText(text: text)
            
            self.hapticTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(self.doHapticFeedback), userInfo: nil, repeats: true)
            self.speechTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.doSpeechFeedback), userInfo: ["speech": text], repeats: true)
        }
        
    }
    
    public func stop() {
        hapticTimer?.invalidate()
        speechTimer?.invalidate()
    }
    
    @objc private func doHapticFeedback() {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
    @objc private func doSpeechFeedback(sender: Timer) {
        if let userInfo = sender.userInfo as? Dictionary<String, String>{
            self.speekText(text: userInfo["speech"]!)
        }
    }
    
    private func speekText(text: String) {
        if let isSpeaking = self.speechSynthesizer?.isSpeaking {
            if isSpeaking {
                return
            }
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = self.speechVoice
        self.speechSynthesizer?.speak(utterance)
    }
}
