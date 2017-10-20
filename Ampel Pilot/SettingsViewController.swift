//
//  SettingController.swift
//  Ampel Pilot
//
//  Created by Patrick Valenta on 20.10.17.
//  Copyright © 2017 Patrick Valenta. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {
    
    var viewModel: SettingsViewModel!
    
    @IBOutlet weak var soundSwitch: UISwitch!
    @IBOutlet weak var vibrationSwitch: UISwitch!
    @IBOutlet weak var confidenceSlider: UISlider!
    @IBOutlet weak var iouSlider: UISlider!
    
    
    lazy var closeButton: UIBarButtonItem = {
        let bi = UIBarButtonItem(title: "Schließen", style: UIBarButtonItemStyle.plain, target: self, action: #selector(closeBtnPressed))
        return bi
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Einstellungen"
        
        navigationItem.rightBarButtonItems = [closeButton]
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupViewModel()
    }
    
    // MARK: - Initialization
    
    func setupViewModel() {
        
        viewModel.confidenceThreshold.bind {
            self.confidenceSlider.setValue($0, animated: true)
        }
        
        viewModel.iouThreshold.bind {
            self.iouSlider.setValue($0, animated: true)
        }
        
        viewModel.sound.bind {
            self.soundSwitch.setOn($0, animated: true)
        }
        
        viewModel.vibrate.bind {
            self.vibrationSwitch.setOn($0, animated: true)
        }
        
        viewModel?.initFetch()
    }
    
    // MARK: - Actions
    @objc func closeBtnPressed() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func soundSwitchValueChanged(_ sender: UISwitch, forEvent event: UIEvent) {
        viewModel.updateSound(new: sender.isOn)
    }
    
    @IBAction func vibrationSwitchValueChanged(_ sender: UISwitch) {
        viewModel.updateVibrate(new: sender.isOn)
    }
    
    @IBAction func confidenceSliderValueChanged(_ sender: UISlider) {
        viewModel.updateConfidenceThreshold(new: sender.value)
    }
    
    @IBAction func iouSliderValueChanged(_ sender: UISlider) {
        viewModel.updateIOUThreshold(new: sender.value)
    }
    
    
}
