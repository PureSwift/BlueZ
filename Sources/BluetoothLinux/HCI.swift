//
//  HCI.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/1/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import Glibc
#elseif os(macOS) || os(iOS)
    import Darwin.C
#endif

import BluetoothHCI
import CSwiftBluetoothLinux

public extension HCI {
    
    // MARK: - Typealiases
    
    typealias DeviceFlag             = HCIDeviceFlag
    
    typealias DeviceEvent            = HCIDeviceEvent
    
    typealias ControllerType         = HCIControllerType
    
    typealias BusType                = HCIBusType
    
    typealias IOCTL                  = HCIIOCTL
}

/// HCI device flags
public enum HCIDeviceFlag: CInt {
    
    case up
    case initialized
    case running
    
    case passiveScan
    case interactiveScan
    case authenticated
    case encrypt
    case inquiry
    
    case raw
}

/// HCI controller types
public enum HCIControllerType: UInt8 {
    
    case bredr                              = 0x00
    case amp                                = 0x01
}

/// HCI bus types
public enum HCIBusType: CInt {
    
    case virtual
    case usb
    case pcCard
    case uart
    case rs232
    case pci
    case sdio
}

/// HCI dev events
public enum HCIDeviceEvent: CInt {
    
    case register                           = 1
    case unregister
    case up
    case down
    case suspend
    case resume
}

/// HCI Packet types
public enum HCIPacketType: UInt8 {
    
    case command                            = 0x01
    case acl                                = 0x02
    case sco                                = 0x03
    case event                              = 0x04
    case vendor                             = 0xff
}

/// HCI Socket Option
public enum HCISocketOption: CInt {
    
    case dataDirection                      = 1
    case filter                             = 2
    case timeStamp                          = 3
}

/// HCI `ioctl()` defines
public enum HCIIOCTL {
    
    private static let H                    = CInt(UnicodeScalar(unicodeScalarLiteral: "H").value)
    
    /// #define HCIDEVUP	_IOW('H', 201, int)
    public static let DeviceUp              = IOC.IOW(H, 201, CInt.self)
    
    /// #define HCIDEVDOWN	_IOW('H', 202, int)
    public static let DeviceDown            = IOC.IOW(H, 202, CInt.self)
    
    /// #define HCIDEVRESET	_IOW('H', 203, int)
    public static let DeviceReset           = IOC.IOW(H, 203, CInt.self)
    
    /// #define HCIDEVRESTAT	_IOW('H', 204, int)
    public static let DeviceRestat          = IOC.IOW(H, 204, CInt.self)
    
    
    /// #define HCIGETDEVLIST	_IOR('H', 210, int)
    public static let GetDeviceList         = IOC.IOR(H, 210, CInt.self)
    
    /// #define HCIGETDEVINFO	_IOR('H', 211, int)
    public static let GetDeviceInfo         = IOC.IOR(H, 211, CInt.self)
    
    // TODO: All HCI ioctl defines
    
    /// #define HCIINQUIRY	_IOR('H', 240, int)
    public static let Inquiry               = IOC.IOR(H, 240, CInt.self)
}

// MARK: - Internal Supporting Types

internal struct HCISocketAddress {
    
    var family = sa_family_t()
    
    var device: UInt16 = 0
    
    var channel: UInt16 = 0
    
    init() { }
}

/* Ioctl requests structures */

/// `hci_dev_req`
internal struct HCIDeviceListItem {
    
    /// uint16_t dev_id;
    var identifier: UInt16 = 0
    
    /// uint32_t dev_opt;
    var options: UInt32 = 0
    
    init() { }
}

/// `hci_dev_list_req`
internal struct HCIDeviceList {
    
    typealias Item = HCIDeviceListItem
    
    static var maximumCount: Int {
        return HCI.maximumDeviceCount
    }
    
    /// uint16_t dev_num;
    var numberOfDevices: UInt16 = 0
    
    /// struct hci_dev_req dev_req[0];	/* hci_dev_req structures */
    /// 16 elements
    var list: (HCIDeviceListItem, HCIDeviceListItem, HCIDeviceListItem, HCIDeviceListItem, HCIDeviceListItem, HCIDeviceListItem, HCIDeviceListItem, HCIDeviceListItem, HCIDeviceListItem, HCIDeviceListItem, HCIDeviceListItem, HCIDeviceListItem, HCIDeviceListItem, HCIDeviceListItem, HCIDeviceListItem, HCIDeviceListItem) = (HCIDeviceListItem(), HCIDeviceListItem(), HCIDeviceListItem(), HCIDeviceListItem(), HCIDeviceListItem(), HCIDeviceListItem(), HCIDeviceListItem(), HCIDeviceListItem(), HCIDeviceListItem(), HCIDeviceListItem(), HCIDeviceListItem(), HCIDeviceListItem(), HCIDeviceListItem(), HCIDeviceListItem(), HCIDeviceListItem(), HCIDeviceListItem())
    
    init() { }
    
    subscript (index: Int) -> HCIDeviceListItem {
        
        assert(index < type(of: self).maximumCount, "The request can only contain up to \(type(of: self).maximumCount) devices")
        
        switch index {
            
        case 0:  return list.0
        case 1:  return list.1
        case 2:  return list.2
        case 3:  return list.3
        case 4:  return list.4
        case 5:  return list.5
        case 6:  return list.6
        case 7:  return list.7
        case 8:  return list.8
        case 9:  return list.9
        case 10: return list.10
        case 11: return list.11
        case 12: return list.12
        case 13: return list.13
        case 14: return list.14
        case 15: return list.15
            
        default: fatalError("Invalid index \(index)")
        }
    }
}

extension HCIDeviceList: Collection {
    
    public var count: Int {
        
        return Int(numberOfDevices)
    }
    
    /// The start `Index`.
    public var startIndex: Int {
        return 0
    }
    
    /// The end `Index`.
    ///
    /// This is the "one-past-the-end" position, and will always be equal to the `count`.
    public var endIndex: Int {
        return count
    }
    
    public func index(before i: Int) -> Int {
        return i - 1
    }
    
    public func index(after i: Int) -> Int {
        return i + 1
    }
    
}

extension HCIDeviceList: RandomAccessCollection {

    public subscript(bounds: Range<Int>) -> Slice<HCIDeviceList> {
        
        return Slice<HCIDeviceList>(base: self, bounds: bounds)
    }
    
    public func makeIterator() -> IndexingIterator<HCIDeviceList> {
        return IndexingIterator(_elements: self)
    }
}

/// `hci_inquiry_req`
internal struct HCIInquiryRequest {
    
    /// uint16_t dev_id;
    var identifier: UInt16 = 0
    
    /// uint16_t flags;
    var flags: UInt16 = 0
    
    /// uint8_t  lap[3];
    var lap: (UInt8, UInt8, UInt8) = (0,0,0)
    
    /// uint8_t  length;
    var length: UInt8 = 0
    
    /// uint8_t  num_rsp;
    var responseCount: UInt8 = 0
    
    init() { }
}

/// `hci_dev_info`
public struct HCIDeviceInformation {
    
    /// uint16_t dev_id;
    public internal(set) var identifier: UInt16 = 0
    
    /// char name[8];
    internal let nameCharacters: (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar) = (0, 0, 0, 0, 0, 0, 0, 0)
    
    public var name: String {
        var bytes = nameCharacters
        return withUnsafePointer(to: &bytes) {
            $0.withMemoryRebound(to: CChar.self, capacity: 8) {
                return String(cString: $0)
            }
        }
    }
    
    /// bdaddr_t bdaddr;
    public let address: BluetoothAddress = .zero
    
    /// uint32_t flags;
    public let flags = HCIDeviceOptions(rawValue: 0)
    
    /// uint8_t type;
    public let type: UInt8 = 0
    
    /// uint8_t  features[8];
    public let features: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0, 0, 0, 0, 0)
    
    /// uint32_t pkt_type;
    public let packetType: UInt32 = 0
    
    /// uint32_t link_policy;
    public let linkPolicy: UInt32 = 0
    
    /// uint32_t link_mode;
    public let linkMode: UInt32 = 0
    
    /// uint16_t acl_mtu;
    public let aclMaximumTransmissionUnit: UInt16 = 0
    
    /// uint16_t acl_pkts;
    public let aclPacketSize: UInt16 = 0
    
    /// uint16_t sco_mtu;
    public let scoMaximumTransmissionUnit: UInt16 = 0
    
    /// uint16_t sco_pkts;
    public let scoPacketSize: UInt16 = 0
    
    /// struct hci_dev_stats stat;
    public let statistics: HCIDeviceStatistics = HCIDeviceStatistics()
    
    internal init() { }
}

public struct HCIDeviceStatistics: Equatable, Hashable {
    
    /// uint32_t err_rx;
    public let errorRX: UInt32 = 0
    
    /// uint32_t err_tx;
    public let errorTX: UInt32 = 0
    
    /// uint32_t cmd_tx;
    public let commandTX: UInt32 = 0
    
    /// uint32_t evt_rx;
    public let eventRX: UInt32 = 0
    
    /// uint32_t acl_tx;
    public let alcTX: UInt32 = 0
    
    /// uint32_t acl_rx;
    public let alcRX: UInt32 = 0
    
    /// uint32_t sco_tx;
    public let scoTX: UInt32 = 0
    
    /// uint32_t sco_rx;
    public let scoRX: UInt32 = 0
    
    /// uint32_t byte_rx;
    public let byteRX: UInt32 = 0
    
    /// uint32_t byte_tx;
    public let byteTX: UInt32 = 0
    
    internal init() { }
}

public struct HCIDeviceOptions: RawRepresentable, Equatable, Hashable {
    
    public let rawValue: UInt32
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
}

public extension HCIDeviceOptions {
    
    func contains(_ flag: HCIDeviceFlag) -> Bool {
        return HCITestBit(flag, rawValue)
    }
}

internal struct HCIFilter {
    
    internal struct Bits {
        
        static let FilterType           = CInt(31)
        static let Event                = CInt(63)
        static let OpcodeGroupField     = CInt(63)
        static let OpcodeCommandField   = CInt(127)
    }
    
    var typeMask: UInt32 = 0
    
    var eventMask: (UInt32, UInt32) = (0, 0)
    
    var opcode: UInt16 = 0
    
    init() { clear() }
    
    @inline(__always)
    mutating func clear() {
        
        memset(&self, 0, MemoryLayout<HCIFilter>.size)
    }
    
    @inline(__always)
    mutating func setPacketType(_ type: HCIPacketType) {
        
        let bit = type == .vendor ? 0 : CInt(type.rawValue) & HCIFilter.Bits.FilterType
        
        HCISetBit(bit, &typeMask)
    }
    
    @inline(__always)
    mutating func setEvent(_ event: UInt8) {
        
        let bit = (CInt(event) & HCIFilter.Bits.Event)
        
        HCISetBit(bit, &eventMask.0)
    }
    
    @inline(__always)
    mutating func setEvent<T: HCIEvent>(_ event: T) {
        
        setEvent(event.rawValue)
    }
    
    @inline(__always)
    mutating func setEvent(_ event1: UInt8, _ event2: UInt8, _ event3: UInt8, _ event4: UInt8) {
        
        eventMask.0 = 0
        eventMask.0 += UInt32(event4) << 0o30
        eventMask.0 += UInt32(event3) << 0o20
        eventMask.0 += UInt32(event2) << 0o10
        eventMask.0 += UInt32(event1) << 0o00
    }
}

internal func HCITestBit(_ flag: CInt,  _ options: UInt32) -> Bool {
    
    return (options + (UInt32(bitPattern: flag) >> 5)) & (1 << (UInt32(bitPattern: flag) & 31)) != 0
}

internal func HCITestBit(_ flag: HCI.DeviceFlag, _ options: UInt32) -> Bool {
    
    return HCITestBit(flag.rawValue, options)
}
