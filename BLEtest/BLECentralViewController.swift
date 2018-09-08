//
//  BLECentralViewController.swift
//  BLEtest
//
//  Created by 陳鈞廷 on 2018/9/7.
//  Copyright © 2018年 陳鈞廷. All rights reserved.
//

import UIKit
import CoreBluetooth


let BLEService_UUID4 = CBUUID(string: "1800")
let BLEService_UUID5 = CBUUID(string: "180A")

let BLEService_UUID0 = CBUUID(string: "49535343-5d82-6099-9348-7aac4d5fbc51")
let BLEService_UUID1 = CBUUID(string: "49535343-c9d0-cc83-a44a-6fe238d06d33")
let BLEService_UUID2 = CBUUID(string: "49535343-fe7d-4ae5-8fa9-9fafd205e455")
let BLECharacteristic_UUID = CBUUID(string: "49535343-026e-3a9b-954c-97daef17e26e")

class BLECentralViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var centralManager: CBCentralManager!
    var peripherals: [CBPeripheral] = []
    var selectedPeripheral: CBPeripheral?
    var peripheralsTableView: UITableView!
    var BLECharacteristic: CBCharacteristic?
    let uartViewController = UARTViewController()
    
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
        peripheral.discoverServices([BLEService_UUID0])
        
        let alertVC = UIAlertController(title: "connect sucessfully", message: "connection to \(peripheral.name!) is successful.", preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "ok", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction) -> Void in
            self.dismiss(animated: true, completion: nil)
            
            self.uartViewController.peripheral = peripheral
            self.uartViewController.BLECharacteristic = self.BLECharacteristic
            self.present(self.uartViewController, animated: true, completion: nil)
        })
        alertVC.addAction(action)
        self.present(alertVC, animated: true, completion: nil)
        
        
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
        
        print("Found \(characteristics.count) characteristics!")
        
        for characteristic in characteristics {
            //looks for the right characteristic
            if (characteristic.uuid.isEqual(BLECharacteristic_UUID)){
                BLECharacteristic = characteristic
            }
            
            if (characteristic.properties.contains(.read)){
                print("characteristic: \(characteristic.uuid) permit read")
            }
            print("found characteristic uuid: \(characteristic.uuid)")
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil){
            print("get error when sending command, error: \(error!.localizedDescription)")
            return
        }
        
        if let value = characteristic.value{
            let log = NSString(data: value, encoding: String.Encoding.utf8.rawValue)
            print(log!)
        }
        self.uartViewController.showWriteMessenger()
        
        peripheral.discoverServices([BLEService_UUID0])
        
        peripheral.readValue(for: BLECharacteristic!)

    }
    
//    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
//        if (error != nil) {
//            print("get error when sending command, error: \(error!.localizedDescription)")
//            return
//        }
//        print("sending command succeeded!")
//
//
//    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil){
            print("get error when updating data, error: \(error!.localizedDescription)")
            return
        }
        
        print("value did update")
        if ((characteristic.value) != nil){
            let resultStr = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue)
            print(resultStr!)
        }
        
    
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil){
            print("get error when updating data, error: \(error!.localizedDescription)")
            return
        }
        
        if (characteristic.isNotifying) {
            print ("Subscribed. Notification has begun for: \(characteristic.uuid)")
        }
        
        if let value = characteristic.value{
            let log = [UInt8](value)
            print(log)
        }
        
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
