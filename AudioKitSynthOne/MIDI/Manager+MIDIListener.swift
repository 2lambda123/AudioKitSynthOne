//
//  Manager+MIDIListener.swift
//  AudioKitSynthOne
//
//  Created by AudioKit Contributors on 5/25/18.
//  Copyright © 2018 AudioKit. All rights reserved.
//


// AKMIDIListener protocol functions

extension Manager: AKMIDIListener {

    public func receivedMIDINoteOn(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel, portID: MIDIUniqueID? = nil, offset: MIDITimeStamp = 0) {
        guard channel == conductor.midiInChannel || conductor.isOmniMode else { return }
        var newVelocity = velocity
        if (newVelocity == 0) {
          receivedMIDINoteOff(noteNumber: noteNumber, velocity: newVelocity, channel: channel)
          return
        }
        if !appSettings.velocitySensitive {
            newVelocity = 127
        } else {
            let velocitySensitivity = appSettings.velocitySensitivity
            newVelocity = MIDIVelocity( 127 * pow( Double(newVelocity) / 127, pow(2, -velocitySensitivity) ) )
        }
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.keyboardView.pressAdded(noteNumber, velocity: newVelocity)
                self.notesFromMIDI.insert(noteNumber)
                //AKLog("noteNumber: \(noteNumber), velocity:\(velocity) ASYNC")
            }
        } else {
            keyboardView.pressAdded(noteNumber, velocity: newVelocity)
            notesFromMIDI.insert(noteNumber)
            //AKLog("noteNumber: \(noteNumber), velocity:\(velocity) SYNC")
        }
        //AKLog("noteNumber: \(noteNumber), newVelocity:\(newVelocity)")
    }

    public func receivedMIDINoteOff(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel, portID: MIDIUniqueID? = nil, offset: MIDITimeStamp = 0) {
        guard (channel == conductor.midiInChannel || conductor.isOmniMode) && !keyboardView.holdMode else { return }
        DispatchQueue.main.async {
            self.keyboardView.pressRemoved(noteNumber)
            self.notesFromMIDI.remove(noteNumber)

            // Mono Mode
            if !self.keyboardView.polyphonicMode {
                let remainingNotes = self.notesFromMIDI.filter { $0 != noteNumber }
                if let highest = remainingNotes.max() {
                    self.keyboardView.pressAdded(highest, velocity: velocity)
                }
            }
        }
    }

    // Assign MIDI CC to active MIDI Learn Controls
    func assignMIDIControlToControls(cc: MIDIByte) {
        let activeMIDILearnControls = midiControls.filter { $0.isMIDILearnActive }
        for control in activeMIDILearnControls {
            control.midiCC = cc
            control.isMIDILearnActive = false
        }
    }

    // MIDI Controller input
    public func receivedMIDIController(_ controller: MIDIByte, value: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID? = nil, offset: MIDITimeStamp = 0) {
        guard channel == conductor.midiInChannel || conductor.isOmniMode else { return }

        // If any MIDI Learn controls are active, assign the CC
        DispatchQueue.main.async {
            if self.midiLearnToggle.isSelected { self.assignMIDIControlToControls(cc: controller) }
        }

        // Handle MIDI Control Messages
        switch controller {

        // Mod Wheel
        case AKMIDIControl.modulationWheel.rawValue:
            DispatchQueue.main.async {
                self.modWheelPad.setVerticalValueFrom(midiValue: value)
            }

        // Sustain Pedal
        case AKMIDIControl.damperOnOff.rawValue:
            if value > 0 && !sustainMode {
                conductor.sustainer.sustain(down: true)
                sustainMode = true
            } else if sustainMode {
                conductor.sustainer.sustain(down: false)
                sustainMode = false
            }

            // TODO: replace SDSustain with dsp sustain using this CC
            //AKLog("REPLACE value:\(value), sustainMode:\(sustainMode)")

        // controllers
        default:
            //AKLog("controller:\(controller), value:\(value), channel:\(channel)")
            break
        }

        // Bank Change msb/cc0
        if controller == 0 {
            guard channel == conductor.midiInChannel || conductor.isOmniMode else { return }
            if Int(value) != self.presetsViewController.bankIndex {
                DispatchQueue.main.async {
                    self.presetsViewController.didSelectBank(index: Int(value))
                }
            }
        }

        // Check for MIDI learn controls that match controller
        let matchingControls = midiControls.filter { $0.midiCC == controller }

        // Set new control values from MIDI for matching controls
        for midiControl in matchingControls {
            DispatchQueue.main.async {
                midiControl.setControlValueFrom(midiValue: value)
            }
        }
    }

    // MIDI Program/Patch Change
    public func receivedMIDIProgramChange(_ program: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID? = nil, offset: MIDITimeStamp = 0) {
        guard channel == conductor.midiInChannel || conductor.isOmniMode else { return }
        guard !pcJustTriggered else { return }
        DispatchQueue.main.async {
            self.presetsViewController.didSelectPreset(index: Int(program))
        }

        // Prevent multiple triggers from multiple MIDI inputs
        pcJustTriggered = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.pcJustTriggered = false
        }
    }

    // MIDI Pitch Wheel
    public func receivedMIDIPitchWheel(_ pitchWheelValue: MIDIWord, channel: MIDIChannel, portID: MIDIUniqueID? = nil, offset: MIDITimeStamp = 0) {
        guard channel == conductor.midiInChannel || conductor.isOmniMode else { return }
        guard let s = Conductor.sharedInstance.synth else {
            AKLog("Can't process MIDI pitch wheel because synth is not instantiated")
            return
        }
        let val01 = Double(pitchWheelValue).normalized(from: 0...16_383)

        // UI will be updated by dependentParameterDidChange()
        s.setDependentParameter(.pitchbend, val01, 0)
    }

    // After touch
    public func receivedMIDIAftertouch(_ pressure: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID? = nil, offset: MIDITimeStamp = 0) {
        guard channel == conductor.midiInChannel || conductor.isOmniMode else { return }
        //NOP
    }

    // MIDI Setup Change
    public func receivedMIDISetupChange() {
        AKLog("midi setup change, midi.inputNames: \(AudioKit.midi.inputNames)")
        let midiInputNames = AudioKit.midi.inputNames
        midiInputNames.forEach { inputName in
            
            // check to see if input exists before adding it
            if midiInputs.firstIndex(where: { $0.name == inputName }) == nil {
                let newMIDI = MIDIInput(name: inputName, isOpen: true)
                midiInputs.append(newMIDI)
                AudioKit.midi.openInput(name: inputName)
            }
        }
    }

    public func receivedMIDISystemCommand(_ data: [MIDIByte], portID: MIDIUniqueID? = nil, offset: MIDITimeStamp = 0) {
        //NOP
    }
}
