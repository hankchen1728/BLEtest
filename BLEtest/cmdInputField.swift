//
//  cmdInputField.swift
//  BLEtest
//
//  Created by 陳鈞廷 on 2018/10/25.
//  Copyright © 2018年 陳鈞廷. All rights reserved.
//

import UIKit

class cmdInputField: UIView {
    var input1: UITextField!
    var input2: UITextField!
    var title: UILabel!
    var viewHeight, viewWidth: CGFloat!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        viewWidth = frame.width
        viewHeight = frame.height
        
        input1 = UITextField(frame: CGRect(x: viewWidth * 0.45, y: 0, width: viewWidth * 0.2, height: viewHeight))
        input1.borderStyle = .roundedRect
        input1.returnKeyType = .done
        input1.backgroundColor = UIColor.darkGray
        input1.textColor = UIColor.white
        self.addSubview(input1)
        
        input2 = UITextField(frame: CGRect(x: viewWidth * 0.45, y: 0, width: viewWidth * 0.2, height: viewHeight))
        input2.borderStyle = .roundedRect
        input2.returnKeyType = .done
        input2.backgroundColor = UIColor.darkGray
        input2.textColor = UIColor.white
        self.addSubview(input2)
        
    }
    
    func setPlaceholder(input1Str: String, input2Str: String){
        input1.placeholder = input1Str
        input2.placeholder = input2Str
    }
    
    func setText(input1Str: String, input2Str: String) {
        input1.text = input1Str
        input2.text = input2Str
    }
    
    func setLabel(label: String){
        title = UILabel(frame: CGRect(x: viewWidth * 0.1, y: 0, width: viewWidth * 0.3, height: viewHeight))
        title.text = label
        self.addSubview(title)
    }
    
    func setDelegate(viewController: UIViewController) {
        input1.delegate = viewController as? UITextFieldDelegate
        input2.delegate = viewController as? UITextFieldDelegate
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
