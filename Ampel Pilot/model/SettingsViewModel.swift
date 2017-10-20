//
//  SettingsViewModel.swift
//  Ampel Pilot
//
//  Created by Patrick Valenta on 16.10.17.
//  Copyright © 2017 Patrick Valenta. All rights reserved.
//

import Foundation

struct SettingsViewModel {
    typealias BoundFunction = (()->())?
    
    let dataManager: DataManager
    
    private let model: Settings
    
    init(model: Settings, dataManager: DataManager) {
        self.model = model
        self.dataManager = dataManager
    }
}
