//
//  DataManager.swift
//  Ampel Pilot
//
//  Created by Patrick Valenta on 16.10.17.
//  Copyright © 2017 Patrick Valenta. All rights reserved.
//

import Foundation

class DataManager {
    func fetchSettings(_ complete: @escaping (_ settings: Settings) -> ()) {
        DispatchQueue.global().async {
            Settings.initDefaults()
            complete(Settings.fetch())
        }
    }
    
    func saveSettings(_ newSettings: Settings) {
        newSettings.save()
    }
}
