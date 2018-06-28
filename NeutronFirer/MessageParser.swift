//
//  SysexParser.swift
//  NeutronFirer
//
//  Created by Peter Bloxidge on 29/05/2018.
//  Copyright © 2018 Peter Bloxidge. All rights reserved.
//

import Cocoa

enum MessageType: Int {
    case predefined
    case custom
}

class MessageParser {
    private let SYSEX_START_BYTE : UInt8 = 0xF0
    private let SYSEX_END_BYTE : UInt8 = 0xF7
    private let MANUFACTURER_ID_ARRAY : [UInt8] = [0x00, 0x20, 0x32]  // "Behringer"
    private let FAMILY_ID_BYTE : UInt8 = 0x28                         // "Neutron"
    
    static let instance = MessageParser()
    
    var messageType: MessageType = .predefined
    
    var deviceID: UInt8 = 0x7F  // Broadcast
    var command: UInt8 = 0x0A
    private var address: UInt8 = 0x00
    var value: [UInt8] = []
    
    private var sysexHeader: [UInt8] {
        let header = [[SYSEX_START_BYTE], MANUFACTURER_ID_ARRAY, [FAMILY_ID_BYTE], [deviceID]]
        return header.flatMap { $0 }
    }
    
    var message: [UInt8] {
        let sysexMessage: [[UInt8]?] = [
            sysexHeader,
            [command],
            (command == 0x0A ? [address] : nil), // Address and value only needed for parameter setting command
            (command == 0x0A ? value : nil),
            [SYSEX_END_BYTE]
        ]
        switch messageType {
        case .predefined:
            return sysexMessage
                .compactMap { $0 }
                .flatMap { $0 }
        case .custom:
            return value
        }
    }
    
    func setAddress(msb: UInt8, lsb: UInt8) {
        address = ((msb << 4) | lsb)
    }
}
