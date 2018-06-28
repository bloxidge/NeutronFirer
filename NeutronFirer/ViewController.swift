//
//  ViewController.swift
//  NeutronFirer
//
//  Created by Peter Bloxidge on 29/05/2018.
//  Copyright © 2018 Peter Bloxidge. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTextFieldDelegate, NSTabViewDelegate {

    @IBOutlet weak var messageLabel: NSTextField!
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet weak var deviceIDSelect: NSPopUpButton!
    @IBOutlet weak var commandSelect: NSPopUpButton!
    @IBOutlet weak var addressMSB: NSPopUpButton!
    @IBOutlet weak var addressLSB: NSPopUpButton!
    @IBOutlet weak var valueTextField: NSTextField!
    @IBOutlet weak var customMessageTextField: NSTextField!
    
    private var addressValueEnabled: Bool = true {
        didSet {
            addressMSB.isEnabled = addressValueEnabled
            addressLSB.isEnabled = addressValueEnabled
            valueTextField.isEnabled = addressValueEnabled
        }
    }
    
    private let midi = MIDIEngine()
    
    func updateMessageValue() {
        var activeTextField: NSTextField
        switch MessageParser.instance.messageType {
        case .predefined: activeTextField = valueTextField
        case .custom: activeTextField = customMessageTextField
        }
        var hexString = activeTextField.stringValue.replacingOccurrences(of: " ", with: "")
        if hexString.count % 2 == 1 {
            hexString = String(hexString.dropLast())
        }
        MessageParser.instance.value = [UInt8](hex: hexString) ?? []
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        midi.printSourcesAndDestinations()

        valueTextField.delegate = self
        customMessageTextField.delegate = self
        tabView.delegate = self
        
        updateLabel()
    }
    
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        let selectedIndex = tabView.indexOfTabViewItem(tabViewItem!)
        MessageParser.instance.messageType = MessageType(rawValue: selectedIndex)!
        updateMessageValue()
        updateLabel()
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else {
            return
        }
        var text = textField.stringValue.uppercased()
        text = text.replacingOccurrences(of: " ", with: "")
        guard let validRange = text.range(of: "^[A-Fa-f0-9]+$", options: .regularExpression, range: nil, locale: nil) else {
            text.insert(separator: " ", every: 2)
            textField.stringValue = String(text.dropLast())
            return
        }
        text = String(text[validRange])
        text.insert(separator: " ", every: 2)
        textField.stringValue = text
        
        updateMessageValue()
        updateLabel()
    }
    
    @IBAction func deviceIDChanged(_ sender: NSPopUpButton) {
        guard let selection = sender.selectedItem else {
            return
        }
        let deviceID = selection.title == "All" ? 0x7F : sender.indexOfSelectedItem - 1
        MessageParser.instance.deviceID = UInt8(deviceID)
        updateLabel()
    }
    
    @IBAction func commandChanged(_ sender: NSPopUpButton) {
        guard let title = sender.selectedItem?.title else {
            return
        }
        let commandString = String(title[..<title.index(title.startIndex, offsetBy: 2)])
        guard let command = [UInt8](hex: commandString)?.first else {
            return
        }
        addressValueEnabled = command == 0x0A
        MessageParser.instance.command = command
        updateLabel()
    }
    
    @IBAction func addressChanged(_ sender: NSPopUpButton) {
        MessageParser.instance.setAddress(msb: UInt8(addressMSB.indexOfSelectedItem),
                                          lsb: UInt8(addressLSB.indexOfSelectedItem))
        updateLabel()
    }
    
    @IBAction func sendPressed(_ sender: NSButton) {
        midi.sendMessage()
    }
    
    private func updateLabel() {
        print(MessageParser.instance.message)
        messageLabel.stringValue = MessageParser.instance.message.hexString.inserting(separator: " ", every: 2).uppercased()
    }
}
