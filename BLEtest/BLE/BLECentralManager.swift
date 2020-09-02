//
//  BLECentralManager.swift
//  BLEtest
//
//  Created by 陳鈞廷 on 2019/1/28.
//  Copyright © 2019 陳鈞廷. All rights reserved.
//

import UIKit
import CoreBluetooth

class BLECentralManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private var cbCenMgr: CBCentralManager!
    var peripherals: [CBPeripheral] = []
    var selectedPeripheral: CBPeripheral?
    var BLECharacteristic: CBCharacteristic?
    
    var didDiscoverPeripheralAction: (() -> ())!
    var didConnectPeripheralAction: (() -> ())!
    var didReadReturnAction: (() -> ())!
    
    var writeCommand: [UInt8] = []
    var returnCommand: [UInt8] = []
    var returnDataLen = 0
    
    let BLEService_UUID = CBUUID(string: "49535343-fe7d-4ae5-8fa9-9fafd205e455")
    let BLECharacteristic_UUID = CBUUID(string: "49535343-1E4D-4BD9-BA61-23C647249616")

    override init() {
        super.init()
        cbCenMgr = CBCentralManager(delegate: self, queue: DispatchQueue.main, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    /**
     Check Bluetooth state.
     If state is poweredOn, call `startScan()` to scan all peripherals.
     */
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("CBCentralManagerStatePoweredOn")
            startScan()
        case .poweredOff:
            print("CBCentralManagerStatePoweredOff")
        case .unknown:
            print("CBCentralManagerStateUnknown")
        case .resetting:
            print("CBCentralManagerStateResetting")
        case .unsupported:
            print("CBCentralManagerStateUnsupported")
        case .unauthorized:
            print("CBCentralManagerStateUnauthorized")
        @unknown default:
            // TODO: deal with error
            print("Unknown condition.")
        }
    }
    
    
    /**
     Set action to invoke when any Peripheral discovered
     
     - Parameter action: action to invoke when any Peripheral discovered
     
     */
    func addAction(didDiscoverPeripheralAction action: @escaping() -> ()) {
        didDiscoverPeripheralAction = action
    }
    
    
    /**
     Set action to invoke when connecting to a peripheral
     
     - Parameter action: action to invoke when connecting to a peripheral
     
     */
    func addAction(didConnectPeripheralAction action: @escaping() -> ()) {
        didConnectPeripheralAction = action
    }
    
    func addAction(didReadReturnAction action: @escaping() -> ()) {
        didReadReturnAction = action
    }
    
    /**
     Scan peripherals.
     */
    func startScan() {
        // print("Now Scanning...")
        peripherals.removeAll()
        stopCurrentConnection()
        cbCenMgr?.scanForPeripherals(withServices: nil, options: nil)
    }
    
    
    /**
     Try to connect to selected device.
     
     - Parameter index: index of selected Peripheral in Array "peripherals"
     
     - Returns:
     */
    func connectDevice(index: NSInteger) {
        selectedPeripheral = peripherals[index]
        cbCenMgr.connect(selectedPeripheral!, options: nil)
    }
    
    /**
     Try to disconnect to selected device.
     
     - Returns:
     */
    func stopCurrentConnection() {
        if (selectedPeripheral != nil) {
            cbCenMgr.cancelPeripheralConnection(selectedPeripheral!)
            selectedPeripheral = nil
        } else {
            print("Warning: No connection.\n")
        }
    }
    
    
    /**
     =================================================
     = The following function is not for user.                                       =
     = Please do "NOT" call the following functions.                           =
     =================================================
     */
    
    /**
     Discover devices.
     */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if (peripheral.name == nil || self.peripherals.contains(peripheral)) {
            return
        }
        // TODO: convert `print` to `log`
        print("Find a new device: \(String(describing: peripheral.name)).\n")
        self.peripherals.append(peripheral)
        peripheral.delegate = self
        
        if (didDiscoverPeripheralAction != nil) {
            didDiscoverPeripheralAction()
        }
    }
    
    /**
     Detect successful connection.
     */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Success to connect to \(String(describing: peripheral.name)).\n")
        cbCenMgr.stopScan()
        
        peripheral.delegate = self
        peripheral.discoverServices([BLEService_UUID])
        
        if (didConnectPeripheralAction != nil) {
            didConnectPeripheralAction()
        }
    }
    
    /**
     Detect fail connection
     */
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(String(describing: peripheral.name)), Error: \(String(describing: error?.localizedDescription))")
    }
    
    /**
     Detect disconnection
     */
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnect to device: \(String(describing: peripheral.name)). \n")
    }
    
    /**
     Detect available services for `CBPeripheral`.
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if (error != nil){
            print("Encount error when finding Services of \(String(describing: peripheral.name)), error: \(String(describing: error?.localizedDescription)).\n")
            return
        }
        if (peripheral.services != nil){
            print("All services of device: \(String(describing: peripheral.name)) are:")
            for service in peripheral.services!{
                peripheral.discoverCharacteristics(nil, for: service)
                print("\(service.uuid.uuidString)")
            }
            print()
        }else{
            print("No services found of device: \(String(describing: peripheral.name)).\n")
        }
    }
    
    /**
     Detect available Characteristics for `CBService`.
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if (error != nil){
            print("Encount error when finding characteristics of \(String(describing: peripheral.name)), error: \(String(describing: error?.localizedDescription)).\n")
            return
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        for characteristic in characteristics {
            self.selectedPeripheral?.setNotifyValue(true, for: characteristic)
            
            // looks for the right characteristic
            if (characteristic.uuid == BLECharacteristic_UUID){
                BLECharacteristic = characteristic
//                if (characteristic.properties.contains(.read)) {
//                    BLECharacteristic = characteristic
//                    print("Get characteristic: \(String(describing: BLECharacteristic?.uuid)).\n")
//                    break
//                } else {
//                    print("Characteristic: \(characteristic.uuid) prohibit reading.\n")
//                }
            }
        }
        
        if (BLECharacteristic == nil) {
            print("Warning: No right characteristic discovered.\n")
        }
    }
    
    /**
     Detect data writen(sent) to `CBPeripheral`.
     */
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil){
            print("Got error when sending command, error: \(error!.localizedDescription).\n")
            return
        }
        
        if let value = characteristic.value{
            let log = [UInt8](value)
            writeCommand = log
            print("************")
            print("using char: \(characteristic.uuid), didWriteValueFor: \(log)")
            print("************")
        }
    }
    
    /**
     Detect data received(returned) from `CBPeripheral`.
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil){
            print("get error when updating data, error: \(error!.localizedDescription)")
            return
        }
        
        // Add to main thread
        DispatchQueue.main.async {
            if let value = characteristic.value{
                let log = [UInt8](value)
                print("did read return command length: \(log.count)")
                print("read data: \(log)")
                
                // Record return command
                if (self.cmdIsStart(ReadData: log)) {
                    self.returnCommand.removeAll()
                }
                
                self.returnCommand.append(contentsOf: log)
                
                if (self.cmdIsEnd(ReadData: log)) {
                    if (self.didReadReturnAction != nil) {
                        self.didReadReturnAction()
                    }
                    
                    print("***********")
                    print("using char: \(characteristic.uuid), did Update read value (int): \(self.returnCommand)")
                    print("return data length: \(value.count)")
                    self.returnDataLen = self.returnCommand.count
                    print("now receive length: \(self.returnDataLen)")
                    print("***********")
                }
            }
        }
    }

    /**
     Check if the command contains start-code.
     
     - Parameter ReadData: Read(return) data from `CBPeripheral`.
     
     - Returns: true if ReadData contains start-code.
     */
    private func cmdIsStart(ReadData: [UInt8]) -> Bool {
        // 0x55 equals to 85, and 0xAA equals to 170
        if (ReadData[0] == 85) && (ReadData[1] == 170) {
            return true
        }
        return false
    }
    
    /**
     Check if the command contains end-code.
     
     - Parameter ReadData: Read(return) data from `CBPeripheral`.
     
     - Returns: true if ReadData contains end-code.
     */
    private func cmdIsEnd(ReadData: [UInt8]) -> Bool {
        // 0x55 equals to 85, and 0xAA equals to 170
        let cmdLen: Int = ReadData.count
        if (ReadData[cmdLen - 4] == 170) && (ReadData[cmdLen - 3] == 85){
            return true
        }
        return false
    }
    
    
    /**
     Convert Array of integer into that of String in Hex format.
 
     - Parameter intArray: Array of Integer
     
     - Returns: Array of String with each element in Hex format
     */
    func intToHexArray(intArray: [UInt8]) -> [String] {
        var hexArray:[String] = []
        for intElem in intArray{
            hexArray.append(String(format:"%02X", intElem))
        }
        return hexArray
    }

}
