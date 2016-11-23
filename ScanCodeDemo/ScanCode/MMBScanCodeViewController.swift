//
//  MMBScanCodeViewController.swift
//  meimabang
//
//  Created by Robin on 22/11/16.
//  Copyright © 2016年 广州雅特网络科技. All rights reserved.
//

import UIKit
/* 加入app状态d控制*/
class MMBScanCodeViewController: UIViewController , QISCaptureManagerDelegate {
    
    
    override var nibName: String? {
        let name:String = NSStringFromClass(self.classForCoder)
        let arr = name.components(separatedBy: ".")
        if arr.count > 1 {
            return arr[arr.count - 1]
        } else {
            return arr[0]
        }
    }

    var  captureManager:MMBCaptureManager = MMBCaptureManager.init(croRect: MMBQRcodeOverlayView.cropRect())
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureManager.delegate = self
        captureManager.rootViewController = self
    
        
        
        self.addCapturePreviewSubLayer()
        
        
        captureManager.perform(#selector(MMBCaptureManager.authCaputre), with: nil, afterDelay: 1.0)
        self.perform(#selector(MMBScanCodeViewController.addCapturePreviewSubLayer), with: nil, afterDelay: 1.1)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
    }
    
    
    @IBOutlet var overlayView:MMBQRcodeOverlayView? = nil
    func addCapturePreviewSubLayer()
    {
        if captureManager.videoPreViewLayer != nil
        {
        captureManager.videoPreViewLayer!.frame = self.view.layer.bounds
        self.view.layer.addSublayer(captureManager.videoPreViewLayer!)
        
        self.view.bringSubview(toFront: overlayView!)
            
            captureManager.startReader()

        }
    }

    
    // MARK:  QISCaptureManagerDelegate
    func didChangeAccessCameraState(isGranted: Bool) {
        
        if isGranted {
            self.addCapturePreviewSubLayer()
        }
        else{
            self.alertCameraAuth()
        }
    }
    
    func didOutputDecodeStringValue(stringValue: NSString) {
        
        debugPrint("scan result -- \(stringValue)")
    }
    
    /* 提示授权*/
     func alertCameraAuth()
    {
        let alertViewController:UIAlertController = UIAlertController.init(title:nil , message: "请在“设置-隐私-相机”选项中，允许应用访问你的相机", preferredStyle: .alert)
        
        let otherAction = UIAlertAction.init(title: "好", style: .default) { (action) in
            
        }
        
        alertViewController.addAction(otherAction)
        
        self.present(alertViewController, animated: true, completion: nil)
        //alertViewController.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
    }
    
    deinit {
        
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
