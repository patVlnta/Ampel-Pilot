# Ampel-Pilot

[![Platform](http://img.shields.io/badge/platform-ios-blue.svg?style=flat
)](https://developer.apple.com/iphone/index.action)
[![Language](http://img.shields.io/badge/language-swift-brightgreen.svg?style=flat
)](https://developer.apple.com/swift)
[![License](http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat
)](http://mit-license.org)

Pedestrian Traffic Light Detector for visual impaired people, that can be used as guidance for determining the current phase of a pedestrian traffic light.

![Demo GIF](https://github.com/patVlnta/Ampel-Pilot/blob/master/images/ap_demo.gif "Demo GIF Animation")

You can watch the full demo video [here](https://github.com/patVlnta/Ampel-Pilot/blob/master/images/ap_demo.webm?raw=true). (Shot with a iPhone 6s)

## Features

* Detection and recognition of pedestrian traffic lights
* Audiovisual and  haptic feedback based on the current traffic light phase (Red, Green)
* Accessibility added for easier usage of the app
* Option to customize feedback and detection parameters

## Model and Dataset

The model used in the application is trained with the ML framework YOLOv2. 3062 Images have been used during training given the following results on the validation set (630 images):

| Light Phase        | Recall           | Precision  | IoU  |
| ------------- |:-------------:| :-----:| :-----:|
| Red     | 0.796 | 0.739 | 0.602 |
| Green     | 0.734 | 0.688 | 0.601 |

Please consider that the model is trained on the Red and Green image channels only. Therefore the camera output is beeing manipulated accordinly before beeing sent further down the proccessing pipeline. You can adjust that via a color matrix [here](https://github.com/patVlnta/Ampel-Pilot/blob/15fe48ec3ce2b7133fd1a1b82918e8ec796b740d/Ampel%20Pilot/helpers/VideoCapture.swift#L162):

#### VideoCapture.swift

``` swift
if let colorMatrixFilter = CIFilter(name: "CIColorMatrix") {
            let r:CGFloat = 1
            let g:CGFloat = 1
            let b:CGFloat = 0
            let a:CGFloat = 1
```

## Limitations

* Model trained on german traffic lights only
* Using the app at night will get you less accurate results
* Multi lane crossings (3+) will get you less accurate results

## Requirements

* Xcode 8 or higher
* iOS 11 or higher