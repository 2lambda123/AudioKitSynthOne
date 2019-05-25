//
//  PresetUIButon.swift
//  AudioKitSynthOne
//
//  Created by AudioKit Contributors on 11/24/17.
//  Copyright © 2017 AudioKit. All rights reserved.
//

import UIKit

class PresetUIButton: SynthButton {

    // MARK: - Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for _ in touches {
            self.setNeedsDisplay()
            self.setValueCallback(value)
        }
    }
}
