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
    var characteristicLabel: UILabel!
    var peripheral: CBPeripheral!
    var sendCommandButton: UIButton! // button to send command to Spectrum
    var getPixelDataButton: UIButton! // button to send Pixel Data mode to Spectrum
    let fullScreenSize = UIScreen.main.bounds.size
    var BLECharacteristic: CBCharacteristic?
    var commandInputField: UITextField!
    var writeArray: [UInt8] = []
    

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
        
        let width = fullScreenSize.width
        let height = fullScreenSize.height
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: DispatchQueue.main)
        
        self.view.backgroundColor = UIColor.white
        
        sendCommandButton = UIButton(frame: CGRect(x: width * 0.55, y: height * 0.8, width: width * 0.4, height: height * 0.1))
        sendCommandButton.setTitle("send command", for: .normal)
        sendCommandButton.isEnabled = true
        sendCommandButton.setTitleColor(UIColor.blue, for: .normal)
        sendCommandButton.backgroundColor = UIColor.lightGray
        sendCommandButton.addTarget(self, action: #selector(self.sendCommand), for: .touchUpInside)
        self.view.addSubview(sendCommandButton)
        
        commandInputField = UITextField(frame: CGRect(x: width * 0.2, y: height * 0.3, width: width * 0.6, height: height * 0.1))
        commandInputField.borderStyle = .roundedRect
        commandInputField.returnKeyType = .done
        commandInputField.backgroundColor = UIColor.darkGray
        commandInputField.textColor = UIColor.white
        commandInputField.delegate = self
        self.view.addSubview(commandInputField)
        
        characteristicLabel = UILabel(frame: CGRect(x: width*0.05, y:height*0.1, width: width*0.9, height: height*0.15))
        characteristicLabel.text = "characteristic: \n\(self.BLECharacteristic!.uuid)"
        characteristicLabel.textAlignment = NSTextAlignment.center
        characteristicLabel.font = UIFont.systemFont(ofSize: 11)
        characteristicLabel.numberOfLines = 2
        self.view.addSubview(characteristicLabel)
        
        getPixelDataButton = UIButton(frame: CGRect(x: width * 0.05, y: height * 0.8, width: width * 0.4, height: height * 0.1))
        getPixelDataButton.setTitle("get pixel", for: .normal)
        getPixelDataButton.isEnabled = true
        getPixelDataButton.setTitleColor(UIColor.blue, for: .normal)
        getPixelDataButton.backgroundColor = UIColor.lightGray
        getPixelDataButton.addTarget(self, action: #selector(self.getPixelandPlot), for: .touchUpInside)
        self.view.addSubview(getPixelDataButton)
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        
        return true
    }

    @objc func sendCommand() {
        print("send command to device: \(self.peripheral.name!)")
        
        let commandText = self.commandInputField.text
        let commandArray = hexStringToBytes(str: commandText!)
        writeArray = commandArray
        let commandData = Data(bytes: commandArray)

        self.peripheral.writeValue(commandData, for: BLECharacteristic!, type: .withResponse)
        
    }
    
    @objc func getPixelandPlot() {
        let getPixelCmd:[UInt8] = [0x55, 0xAA, 0xFF, 0xFF, 0x00, 0x00, 0xAA, 0x55, 0xFC, 0x03]
        let commandData = Data(bytes: getPixelCmd)
        self.peripheral.writeValue(commandData, for: BLECharacteristic!, type: .withResponse)
        
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
    
    
    func showWriteMessenger(NotifyData: [UInt8]){
        if (self.writeArray.count == 0){
            print("no input data")
            return
        }
        let writeStrArray = hexToStr(hexArray: self.writeArray)
        let NotifyStrArray = hexToStr(hexArray: NotifyData)
        let alertView = UIAlertController.init(title: "寫入成功", message: "寫入指令: \(writeStrArray) \n回傳資料: \(NotifyStrArray)", preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction.init(title: "ok", style: .cancel, handler: nil)
        alertView.addAction(cancelAction)
        self.present(alertView, animated: true, completion: nil)
    }
    
    func hexToStr(hexArray: [UInt8]) -> [String]{
        var StrArray: [String] = []
        var hexStr: String
        for hex in hexArray{
            hexStr = "0x" + String(format:"%02X", hex)
            StrArray.append(hexStr)
        }
        return StrArray
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
