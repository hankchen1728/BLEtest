//
//  UARTViewController.swift
//  BLEtest
//
//  Created by 陳鈞廷 on 2018/9/8.
//  Copyright © 2018年 陳鈞廷. All rights reserved.
//

import UIKit
import CoreBluetooth


class UARTViewController: UIViewController, CBPeripheralManagerDelegate, UITextFieldDelegate{
    
    
    var peripheralManager: CBPeripheralManager?
    var peripheral: CBPeripheral!
    var sendCommandButton: UIButton!
    let fullScreenSize = UIScreen.main.bounds.size
    var BLECharacteristic: CBCharacteristic?
    var commandInputField: UITextField!

    

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("===============")
        switch peripheral.state {
            case .poweredOn:
                print("CBPeripheralManager is poweredOn")
                if let deviceName = self.peripheral.name{
                    print("now connect to \(deviceName)")
                }
            case .poweredOff:
                print("CBPeripheralManager is poweredOff")
            case .unknown:
                print("CBPeripheralManager is unknown")
            case .resetting:
                print("CBPeripheralManager is resetting")
            case .unauthorized:
                print("CBPeripheralManager is unauthorized")
            case .unsupported:
                print("CBPeripheralManager is unsupported")
        }
        print("===============")
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        peripheralManager = CBPeripheralManager(delegate: self, queue: DispatchQueue.main)
        
        self.view.backgroundColor = UIColor.white
        sendCommandButton = UIButton(frame: CGRect(x: fullScreenSize.width * 0.3, y:fullScreenSize.height * 0.8, width: fullScreenSize.width * 0.4, height: fullScreenSize.height * 0.1))
        sendCommandButton.setTitle("send command", for: .normal)
        sendCommandButton.isEnabled = true
        sendCommandButton.setTitleColor(UIColor.blue, for: .normal)
        sendCommandButton.backgroundColor = UIColor.lightGray
        sendCommandButton.addTarget(self, action: #selector(self.sendCommand), for: .touchUpInside)
        self.view.addSubview(sendCommandButton)
        
        commandInputField = UITextField(frame: CGRect(x: fullScreenSize.width * 0.2, y:fullScreenSize.height * 0.3, width: fullScreenSize.width * 0.6, height: fullScreenSize.height * 0.1))
        commandInputField.borderStyle = .roundedRect
        commandInputField.returnKeyType = .done
        commandInputField.backgroundColor = UIColor.darkGray
        commandInputField.textColor = UIColor.white
        commandInputField.delegate = self
        self.view.addSubview(commandInputField)
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        
        return true
    }

    @objc func sendCommand(){
        print("send command to device: \(self.peripheral.name!)")
        
        let commandText = self.commandInputField.text
        let commandArray = hexStringToBytes(str: commandText!)
        let commandData = NSData(bytes: commandArray, length: commandArray.count)
        self.peripheral.writeValue(commandData as Data, for: BLECharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
        
//        var command:[UInt8] = [0x55,0xAA,0x01,0x01,0x00,0x00,0xAA,0x55,0x00,0x02]
//        let commandData = NSData(bytes: &command, length: command.count)
//        self.peripheral.writeValue(commandData as Data, for: BLECharacteristic!, type: CBCharacteristicWriteType.withResponse)
        
        self.peripheral.setNotifyValue(true, for: BLECharacteristic!)
        
    }
    
    func hexStringToBytes(str: String) -> [UInt8]{
        var bytes:[UInt8] = []
        var substr:String = ""
        for char in str{
            if char == "-"{continue}
            if substr.count < 2 {substr += String(char)}
            if substr.count == 2{
                bytes.append(UInt8(substr, radix: 16)!)
                substr = ""
            }
        }
        return bytes
    }
    
    
    func showWriteMessenger(){
        let alertView = UIAlertController.init(title: "藍芽通訊", message: "寫入成功！！！", preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction.init(title: "ok", style: .cancel, handler: nil)
        alertView.addAction(cancelAction)
        self.present(alertView, animated: true, completion: nil)
    }
    
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("Device subscribe to characteristic")
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("===========")
            print("\(error)")
            return
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}