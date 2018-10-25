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
    var BLECharacteristic: CBCharacteristic?
    
    var characteristicLabel: UILabel!
    var sendCommandButton: UIButton! // button to send command to Spectrum
    var getPixelDataButton: UIButton! // button to send Pixel Data mode to Spectrum
    let fullScreenSize = UIScreen.main.bounds.size
    
    var commandInputField: UITextField!
    var startCodeInputField: CMDInputField!
    var cmdCodeInputField: CMDInputField!
    var parmCodeInputField: CMDInputField!
    var endCodeInputField: CMDInputField!
    var checkSumInputField: CMDInputField!
    
    var writeArray: [UInt8] = []
    var readArray: [UInt8] = []
    let chartViewController = ChartViewController()
    

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
        
//        commandInputField = UITextField(frame: CGRect(x: width * 0.2, y: height * 0.3, width: width * 0.6, height: height * 0.1))
//        commandInputField.borderStyle = .roundedRect
//        commandInputField.returnKeyType = .done
//        commandInputField.backgroundColor = UIColor.darkGray
//        commandInputField.textColor = UIColor.white
//        commandInputField.delegate = self
//        self.view.addSubview(commandInputField)
        
        startCodeInputField = CMDInputField(frame: CGRect(x: 0, y: height * 0.15, width: width, height: height * 0.07))
        startCodeInputField.setDelegate(viewController: self)
        startCodeInputField.setLabel(label: "起始碼")
        startCodeInputField.setText(input1Str: "55", input2Str: "AA")
        self.view.addSubview(startCodeInputField)
        
        cmdCodeInputField = CMDInputField(frame: CGRect(x: 0, y: height * 0.25, width: width, height: height * 0.07))
        cmdCodeInputField.setDelegate(viewController: self)
        cmdCodeInputField.setLabel(label: "指令碼")
        cmdCodeInputField.setPlaceholder(input1Str: "00", input2Str: "00")
        self.view.addSubview(cmdCodeInputField)
        
        parmCodeInputField = CMDInputField(frame: CGRect(x: 0, y: height * 0.35, width: width, height: height * 0.07))
        parmCodeInputField.setDelegate(viewController: self)
        parmCodeInputField.setLabel(label: "參數")
        parmCodeInputField.setPlaceholder(input1Str: "00", input2Str: "00")
        self.view.addSubview(parmCodeInputField)
        
        endCodeInputField = CMDInputField(frame: CGRect(x: 0, y: height * 0.45, width: width, height: height * 0.07))
        endCodeInputField.setDelegate(viewController: self)
        endCodeInputField.setLabel(label: "結束碼")
        endCodeInputField.setText(input1Str: "AA", input2Str: "55")
        self.view.addSubview(endCodeInputField)
        
        checkSumInputField = CMDInputField(frame: CGRect(x: 0, y: height * 0.55, width: width, height: height * 0.07))
        checkSumInputField.setDelegate(viewController: self)
        checkSumInputField.setLabel(label: "檢查碼")
        checkSumInputField.setPlaceholder(input1Str: "00", input2Str: "00")
        self.view.addSubview(checkSumInputField)
        
        
        characteristicLabel = UILabel(frame: CGRect(x: width*0.05, y:height*0.65, width: width*0.9, height: height*0.15))
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
        getPixelDataButton.addTarget(self, action: #selector(self.getPixel), for: .touchUpInside)
        self.view.addSubview(getPixelDataButton)
    }
    
    // limit each textField input length
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let maxLength = 2
        let currentString: NSString = textField.text! as NSString
        let newString: NSString =
            currentString.replacingCharacters(in: range, with: string) as NSString
        return newString.length <= maxLength
    }
    
    func getInputCmdStr() -> String {
        var cmd: String = ""
        cmd += (startCodeInputField.input1.text! + "-" + startCodeInputField.input2.text!)
        cmd += (cmdCodeInputField.input1.text! + "-" + cmdCodeInputField.input2.text!)
        cmd += (parmCodeInputField.input1.text! + "-" + parmCodeInputField.input2.text!)
        cmd += (endCodeInputField.input1.text! + "-" + endCodeInputField.input2.text!)
        cmd += (checkSumInputField.input1.text! + "-" + checkSumInputField.input2.text!)
        return cmd
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        var checkSum: Int = 0
        checkSum += (getInputInt(cmdInputField: startCodeInputField, N: 1) + getInputInt(cmdInputField: startCodeInputField, N: 2))
        checkSum += (getInputInt(cmdInputField: cmdCodeInputField, N: 1) + getInputInt(cmdInputField: cmdCodeInputField, N: 2))
        checkSum += (getInputInt(cmdInputField: parmCodeInputField, N: 1) + getInputInt(cmdInputField: parmCodeInputField, N: 2))
        checkSum += (getInputInt(cmdInputField: endCodeInputField, N: 1) + getInputInt(cmdInputField: endCodeInputField, N: 2))
        let checkSumLow: Int = checkSum % 256
        let checkSumHigh: Int = checkSum / 256
        checkSumInputField.input1.text = String(format:"%02X", checkSumLow)
        checkSumInputField.input2.text = String(format:"%02X", checkSumHigh)
    }
    
    func getInputInt(cmdInputField: CMDInputField, N: Int) -> Int{
        if (N == 1){
            if (cmdInputField.input1.text == "") { return 0}
            else {
                return Int(cmdInputField.input1.text!, radix: 16)!
            }
        }else if (N == 2){
            if (cmdInputField.input2.text == "") { return 0}
            else {
                return Int(cmdInputField.input2.text!, radix: 16)!
            }
        }
        return 0
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }

    @objc func sendCommand() {
        print("send command to device: \(self.peripheral.name!)")
        
//        let commandText = self.commandInputField.text
        let commandText = getInputCmdStr()
        let commandArray = hexStringToBytes(str: commandText)
        writeArray = commandArray
        let commandData = Data(bytes: commandArray)

        self.peripheral.writeValue(commandData, for: BLECharacteristic!, type: .withResponse)
    }
    
    @objc func getPixel() {
        let getPixelCmd:[UInt8] = [0x55, 0xAA, 0xFF, 0xFF, 0x00, 0x00, 0xAA, 0x55, 0xFC, 0x03]
        let commandData = Data(bytes: getPixelCmd)
        self.peripheral.writeValue(commandData, for: BLECharacteristic!, type: .withResponse)
        self.peripheral.readValue(for: BLECharacteristic!)
        self.chartViewController.pixelDataArray = self.readArray
        plotChartAndShow()
    }
    
    
    
    func plotChartAndShow() {
        let alertVC = UIAlertController(title: "read sucessfully", message: "now plot the pixel data chart", preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "ok", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction) -> Void in
            self.dismiss(animated: true, completion: nil)

            self.navigationController?.pushViewController(self.chartViewController, animated: true)
            self.chartViewController.specStart = 300
            self.chartViewController.specEnd = 300 + 1920
            self.chartViewController.pixelDataArray = self.readArray
        })
        alertVC.addAction(action)
        self.view.window?.rootViewController?.present(alertVC, animated: true)
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
        self.presentedViewController?.present(alertView, animated: true, completion: nil)
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

}
