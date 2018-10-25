//
//  ChartView.swift
//  ChartExample
//
//  Created by 陳鈞廷 on 2018/8/28.
//  Copyright © 2018年 陳鈞廷. All rights reserved.
//

import UIKit

class ChartView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    var viewHeight, viewWidth: CGFloat!
    let ChartLine = UIBezierPath()
    let ChartLineLayer = CAShapeLayer()
    
    let maskLayer = CAShapeLayer() // mask for VisibleColorLayer
    let VisibleColorLayer = CAGradientLayer()
    let rainBowColors:[CGColor] = [ UIColor.black.cgColor,
                                    UIColor.purple.cgColor,
                                    UIColor.blue.cgColor,
                                    UIColor.green.cgColor,
                                    UIColor.yellow.cgColor,
                                    UIColor.orange.cgColor,
                                    UIColor.red.cgColor,
                                    UIColor.black.cgColor]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        viewWidth = frame.width
        viewHeight = frame.height
        
        VisibleColorLayer.colors = rainBowColors
        VisibleColorLayer.startPoint = CGPoint(x: 0, y: 0) //
        VisibleColorLayer.endPoint = CGPoint(x: 1, y: 0) //
    }
    
    func ChartPlot(dataArray: [CGFloat], specStart: Int, specEnd: Int) {
        // draw bound of chart
        drawChartBound(specStart: specStart, specEnd: specEnd, labelLine: 10)
        
        
        VisibleColorLayer.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
        let location = GradientLayerLocation(specStart: specStart, specEnd: specEnd)
        VisibleColorLayer.locations = location
        self.layer.addSublayer(VisibleColorLayer)
        
        
        // draw chart line
        let pointNum: Int = dataArray.count
        let pointWidth: CGFloat = viewWidth / CGFloat(pointNum + 1)
        ChartLine.move(to: CGPoint(x: 0, y: viewHeight))
        // need to add a new path for mask for VisibleColorLayer
        // TODO: skip start and end code
        for i in 4...pointNum-5 {
            ChartLine.addLine(to: CGPoint(x: pointWidth * CGFloat(i+1), y: viewHeight - dataArray[i]))
        }
        ChartLine.addLine(to: CGPoint(x: viewWidth, y: viewHeight))
        
        // mask for VisibleColorLayer
        ChartLine.close()
        maskLayer.path = ChartLine.cgPath
        VisibleColorLayer.mask = maskLayer
        
        ChartLineLayer.path = ChartLine.cgPath
        ChartLineLayer.fillColor = UIColor.clear.cgColor
        ChartLineLayer.strokeColor = UIColor.black.cgColor
        ChartLineLayer.lineWidth = 0.3
        self.layer.addSublayer(ChartLineLayer)
    }
    
    private func drawChartBound(specStart: Int, specEnd: Int, labelLine: CGFloat){
        let ChartBound = UIBezierPath()
        ChartBound.move(to: CGPoint(x: 0, y: viewHeight))
        ChartBound.addLine(to: CGPoint(x: viewWidth, y: viewHeight))
        ChartBound.addLine(to: CGPoint(x: viewWidth, y: 0))
        ChartBound.addLine(to: CGPoint(x: 0, y: 0))
        ChartBound.addLine(to: CGPoint(x: 0, y: viewHeight + labelLine))

        var labelX: CGFloat
        for i in (specStart / 50)+1 ... (specEnd / 50){
            labelX = CGFloat(50 * i - specStart) / CGFloat(specEnd - specStart) * viewWidth
            ChartBound.move(to: CGPoint(x: labelX, y: viewHeight))
            ChartBound.addLine(to: CGPoint(x: labelX, y: viewHeight + labelLine))
        }
        ChartBound.move(to: CGPoint(x: viewWidth, y: viewHeight))
        ChartBound.addLine(to: CGPoint(x: viewWidth, y: viewHeight + labelLine))
        
        
        ChartBound.lineWidth = 1
        
        let boundLayer = CAShapeLayer()
        boundLayer.path = ChartBound.cgPath
        boundLayer.fillColor = UIColor.clear.cgColor
        boundLayer.strokeColor = UIColor.black.cgColor
        self.layer.addSublayer(boundLayer)
    }
    
    func enableVisibleColorLayer(enable: Bool){
        if enable{
            self.layer.addSublayer(VisibleColorLayer)
        }else{
            VisibleColorLayer.removeFromSuperlayer()
        }
    }
    
    func GradientLayerLocation(specStart: Int, specEnd: Int) -> Array<NSNumber>{
        var LocationArray: Array<Float> = [ 0, 0, 0, 0, 0, 0, 0]
        let GradSpec: Array<Int> = [380, 450, 495, 570, 590, 620, 750]
        for i in 0...GradSpec.count-1 {
            LocationArray[i] = Float(GradSpec[i] - specStart) / Float(specEnd - specStart)
        }
        return LocationArray as [NSNumber]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
