//
//  GATTDatabase.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 2/29/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import SwiftFoundation
import Bluetooth

/// GATT Database
public struct GATTDatabase {
    
    /// GATT Services in this database.
    public var services: [Service] = [] {
        
        didSet { updateAttributes() }
    }
    
    /// Attribute representation of the database.
    public private(set) var attributes: [Attribute] = []
    
    // MARK: - Initialization
    
    public init(services: [Service] = []) {
        
        self.services = services
        self.updateAttributes()
    }
    
    // MARK: - Dynamic Properties
    
    public var isEmpty: Bool {
        
        return services.isEmpty
    }
    
    // MARK: - Methods
    
    /// Clear the database.
    public mutating func clear() {
        
        self.services = []
    }
    
    /// Write the value to attribute specified by the handle.
    public mutating func write(value: [UInt8], _ handle: UInt16) {
        
        fatalError("Write to GATTDatabase not implemented")
    }
    
    /// The handles of the service at the specified index.
    public func serviceHandle(index: Int) -> UInt16 {
        
        var handle: UInt16 = 0x0000
        
        for (serviceIndex, service) in services.enumerate() {
            
            // increment handle
            handle += 1
            
            guard serviceIndex != index
                else { return handle }
            
            for characteristic in service.characteristics {
                
                handle += 2 + UInt16(characteristic.descriptors.count)
            }
        }
        
        fatalError("Invalid Service Index \(index)")
    }
    
    /// The end group handle for the service at the specified handle.
    public func serviceEndHandle(index: Int) -> UInt16 {
        
        let startHandle = serviceHandle(index)
        
        let service = services[index]
        
        var handle = startHandle
        
        for characteristic in service.characteristics {
            
            handle += 2 + UInt16(characteristic.descriptors.count)
        }
        
        return handle
    }
    
    public func serviceOf(attributeHandle: UInt16) -> Service {
        
        for (index, service) in services.enumerate() {
            
            let serviceHandleRange = serviceHandle(index) ... serviceEndHandle(index)
            
            if serviceHandleRange.contains(attributeHandle) {
                
                return service
            }
        }
        
        fatalError("Invalid attribute handle: \(attributeHandle)")
    }
    
    // MARK: - Subscripting
    
    /// The attribute with the specified handle.
    public subscript(handle: UInt16) -> Attribute {
        
        return attributes[Int(handle) - 1]
    }
    
    // MARK: - Private Methods
    
    private mutating func updateAttributes() {
        
        var attributes = [Attribute]()
        
        var handle: UInt16 = 0x0000
        
        for service in services {
            
            // increment handle
            handle += 1
            
            let attribute = Attribute(service: service, handle: handle)
            
            attributes.append(attribute)
            
            for characteristic in service.characteristics {
                
                // increment handle
                handle += 1
                
                attributes += Attribute.fromCharacteristic(characteristic, handle: handle)
                
                handle = attributes.last!.handle
            }
        }
        
        self.attributes = attributes
    }
}

// MARK: - Supporting Types

public extension GATTDatabase {
    
    /// GATT Include Declaration
    public struct Include {
        
        /// Included service handle
        public var serviceHandle: UInt16
        
        /// End group handle
        public var endGroupHandle: UInt16
        
        /// Included Service UUID
        public var serviceUUID: Bluetooth.UUID
        
        public init(serviceHandle: UInt16, endGroupHandle: UInt16, serviceUUID: Bluetooth.UUID) {
            
            self.serviceHandle = serviceHandle
            self.endGroupHandle = endGroupHandle
            self.serviceUUID = serviceUUID
        }
        
        /// ATT Attribute Value
        private var value: [UInt8] {
            
            let handleBytes = serviceHandle.littleEndianBytes
            
            let endGroupBytes = endGroupHandle.littleEndianBytes
            
            return [handleBytes.0, handleBytes.1, endGroupBytes.0, endGroupBytes.1] + serviceUUID.toData().byteValue
        }
    }
    
    /// ATT Attribute
    public struct Attribute {
        
        public let handle: UInt16
        
        public let UUID: Bluetooth.UUID
        
        public let value: [UInt8]
        
        public let permissions: [Permission]
        
        /// Defualt initializer
        private init(handle: UInt16, UUID: Bluetooth.UUID, value: [UInt8] = [], permissions: [Permission] = []) {
            
            self.handle = handle
            self.UUID = UUID
            self.value = value
            self.permissions = permissions
        }
        
        /// Initialize attribute with a `Service`.
        private init(service: GATT.Service, handle: UInt16) {
            
            self.handle = handle
            self.UUID = GATT.UUID(primaryService: service.primary).toUUID()
            self.value = service.UUID.toData().byteValue
            self.permissions = [.Read] // Read only
        }
        
        /// Initialize attribute with an `Include Declaration`.
        private init(include: Include, handle: UInt16) {
            
            self.handle = handle
            self.UUID = GATT.UUID.Include.toUUID()
            self.value = include.value
            self.permissions = [.Read] // Read only
        }
        
        /// Initialize attributes from a `Characteristic`.
        private static func fromCharacteristic(characteristic: Characteristic, handle: UInt16) -> [Attribute] {
            
            var currentHandle = handle
            
            let declarationAttribute: Attribute = {
                
                let propertiesMask = characteristic.properties.optionsBitmask()
                let valueHandleBytes = (handle + 1).littleEndianBytes
                let value = [propertiesMask, valueHandleBytes.0, valueHandleBytes.1] + characteristic.UUID.toData().byteValue
                
                return Attribute(handle: currentHandle, UUID: GATT.UUID.Characteristic.toUUID(), value: value, permissions: [.Read])
            }()
            
            currentHandle += 1
            
            let valueAttribute = Attribute(handle: currentHandle, UUID: characteristic.UUID, value: characteristic.value.byteValue, permissions: characteristic.permissions)
            
            var attributes = [declarationAttribute, valueAttribute]
            
            // add descriptors
            if characteristic.descriptors.isEmpty == false {
                
                var descriptorAttributes = [Attribute]()
                
                for descriptor in characteristic.descriptors {
                    
                    currentHandle += 1
                    
                    let attribute = Attribute(descriptor: descriptor, handle: currentHandle)
                    
                    descriptorAttributes.append(attribute)
                }
                
                attributes += descriptorAttributes
            }
            
            return attributes
        }
        
        /// Initialize attribute with a `Characteristic Descriptor`.
        private init(descriptor: Descriptor, handle: UInt16) {
            
            self.handle = handle
            self.UUID = descriptor.UUID
            self.value = descriptor.value
            self.permissions = descriptor.permissions
        }
    }
}

// MARK: - Typealiases

public extension GATT {
    
    public typealias Database = GATTDatabase
}

public extension GATTDatabase {
    
    public typealias Service = GATT.Service
    public typealias Characteristic = GATT.Characteristic
    public typealias Descriptor = GATT.Descriptor
    public typealias Permission = GATT.Permission
}