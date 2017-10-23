//
//  SelectionViewController.swift
//  Ampel Pilot
//
//  Created by Patrick Valenta on 21.10.17.
//  Copyright © 2017 Patrick Valenta. All rights reserved.
//

import UIKit

class SelectionViewController: UITableViewController {
    
    var viewModel: SelectionViewModel!
    
    private var selectedIndexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = viewModel.title
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfCells
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "selectionCell", for: indexPath)
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.textLabel?.text = viewModel.getTitle(forIndexPath: indexPath)
        
        if viewModel.cellSelected(atIndexPath: indexPath) {
            cell.accessoryType = .checkmark
            selectedIndexPath = indexPath
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let oldSelectedIndexPath = selectedIndexPath {
            if let cell = tableView.cellForRow(at: oldSelectedIndexPath) {
                cell.accessoryType = .none
            }
        }
        
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
            selectedIndexPath = indexPath
            viewModel.selectCell(atIndexPath: indexPath)
        }
    }
}
