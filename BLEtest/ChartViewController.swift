//
//  ChartViewController.swift
//  BLEtest
//
//  Created by 陳鈞廷 on 2018/10/25.
//  Copyright © 2018年 陳鈞廷. All rights reserved.
//

import UIKit

class ChartViewController: UIViewController {

    var screenHeight:CGFloat = 0, screenWidth:CGFloat = 0
    var chartView: ChartView!
    var pixelDataArray: [UInt8] = []
    var specStart: Int = 0
    var specEnd: Int = 0
    
    var colorSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // For 4.7 inch screen, ex. iPhone 8
        // screenHeight = 667.0 , screenWidth = 375.0
        screenHeight = self.view.frame.height
        screenWidth = self.view.frame.width
        
        self.view.backgroundColor = UIColor.white
        
        colorSwitch = UISwitch()
        colorSwitch.center = CGPoint(x: screenWidth * 0.8, y: screenHeight * 0.2)
        colorSwitch.isOn = true
        colorSwitch.addTarget(self, action: #selector(self.showVisibleSpec), for: .valueChanged)
        self.view.addSubview(colorSwitch)
        
        let chartViewFrame = CGRect(x: screenWidth * 0.05, y: screenHeight * 0.4, width: screenWidth * 0.9, height: screenHeight * 0.3)
        
        chartView = ChartView(frame: chartViewFrame)
        chartPlot()
        
        // plot chart
        specStart = 300
        specEnd = 300 + 1920
    }
    
    func chartPlot(){
        if (pixelDataArray.count == 0){
            let alertView = UIAlertController.init(title: "pixel array is NULL", message: "Please read pixel data again!!", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction.init(title: "ok", style: .cancel, handler: nil)
            alertView.addAction(cancelAction)
            self.present(alertView, animated: true)
            return
        }
        
        if (!isPixelDataForm(pixelDataArray: pixelDataArray)) { return}
        
        let dataArray = intArrayToCGFloatArray(intArray: pixelDataArray)
        self.chartView.ChartPlot(dataArray: dataArray, specStart: specStart, specEnd: specEnd)
        self.view.addSubview(self.chartView)
    }
    
    func isPixelDataForm(pixelDataArray: [UInt8]) -> Bool {
        // check start code
        if (pixelDataArray[0] != 85 || pixelDataArray[1] != 170) { return false}
        // check command code
        if (pixelDataArray[2] != 255 || pixelDataArray[3] != 255) { return false}
        // check end code
        let pixelNum = pixelDataArray.count
        if (pixelDataArray[pixelNum - 3] != 85 || pixelDataArray[pixelNum - 4] != 170) { return false}
        return true
    }
    
    func intArrayToCGFloatArray(intArray: [UInt8]) -> [CGFloat]{
        var dataArray: [CGFloat] = []
        for i in 0...intArray.count-1 {
            dataArray.append(CGFloat(intArray[i]))
        }
        return dataArray
    }
    
    @objc func showVisibleSpec(sender: AnyObject){
        let ColorSwitch = sender as! UISwitch
        
        if ColorSwitch.isOn{
            chartView.removeFromSuperview()
            chartView.enableVisibleColorLayer(enable: true)
            self.view.addSubview(chartView)
        }else{
            chartView.removeFromSuperview()
            chartView.enableVisibleColorLayer(enable: false)
            self.view.addSubview(chartView)
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
