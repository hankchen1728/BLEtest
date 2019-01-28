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
    var setLightButtonGroup: UISegmentedControl!
    let fullScreenSize = UIScreen.main.bounds.size
    
//    var startCodeInputField: CMDInputField!
    var cmdCodeInputField: CMDInputField!
    var parmCodeInputField: CMDInputField!
//    var endCodeInputField: CMDInputField!
//    var checkSumInputField: CMDInputField!
    var checkSum: Int = 0
    
    var gainAdjustSlider: UISlider!
    var gainAdjustLabel: UILabel!
    var gainAdjustValue: Int = 0
    
    var expoTimeSlider: UISlider!
    var expoTimeLabel: UILabel!
    var expoTime: Int = 1
    
    var InputCmdArray: [UInt8] = [0x55, 0xAA, 0x01, 0x00, 0x01, 0x00, 0xAA, 0x55, 0x00, 0x02] // command inputed in textfield
    var expoTimeCmd  : [UInt8] = [0x55, 0xAA, 0x19, 0x00, 0x01, 0x00, 0xAA, 0x55, 0x18, 0x02]
    let scanCmd      : [UInt8] = [0x55, 0xAA, 0x03, 0x00, 0x01, 0x00, 0xAA, 0x55, 0x02, 0x02]
    var gainAdjustCmd: [UInt8] = [0x55, 0xAA, 0x20, 0x00, 0x00, 0x00, 0xAA, 0x55, 0x18, 0x02]
    let getPixelCmd  : [UInt8] = [0x55, 0xAA, 0xFF, 0xFF, 0x00, 0x00, 0xAA, 0x55, 0xFC, 0x03]
    var lightCmd     : [UInt8] = [0x55, 0xAA, 0x01, 0x00, 0x01, 0x00, 0xAA, 0x55, 0x00, 0x02]
    
    var checkScanStateTimer = Timer()
    
//    var writeArray: [UInt8] = []
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
        
        cmdCodeInputField = CMDInputField(frame: CGRect(x: 0, y: height * 0.13, width: width, height: height * 0.05))
        cmdCodeInputField.setDelegate(viewController: self)
        cmdCodeInputField.setLabel(label: "指令碼")
        cmdCodeInputField.setText(input1Str: "01", input2Str: "00")
        self.view.addSubview(cmdCodeInputField)
        
        parmCodeInputField = CMDInputField(frame: CGRect(x: 0, y: height * 0.2, width: width, height: height * 0.05))
        parmCodeInputField.setDelegate(viewController: self)
        parmCodeInputField.setLabel(label: "參數")
        parmCodeInputField.setText(input1Str: "01", input2Str: "00")
        self.view.addSubview(parmCodeInputField)
        
        sendCommandButton = UIButton(frame: CGRect(x: width * 0.5, y: height * 0.28, width: width * 0.4, height: height * 0.08))
        sendCommandButton.setTitle("send command", for: .normal)
        sendCommandButton.isEnabled = true
        sendCommandButton.setTitleColor(UIColor.blue, for: .normal)
        sendCommandButton.backgroundColor = UIColor.gray
        sendCommandButton.addTarget(self, action: #selector(self.sendCommand), for: .touchUpInside)
        self.view.addSubview(sendCommandButton)
        
        updateCheckSum()
        
        // use to control Gain Adjust
        gainAdjustLabel = UILabel(frame: CGRect(x: width * 0.05, y: height * 0.4, width: width * 0.3, height: height * 0.1))
        gainAdjustLabel.text = "Gain: 0"
        gainAdjustLabel.textAlignment = NSTextAlignment.left
        self.view.addSubview(gainAdjustLabel)
        
        gainAdjustSlider = UISlider(frame: CGRect(x: 0, y: 0, width: width * 0.6, height: 50))
        gainAdjustSlider.minimumValue = 0
        gainAdjustSlider.maximumValue = 47 // MAX: 0x2F
        gainAdjustSlider.value = 0
        gainAdjustSlider.isContinuous = true
        gainAdjustSlider.center = CGPoint(x: width * 0.65, y: height * 0.45)
        gainAdjustSlider.addTarget(self, action: #selector(updateGainAdjust(sender:)), for: .valueChanged)
        self.view.addSubview(gainAdjustSlider)
        
        
        // use to control exposure time
        expoTimeLabel = UILabel(frame: CGRect(x: width * 0.05, y: height * 0.5, width: width * 0.3, height: height * 0.1))
        expoTimeLabel.text = "曝光時間: 0"
        expoTimeLabel.textAlignment = NSTextAlignment.left
        self.view.addSubview(expoTimeLabel)
        
        expoTimeSlider = UISlider(frame: CGRect(x: 0, y: 0, width: width * 0.6, height: 50))
        expoTimeSlider.minimumValue = 0
        expoTimeSlider.maximumValue = 10
        expoTimeSlider.value = 0
        expoTimeSlider.isContinuous = true
        expoTimeSlider.center = CGPoint(x: width * 0.65, y: height * 0.55)
        expoTimeSlider.addTarget(self, action: #selector(updateExpoTime(sender:)), for: .valueChanged)
        self.view.addSubview(expoTimeSlider)
        
        
        // use to set light
        setLightButtonGroup = UISegmentedControl(items: ["Green", "Blue", "White", "UV", "IR", "All"])
        setLightButtonGroup.tintColor = UIColor.blue
        setLightButtonGroup.backgroundColor = UIColor.white
        setLightButtonGroup.addTarget(self, action: #selector(switchLight), for: .valueChanged)
        setLightButtonGroup.frame.size = CGSize(width: width * 0.9, height: height * 0.07)
        setLightButtonGroup.center = CGPoint(x: width * 0.5, y: height * 0.7)
        self.view.addSubview(setLightButtonGroup)
        
        getPixelDataButton = UIButton(frame: CGRect(x: width * 0.05, y: height * 0.8, width: width * 0.4, height: height * 0.1))
        getPixelDataButton.setTitle("scan", for: .normal)
        getPixelDataButton.isEnabled = true
        getPixelDataButton.setTitleColor(UIColor.blue, for: .normal)
        getPixelDataButton.backgroundColor = UIColor.lightGray
        getPixelDataButton.addTarget(self, action: #selector(self.getPixel), for: .touchUpInside)
        self.view.addSubview(getPixelDataButton)
        
    }
    
    @objc func switchLight(sender: UISegmentedControl) {
        let lightIndex = sender.selectedSegmentIndex
        if (lightIndex < 5) {
            lightCmd[4] = UInt8(pow(2, Double(lightIndex)))
        }else {
            lightCmd[4] = 0x1C
        }
        let _checksum: Int = (85 + 170) * 2 + 1 + Int(lightCmd[4]) + Int(lightCmd[5])
        lightCmd[8] = UInt8(_checksum % 256)
        lightCmd[9] = UInt8(_checksum / 256)
        let commandData = Data(bytes: lightCmd)
        self.peripheral.writeValue(commandData, for: BLECharacteristic!, type: .withResponse)
    }
    
    
    // limit each textField input length
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let maxLength = 2
        let currentString: NSString = textField.text! as NSString
        let newString: NSString =
            currentString.replacingCharacters(in: range, with: string) as NSString
        return newString.length <= maxLength
    }
    
    func updateInputCmd() {
        InputCmdArray[2] = UInt8(getInputInt(cmdInputField: cmdCodeInputField, N: 1))
        InputCmdArray[3] = UInt8(getInputInt(cmdInputField: cmdCodeInputField, N: 2))
        InputCmdArray[4] = UInt8(getInputInt(cmdInputField: parmCodeInputField, N: 1))
        InputCmdArray[5] = UInt8(getInputInt(cmdInputField: parmCodeInputField, N: 2))
        InputCmdArray[8] = UInt8(checkSum % 256)
        InputCmdArray[9] = UInt8(checkSum / 256)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateCheckSum()
    }
    
    func updateCheckSum() {
        self.checkSum = 510 // `AA` is 170, `55` is 85
        checkSum += (getInputInt(cmdInputField: cmdCodeInputField, N: 1) + getInputInt(cmdInputField: cmdCodeInputField, N: 2))
        checkSum += (getInputInt(cmdInputField: parmCodeInputField, N: 1) + getInputInt(cmdInputField: parmCodeInputField, N: 2))
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
        updateInputCmd()
        let commandData = Data(bytes: InputCmdArray)

        self.peripheral.writeValue(commandData, for: BLECharacteristic!, type: .withResponse)
    }
    // ========================
    @objc func updateGainAdjust(sender: UISlider){
        self.gainAdjustLabel.text = "Gain: \(Int(sender.value))"
        gainAdjustValue = Int(sender.value)
        updateGainAdjustCmd()
    }
    
    func updateGainAdjustCmd() {
        gainAdjustCmd[4] = UInt8(gainAdjustValue)
        // update checksum
        let _checksum: Int = (85 + 170) * 2 + Int(0x20) + Int(gainAdjustCmd[4])
        gainAdjustCmd[8] = UInt8(_checksum % 256)
        gainAdjustCmd[9] = UInt8(_checksum / 256)
    }
    
    // ========================
    @objc func updateExpoTime(sender: UISlider){
        self.expoTimeLabel.text = "曝光時間: \(Int(sender.value))"
        expoTime = Int(sender.value)
        updateExpoTimeCmd()
    }
    
    func updateExpoTimeCmd() {
        var trueExpoTime: Int = 1
        if (expoTime > 0) {
            trueExpoTime = expoTime * 1250
        }
        
        expoTimeCmd[4] = UInt8(trueExpoTime % 256)
        expoTimeCmd[5] = UInt8(trueExpoTime / 256)
        
        // update checksum
        let _checksum: Int = (85 + 170) * 2 + Int(0x19) + Int(expoTimeCmd[4]) + Int(expoTimeCmd[5])
        expoTimeCmd[8] = UInt8(_checksum % 256)
        expoTimeCmd[9] = UInt8(_checksum / 256)
    }
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    
    @objc func getPixel() {
        var commandData: Data
        // set button unenabled
        getPixelDataButton.isEnabled = false // TODO: let button can't push
        getPixelDataButton.setTitle("Scanning...", for: .normal)
        getPixelDataButton.setTitleColor(UIColor.red, for: .normal)
        getPixelDataButton.backgroundColor = UIColor.lightGray
        
        // set gain adjust
        commandData = Data(bytes: self.gainAdjustCmd)
        self.peripheral.writeValue(commandData, for: BLECharacteristic!, type: .withResponse)
        
        // set expo time
        commandData = Data(bytes: self.expoTimeCmd)
        self.peripheral.writeValue(commandData, for: BLECharacteristic!, type: .withResponse)
        
        // start to scan
        commandData = Data(bytes: self.scanCmd)
        self.peripheral.writeValue(commandData, for: BLECharacteristic!, type: .withResponse)
        
        
        // [0x55, 0xAA, 0x03, 0x01, 0x01, 0x00, 0xAA, 0x55, 0x03, 0x02]
        self.checkScanStateTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.checkScanState), userInfo: nil, repeats: true)
        
        // read pixel data
    }
    
    @objc func checkScanState() {
        if self.readArray.count > 0 {
            if (self.readArray[2] == 3 &&
                self.readArray[3] == 1 &&
                self.readArray[4] == 0){
                print ("did stop scan")
                
                let commandData = Data(bytes: self.getPixelCmd)
                self.peripheral.writeValue(commandData, for: self.BLECharacteristic!, type: .withResponse)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1 ) {
                    // read pixel data
                    self.chartViewController.pixelDataArray = self.readArray
                    self.plotChartAndShow()
                    self.readArray.removeAll()
                }
                checkScanStateTimer.invalidate()
                return
            }
        }
        
        let commandData = Data(bytes: [0x55, 0xAA, 0x03, 0x01, 0x01, 0x00, 0xAA, 0x55, 0x03, 0x02])
        self.peripheral.writeValue(commandData, for: BLECharacteristic!, type: .withResponse)
}
    
    func plotChartAndShow() {
//        let alertVC = UIAlertController(title: "read sucessfully", message: "now plot the pixel data chart", preferredStyle: UIAlertControllerStyle.alert)
//        let action = UIAlertAction(title: "ok", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction) -> Void in
//            self.dismiss(animated: true, completion: nil)
//
//            self.navigationController?.pushViewController(self.chartViewController, animated: true)
//            self.chartViewController.specStart = 300
//            self.chartViewController.specEnd = 300 + 1920
//            self.chartViewController.pixelDataArray = self.readArray
//        })
//        alertVC.addAction(action)
//        self.view.window?.rootViewController?.present(alertVC, animated: true)
        
//        self.dismiss(animated: true, completion: nil)
        self.navigationController?.pushViewController(self.chartViewController, animated: true)
        self.chartViewController.specStart = 300
        self.chartViewController.specEnd = 300 + 1920
        self.chartViewController.pixelDataArray = self.readArray
        
        // TODO: let button can be push
        getPixelDataButton.isEnabled = true
        getPixelDataButton.setTitle("scan", for: .normal)
        getPixelDataButton.setTitleColor(UIColor.blue, for: .normal)
        getPixelDataButton.backgroundColor = UIColor.gray
    }
    
//    func hexStringToBytes(str: String) -> [UInt8]{
//        var bytes:[UInt8] = []
//        var substr:String = ""
//        for char in str{
//            if char == "-"{continue}
//            if substr.count < 2 {substr += String(char)}
//            if substr.count == 2{
//                bytes.append(UInt8(substr, radix: 16)!)
//                substr = ""
//            }
//        }
//        return bytes
//    }

//    func showWriteMessenger(NotifyData: [UInt8]){
//        if (self.writeArray.count == 0){
//            print("no input data")
//            return
//        }
//        let writeStrArray = hexToStr(hexArray: self.writeArray)
//        let NotifyStrArray = hexToStr(hexArray: NotifyData)
//        let alertView = UIAlertController.init(title: "寫入成功", message: "寫入指令: \(writeStrArray) \n回傳資料: \(NotifyStrArray)", preferredStyle: UIAlertControllerStyle.alert)
//        let cancelAction = UIAlertAction.init(title: "ok", style: .cancel, handler: nil)
//        alertView.addAction(cancelAction)
//        self.presentedViewController?.present(alertView, animated: true, completion: nil)
//    }
    
//    func hexToStr(hexArray: [UInt8]) -> [String]{
//        var StrArray: [String] = []
//        var hexStr: String
//        for hex in hexArray{
//            hexStr = "0x" + String(format:"%02X", hex)
//            StrArray.append(hexStr)
//        }
//        return StrArray
//    }
    
    
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
