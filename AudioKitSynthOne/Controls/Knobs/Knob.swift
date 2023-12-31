//
//  KnobView.swift
//  AudioKitSynthOne
//
//  Created by AudioKit Contributors on 7/20/17.
//  Copyright © 2018 AudioKit. All rights reserved.
//

import UIKit

@IBDesignable
public class Knob: UIView, UIGestureRecognizerDelegate, S1Control {

    // MARK: - Init / Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .redraw
        accessibilityTraits = [
            .adjustable,
            .allowsDirectInteraction,
            .updatesFrequently
        ]
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.isUserInteractionEnabled = true
        contentMode = .redraw
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        doubleTapGesture.delegate = self
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)
    }

    override public func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        contentMode = .scaleAspectFit
        clipsToBounds = true
    }

    public class override var requiresConstraintBasedLayout: Bool {
        return true
    }

    // MARK: - Properties

    var onlyIntegers: Bool = false
    private var _value: Double = 0
    public var taper: Double = 1.0 // Linear by default
    var knobFill: CGFloat = 0
    var knobSensitivity: CGFloat = 0.005
    var lastX: CGFloat = 0
    var lastY: CGFloat = 0

    var range: ClosedRange = 0.0...1.0 {
        didSet {
            _value = range.clamp(_value)
            knobValue = CGFloat(Double(knobValue).normalized(from: range, taper: taper))
        }
    }

    var knobValue: CGFloat = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    lazy private var accessibilityChangeAmount: Double = {
        let widthOfRange = range.upperBound - range.lowerBound
        let incrementRange: Range = 1.1..<128.0
        if incrementRange.contains(widthOfRange) && onlyIntegers {
            return 1.0
        } else {
            return widthOfRange * 0.01
        }
    }()

    // MARK: - S1Control

    var value: Double {
        get {
            return _value
        }
        set(newValue) {
            _value = onlyIntegers ? round(newValue) : newValue
            _value = range.clamp(_value)
            knobValue = CGFloat(newValue.normalized(from: range, taper: taper))
            accessibilityValue = onlyIntegers ?
                String(format: "%.0f", _value) :
                String(format: "%.2f", _value)
        }
    }

    var setValueCallback: (Double) -> Void = { _ in }
    var resetToDefaultCallback: () -> Void = { }

    // MARK: - Draw

    public override func draw(_ rect: CGRect) {
        KnobStyleKit.drawKnobOne(frame: CGRect(x: 0,
                                               y: 0,
                                               width: self.bounds.width,
                                               height: self.bounds.height),
                                 knobValue: knobValue)
    }

    // MARK: - Touches

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchPoint = touch.location(in: self)
            lastX = touchPoint.x
            lastY = touchPoint.y
        }
    }

    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchPoint = touch.location(in: self)
            setPercentagesWithTouchPoint(touchPoint)
        }
    }

    @objc public func handleTap(_ sender: Knob) {
        resetToDefaultCallback()
    }

    func setPercentagesWithTouchPoint(_ touchPoint: CGPoint) {

        // Knobs assume up or right is increasing, and down or left is decreasing
        knobValue += (touchPoint.x - lastX) * knobSensitivity
        knobValue -= (touchPoint.y - lastY) * knobSensitivity
        knobValue = (0.0 ... 1.0).clamp(knobValue)
        value = Double(knobValue).denormalized(to: range, taper: taper)
        setValueCallback(value)
        lastX = touchPoint.x
        lastY = touchPoint.y
    }

    // MARK: - Accessibility

	override public func accessibilityIncrement() {
		value += accessibilityChangeAmount
		setValueCallback(value)
	}

	override public func accessibilityDecrement() {
		value -= accessibilityChangeAmount
		setValueCallback(value)
	}
}
