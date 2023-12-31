//
//  ArpDirectionButton.swift
//  AudioKitSynthOne
//
//  Created by AudioKit Contributors on 8/2/17.
//  Copyright © 2018 AudioKit. All rights reserved.
//

import UIKit

@IBDesignable
class ArpDirectionButton: UIView, S1Control {

    // MARK: - LFO Button

    let range: ClosedRange<Double> =  0...2
    private var width: CGFloat = 35.0

    // MARK: - S1Control

    var value = 0.0 {
        didSet {
            setNeedsDisplay()
            switch value {
            case 0.0:
                accessibilityValue = NSLocalizedString("Up", comment: "Up")
            case 1.0:
                accessibilityValue = NSLocalizedString("Up Down", comment: "Up Down")
            default:
                accessibilityValue = NSLocalizedString("Down", comment: "Down")
            }

        }
    }

    public var setValueCallback: (Double) -> Void = { _ in }
    var resetToDefaultCallback: () -> Void = {  }

    // MARK: - Draw

    override func draw(_ rect: CGRect) {
        ArpDirectionStyleKit.drawArpDirectionButton(frame: CGRect(x: 0,
                                                                  y: 0,
                                                                  width: self.bounds.width,
                                                                  height: self.bounds.height),
                                                    directionSelected: CGFloat(value))
    }

    // MARK: - Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchPoint = touch.location(in: self)
            switch touchPoint.x {
            case 0..<width:
                value = 0
            case width...width * 2:
                value = 1
            default:
                value = 2
            }
            setValueCallback(value)
        }
    }

    // MARK: - Accessibility

    override func accessibilityActivate() -> Bool {
        if value < 2.0 {
            value += 1.0
        } else {
            value = 0.0
        }
        return true
    }
    
}
