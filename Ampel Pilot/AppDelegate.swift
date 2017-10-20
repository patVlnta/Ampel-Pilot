//
//  AppDelegate.swift
//  Ampel Pilot
//
//  Created by Patrick Valenta on 03.10.17.
//  Copyright © 2017 Patrick Valenta. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let dataManager = DataManager()
        let viewModel = DetectionViewModel(dataManager: dataManager)
        
        if let firstViewController = window?.rootViewController as? DetectionViewController {
            firstViewController.viewModel = viewModel
        }
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

