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
    var chartViewList: [ChartView?] = []
    var pixelDataList: [[UInt8]] = []
    var specStart: Int = 0
    var specEnd: Int = 0
    var isRemoveNoise: Bool = true
    
    var colorSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // For 4.7 inch screen, ex. iPhone 8
        // screenHeight = 667.0 , screenWidth = 375.0
        screenHeight = self.view.frame.height
        screenWidth = self.view.frame.width
        
        self.view.backgroundColor = UIColor.white
        
        // Switch bottom of plotting color toggle
        colorSwitch = UISwitch()
        colorSwitch.center = CGPoint(x: screenWidth * 0.9, y: screenHeight * 0.15)
        colorSwitch.isOn = true
        colorSwitch.addTarget(self, action: #selector(self.showVisibleSpec), for: .valueChanged)
        self.view.addSubview(colorSwitch)
        
        for i in 0...2 {
            let chartViewFrame = CGRect(x: screenWidth * 0.05, y: screenHeight * (0.2 + 0.25 * CGFloat(i)), width: screenWidth * 0.9, height: screenHeight * 0.25)
            let chartView = ChartView(frame: chartViewFrame)
            chartViewList.append(chartView)
        }
        // TODO: deal with `specStart` and `specEnd`
        specStart = 350
        specEnd = 1000
        
        // Add a bottom for taking screenshot
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "ScreenShot", style: .plain, target: self, action: #selector(self.btnTakeScreenShot))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // before each time view appear, plot the chart
        // TODO: need remove previous chart from superview at each time
        print("Number of pixel data arrays:\(pixelDataList.count)")
        
        for i in 0...chartViewList.count-1 {
            self.chartViewList[i]!.removeFromSuperview()
        }
        
        for chartIndex in 0...chartViewList.count-1 {
            self.chartPlot(chartIndex: chartIndex)
        }
        super.viewWillAppear(animated)
        pixelDataList.removeAll()
    }
    
    
    func chartPlot(chartIndex: NSInteger){
        if (chartIndex >= self.chartViewList.count) {
            print("chartIndex(\(chartIndex)) equal to or larger than chartViewList.count(\(chartViewList.count)).\n")
        }
        
        if (pixelDataList[chartIndex].count == 0){
            let alertView = UIAlertController.init(title: "chartIndex(\(chartIndex)): pixel array is NULL", message: "Please read pixel data again!!", preferredStyle: UIAlertController.Style.alert)
            let cancelAction = UIAlertAction.init(title: "ok", style: .cancel, handler: nil)
            alertView.addAction(cancelAction)
            self.present(alertView, animated: true)
            return
        }
        
        if (!isPixelDataForm(pixelDataArray: pixelDataList[chartIndex])) {
            print("Input data is NOT of pixel data form!!!")
            return
        }
        
        let dataArray = intArrayToCGFloatArray(intArray: pixelDataList[chartIndex])
        
        self.chartViewList[chartIndex]!.ChartPlot(dataArray: dataArray, specStart: specStart, specEnd: specEnd)
        self.view.addSubview(self.chartViewList[chartIndex]!)
        print("Did plot chart\(chartIndex)")
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
        // TODO
        if (isRemoveNoise) {
            dataArray = removeNoise(dataArray: dataArray, neighborSize: 7)
        }
        dataArray.reverse() // reverse the pixel data array
        return dataArray
    }
    
    // TODO
    /**
     Normalize the dataArray, and the largest element would become 255.
     
     - Parameter dataArray:
     
     - Returns:
     */
    func normalize(dataArray: [CGFloat]) -> [CGFloat]{
        var dataArrayNorm: [CGFloat] = []
        var maxValue:CGFloat = 0
        for i in 4...dataArray.count-5 {
            if dataArray[i] > maxValue { maxValue = dataArray[i]}
        }
        for i in 0...dataArray.count-1 {
            dataArrayNorm.append(dataArray[i] * CGFloat(255) / maxValue)
        }
        return dataArrayNorm
    }
    
    /**
     Remove small noise.
     
     - Parameter dataArray:
     - Parameter neighborSize:
     
     - Returns:
     */
    func removeNoise(dataArray: [CGFloat], neighborSize: NSInteger) -> [CGFloat] {
        var noiseRemoved: [CGFloat] = dataArray
        
        // TODO
        for i in 4+(neighborSize/2)...dataArray.count-(5+(neighborSize/2)) {
            let neighbor: [CGFloat] = Array(dataArray[(i - neighborSize / 2)...(i + neighborSize / 2)])
            let median: CGFloat = calculateMean(neighbor)
            noiseRemoved[i] = median
        }
        
        return noiseRemoved
    }
    
    func calculateMedian(_ neighbor: [CGFloat]) -> CGFloat {
        let sorted = neighbor.sorted()
        if sorted.count % 2 == 0 {
            return CGFloat((sorted[(sorted.count / 2)] + sorted[(sorted.count / 2) - 1])) / 2
        } else {
            return CGFloat(sorted[(sorted.count - 1) / 2])
        }
    }
    
    func calculateMean(_ neighbor: [CGFloat]) -> CGFloat {
        var total:CGFloat = 0
        var min:CGFloat = CGFloat.greatestFiniteMagnitude
        var max:CGFloat = 0
        for num in neighbor {
            total += num
            if (num < min) { min = num }
            if (num > max) { max = num }
        }
        return ((total - max - min) / CGFloat(neighbor.count - 2))
    }
    
    @objc func showVisibleSpec(sender: AnyObject){
        let ColorSwitch = sender as! UISwitch
        
        if ColorSwitch.isOn{
//            chartView.removeFromSuperview()
//            chartView.enableVisibleColorLayer(enable: true)
//            self.view.addSubview(chartView)
            for i in 0...chartViewList.count-1 {
                chartViewList[i]!.removeFromSuperview()
                chartViewList[i]!.enableVisibleColorLayer(enable: true)
                self.view.addSubview(chartViewList[i]!)
            }
        }else{
//            chartView.removeFromSuperview()
//            chartView.enableVisibleColorLayer(enable: false)
//            self.view.addSubview(chartView)
            for i in 0...chartViewList.count-1 {
                chartViewList[i]!.removeFromSuperview()
                chartViewList[i]!.enableVisibleColorLayer(enable: false)
                self.view.addSubview(chartViewList[i]!)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func btnTakeScreenShot(_ sender: UIButton) {
        self.takeScreenshot()
    }
    
    open func takeScreenshot(_ shouldSave: Bool = true) -> UIImage? {
        print("takeScreenshot")
        var screenshotImage :UIImage?
        let layer = UIApplication.shared.keyWindow!.layer
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);
        guard let context = UIGraphicsGetCurrentContext() else {return nil}
        layer.render(in:context)
        screenshotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let image = screenshotImage, shouldSave {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
        return screenshotImage
    }

}
