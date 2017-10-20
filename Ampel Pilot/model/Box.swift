//
//  Box.swift
//  Ampel Pilot
//
//  Created by Patrick Valenta on 20.10.17.
//  Copyright © 2017 Patrick Valenta. All rights reserved.
//

class Box<T> {
    typealias Listener = (T) -> Void
    var listener: Listener?
    
    var value: T {
        didSet {
            listener?(value)
        }
    }
    
    init(_ value: T) {
        self.value = value
    }
    
    func bind(listener: Listener?) {
        self.listener = listener
        listener?(value)
    }
}
