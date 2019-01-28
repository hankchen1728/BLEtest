//
//  BLECentralViewController.swift
//  BLEtest
//
//  Created by 陳鈞廷 on 2018/9/7.
//  Copyright © 2018年 陳鈞廷. All rights reserved.
//

import UIKit
import CoreBluetooth

let BLEService_UUID0 = CBUUID(string: "49535343-5d82-6099-9348-7aac4d5fbc51")
let BLEService_UUID1 = CBUUID(string: "49535343-c9d0-cc83-a44a-6fe238d06d33")
let BLEService_UUID2 = CBUUID(string: "49535343-fe7d-4ae5-8fa9-9fafd205e455")
let BLECharacteristic_UUID_notify = CBUUID(string: "49535343-1E4D-4BD9-BA61-23C647249616")

var returnDataLen = 0

class BLECentralViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var centralManager: CBCentralManager!
    var peripherals: [CBPeripheral] = []
    var selectedPeripheral: CBPeripheral?
    var peripheralsTableView: UITableView!
    var BLECharacteristic: CBCharacteristic?
    
    let uartViewController = UARTViewController()
//    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var writeCommand: [UInt8] = []
    var returnCommand: [UInt8] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fullScreenSize = UIScreen.main.bounds.size
        
        peripheralsTableView = UITableView(frame: CGRect(x:0, y:fullScreenSize.height * 0.1, width:fullScreenSize.width, height:fullScreenSize.height * 0.9), style: .plain)
        peripheralsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "BLEcell")
        peripheralsTableView.delegate = self
        peripheralsTableView.dataSource = self
        self.view.addSubview(peripheralsTableView)
        
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        // Do any additional setup after loading the view.
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshDevices))
    }
    
    // refresh and rescan
    @objc func refreshDevices() {
        peripherals.removeAll()
        // disconnect
        if ((selectedPeripheral) != nil) {
            centralManager.cancelPeripheralConnection(selectedPeripheral!)
            selectedPeripheral = nil
        }
        startScan()
    }
    
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
        }
    }
    
    func startScan() {
        print("Now Scanning...")
        centralManager?.scanForPeripherals(withServices: nil, options: nil)
    }
    
    // discover devices
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if (peripheral.name == nil || self.peripherals.contains(peripheral)){
            return
        }
        self.peripherals.append(peripheral)
        peripheral.delegate = self
        self.peripheralsTableView.reloadData()
        print("find a new device: \(String(describing: peripheral.name))")
    }
    
    // connect success
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("success to connect to \(String(describing: peripheral.name))")
        centralManager.stopScan()
        
        peripheral.delegate = self
        peripheral.discoverServices([BLEService_UUID2])
        
        let alertVC = UIAlertController(title: "connect sucessfully", message: "connection to \(peripheral.name!) is successful.", preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction(title: "ok", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
            self.dismiss(animated: true, completion: nil)
            
            self.uartViewController.peripheral = peripheral
            self.uartViewController.BLECharacteristic = self.BLECharacteristic
            self.navigationController?.pushViewController(self.uartViewController, animated: true)
        })
        alertVC.addAction(action)
        self.view.window?.rootViewController?.present(alertVC, animated: true)
        
        
    }
    
    // connect fail
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("failed to connect to \(String(describing: peripheral.name)), error: \(String(describing: error?.localizedDescription))")
    }
    
    // disconnect to device
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("disconnect to device")
    }
    
    // scan Services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("===================")
        if (error != nil){
            print("encount error when finding Services of \(String(describing: peripheral.name)), error: \(String(describing: error?.localizedDescription))")
            return
        }
        if (peripheral.services != nil){
            print("all services of device: \(String(describing: peripheral.name)) are:")
            for service in peripheral.services!{
                peripheral.discoverCharacteristics(nil, for: service)
                print("\(service.uuid.uuidString)")
            }
        }else{
            print("no services found of device: \(String(describing: peripheral.name))")
        }
        
    }
    
    // scan characteristic
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("===================")
        if (error != nil){
            print("encount error when finding Characteristics of \(String(describing: peripheral.name)), error: \(String(describing: error?.localizedDescription))")
            return
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        for characteristic in characteristics {
            if (!characteristic.properties.contains(.notify)) {
                continue
            }
            self.selectedPeripheral?.setNotifyValue(true, for: characteristic)
            //looks for the right characteristic
            if (characteristic.uuid == BLECharacteristic_UUID_notify){
                BLECharacteristic = characteristic
                print("get characteristic: \(String(describing: BLECharacteristic?.uuid))")
            }
            
            if (characteristic.properties.contains(.read)){
                print("characteristic: \(characteristic.uuid) permit read")
            }

        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil){
            print("get error when sending command, error: \(error!.localizedDescription)")
            return
        }
        
        if let value = characteristic.value{
            let log = [UInt8](value)
            writeCommand = log
            print("************")
            print("using char: \(characteristic.uuid), didWriteValueFor: \(log)")
            print("************")
        }
        
        self.selectedPeripheral?.setNotifyValue(true, for: BLECharacteristic!)
//        returnCommand.removeAll() // remove last time data
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil){
            print("get error when updating data, error: \(error!.localizedDescription)")
            return
        }
        
        // add to main thread
        DispatchQueue.main.async {
            if let value = characteristic.value{
                let log = [UInt8](value)
                print("did read return command length: \(log.count)")
                print("read data: \(log)")
                // record return command
                if (self.cmdIsStart(ReadCmd: log)) {
                    self.returnCommand.removeAll() // remove the command last time
                }
                self.returnCommand.append(contentsOf: log)
                
                if (self.cmdIsEnd(ReadCmd: log)) {
                    self.uartViewController.readArray = self.returnCommand
                    print("***********")
//                    let HexArray = self.intToHexArray(intArray: self.returnCommand)
//                    print("using char: \(characteristic.uuid), did Update read value: \(HexArray)")
                    print("using char: \(characteristic.uuid), did Update read value (int): \(self.returnCommand)")
                    print("return data length: \(value.count)")
                    returnDataLen = self.returnCommand.count
                    print("now receive length: \(returnDataLen)")
                    print("***********")
                }
            }
        }
    }
    
    
    func intToHexArray(intArray: [UInt8]) -> [String] {
        var hexArray:[String] = []
        for intElem in intArray{
            hexArray.append(String(format:"%02X", intElem))
        }
        return hexArray
    }
    
    func cmdIsStart(ReadCmd: [UInt8]) -> Bool {
        // 0x55 equals to 85, and 0xAA equals to 170
        if (ReadCmd[0] == 85) && (ReadCmd[1] == 170) {
            return true
        }
        return false
    }
    
    func cmdIsEnd(ReadCmd: [UInt8]) -> Bool {
        // 0x55 equals to 85, and 0xAA equals to 170
        let cmdLen: Int = ReadCmd.count
        if (ReadCmd[cmdLen - 4] == 170) && (ReadCmd[cmdLen - 3] == 85){
            return true
        }
        return false
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BLEcell", for: indexPath) as UITableViewCell
        let peripheral = self.peripherals[indexPath.row]
        if let cellLabel = cell.textLabel{
            cellLabel.text = peripheral.name
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedPeripheral = self.peripherals[indexPath.row]
        centralManager.connect(selectedPeripheral!, options: nil)
    }

}
