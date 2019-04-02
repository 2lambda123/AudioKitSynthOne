//
//  SynthButton.swift
//  AudioKitSynthOne
//
//  Created by AudioKit Contributors on 8/8/17.
//  Copyright © 2017 AudioKit. All rights reserved.
//

class SynthButton: UIButton, S1Control {

    var callback: (Double) -> Void = { _ in }

    var defaultCallback: () -> Void = { }

    var isOn: Bool {
        return self.value == 1
    }

    let range: ClosedRange<Double> = 0...1

    override var isSelected: Bool {
        didSet {
            self.backgroundColor = isOn ? #colorLiteral(red: 0.3058823529, green: 0.3058823529, blue: 0.3254901961, alpha: 1) : #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
			self.accessibilityValue = isOn ?
				NSLocalizedString("On", comment: "On") :
				NSLocalizedString("Off", comment: "Off")
        }
    }

    var value: Double = 0.0 {
        didSet {
            self.isSelected = value == 1.0
            self.setNeedsDisplay()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.clipsToBounds = true
        self.layer.cornerRadius = 2
        self.layer.borderWidth = 1
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for _ in touches {
            self.value = self.isOn ? 0 : 1
            self.setNeedsDisplay()
            self.callback(value)
        }
    }
    
}
