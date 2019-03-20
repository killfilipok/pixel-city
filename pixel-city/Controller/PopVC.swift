//
//  PopVC.swift
//  pixel-city
//
//  Created by Philip on 3/20/19.
//  Copyright © 2019 Philip. All rights reserved.
//

import UIKit

class PopVC: UIViewController, UIGestureRecognizerDelegate {
    
    //outlets
    @IBOutlet weak var popImg: UIImageView!
    @IBOutlet weak var dismissBtn: UIView!
    
    //vars
    var passedImg: UIImage!
    
    func initData(forImage image: UIImage){
        self.passedImg = image
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        popImg.image = passedImg
        addDoubleTap()
    }
    
    
    func addDoubleTap(){
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(screenWasDoubleTapped))
        
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        
        view.addGestureRecognizer(doubleTap)
    }
    
    @objc func screenWasDoubleTapped(){
        dismiss(animated: true, completion: nil)
    }
}
