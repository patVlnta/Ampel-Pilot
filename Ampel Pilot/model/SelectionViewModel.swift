//
//  SelectionViewModel.swift
//  Ampel Pilot
//
//  Created by Patrick Valenta on 21.10.17.
//  Copyright © 2017 Patrick Valenta. All rights reserved.
//

import Foundation

struct SelectionViewModel {
    var title: String
    
    var cells: Box<[SelectionCellViewModel]> = Box([SelectionCellViewModel]())
    
    init(title: String, cells: Box<[SelectionCellViewModel]>) {
        self.title = title
        self.cells = cells
    }
    
    public var numberOfCells: Int {
        return cells.value.count
    }
    
    func getTitle(forIndexPath indexPath: IndexPath) -> String {
        return cells.value[indexPath.row].title
    }
    
    func cellSelected(atIndexPath indexPath: IndexPath) -> Bool {
        return cells.value[indexPath.row].selected
    }
}

extension SelectionViewModel {
    func selectCell(atIndexPath indexPath: IndexPath) {
        cells.value = cells.value.enumerated().map { (index, element) in
            return SelectionCellViewModel(title: element.title, value: element.value, selected: indexPath.row == index ? true : false)
        }
    }
}

struct SelectionCellViewModel {
    var title: String
    var value: Any
    var selected: Bool
}
