//
//  BLECentralViewController.swift
//  BLEtest
//
//  Created by 陳鈞廷 on 2018/9/7.
//  Copyright © 2018年 陳鈞廷. All rights reserved.
//

import UIKit

// Global variable
var bleMgr: BLECentralManager!

class BLECentralViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var peripheralsTableView: UITableView!
    let uartViewController = UARTViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the manager
        bleMgr = BLECentralManager()
        
        let fullScreenSize = UIScreen.main.bounds.size
        
        peripheralsTableView = UITableView(frame: CGRect(x:0, y:fullScreenSize.height * 0.1, width:fullScreenSize.width, height:fullScreenSize.height * 0.9), style: .plain)
        peripheralsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "BLEcell")
        peripheralsTableView.delegate = self
        peripheralsTableView.dataSource = self
        self.view.addSubview(peripheralsTableView)
        
        bleMgr.addAction(didDiscoverPeripheralAction: peripheralsTableView.reloadData)
        bleMgr.addAction(didConnectPeripheralAction: pushToUARTViewController)
        bleMgr.addAction(didReadReturnAction: passReadData)
        
        // Do any additional setup after loading the view.
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshDevices))
    }
    
    // refresh and rescan
    @objc func refreshDevices() {
        bleMgr.startScan()
        peripheralsTableView.reloadData()
    }
    
    func pushToUARTViewController() {
        let alertVC = UIAlertController(title: "connect sucessfully", message: "connection to \(bleMgr.selectedPeripheral!.name!) is successful.", preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction(title: "ok", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
            self.dismiss(animated: true, completion: nil)
            
            self.uartViewController.peripheral = bleMgr.selectedPeripheral!
            self.uartViewController.BLECharacteristic = bleMgr.BLECharacteristic
            self.navigationController?.pushViewController(self.uartViewController, animated: true)
        })
        alertVC.addAction(action)
        self.view.window?.rootViewController?.present(alertVC, animated: true)
    }
    
    func isPixelDataForm(pixelDataArray: [UInt8]) -> Bool {
        // check start code
        if (pixelDataArray[0] != 85 || pixelDataArray[1] != 170) { return false }
        // check command code
        if (pixelDataArray[2] != 255 || pixelDataArray[3] != 255) { return false }
        // check end code
        let pixelNum = pixelDataArray.count
        if (pixelDataArray[pixelNum - 3] != 85 || pixelDataArray[pixelNum - 4] != 170) { return false }
        return true
    }
    
    func passReadData() {
        self.uartViewController.readArray = bleMgr.returnCommand
        
        if isPixelDataForm(pixelDataArray: bleMgr.returnCommand) {
            self.uartViewController.pixelDataList.append(bleMgr.returnCommand)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bleMgr.peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BLEcell", for: indexPath) as UITableViewCell
        let peripheral = bleMgr.peripherals[indexPath.row]
        if let cellLabel = cell.textLabel{
            cellLabel.text = peripheral.name
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        bleMgr.connectDevice(index: indexPath.row)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
