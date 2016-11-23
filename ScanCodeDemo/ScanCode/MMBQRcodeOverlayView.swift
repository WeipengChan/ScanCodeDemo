//
//  MMBQRcodeOverlayView.swift
//  meimabang
//
//  Created by Robin on 22/11/16.
//  Copyright © 2016年 广州雅特网络科技. All rights reserved.
//

import UIKit
import AVFoundation


let  MMBQRcodeOverlayViewPadding = 30.0

/*
   1 滚动的扫描条
   2 session运行状态监测
   4 进出后台监测
   5 挂载overlay view 的 xib
   6 授权提醒
*/
class MMBQRcodeOverlayView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    @IBOutlet  var scrollImageView:UIImageView? = nil
    @IBOutlet  var resultContainerView:UIView? = nil
    @IBOutlet  var resultTipLabel:UILabel? = nil
    @IBOutlet  var cropContainerView:UIView? = nil
    
    @IBOutlet  var scrollTopLayoutStraint:NSLayoutConstraint? = nil
  //  @IBOutlet  var cropTopLayoutStraint:NSLayoutConstraint? = nil
  //  @IBOutlet  var scrollTopLayoutStraint:NSLayoutConstraint? = nil

    
    //由于xib的静态性，最终真正的
    
    deinit {
        
        NotificationCenter.default.removeObserver(self)
    }
    
    static func cropRect() -> CGRect
    {
        //居中显示
        let width = ScreenSize.width.swf - MMBQRcodeOverlayViewPadding.swf * 2
        let height = width
        let x = MMBQRcodeOverlayViewPadding
        let y = (ScreenSize.height.swf - height) / 2
        return CGRect(x: x.f, y: y.f, width:width.f, height:height.f)
 
        //return resultContainerView!.frame
    }
    
    override func awakeFromNib() {
     
        NotificationCenter.default.addObserver(self, selector: #selector(onVideoStart(noti:)), name: NSNotification.Name.AVCaptureSessionDidStartRunning, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onVideoStop(noti:)), name: NSNotification.Name.AVCaptureSessionDidStopRunning, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(onVideoStop(noti:)), name: NSNotification.Name.AVCaptureSessionWasInterrupted, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(onVideoStart(noti:)), name: NSNotification.Name.AVCaptureSessionInterruptionEnded, object: nil)

        scrollImageView!.layer.shadowColor = UIColor.green.cgColor
        scrollImageView!.layer.shadowOffset = CGSizeFromString("{1,1}")
        scrollImageView!.layer.shadowOpacity = 0.5
        scrollImageView!.layer.shadowRadius = 5
        
    }
    


    
    // MARK: 处理和响应通知

    func onVideoStart(noti:Notification)
    {
        DispatchQueue.main.async {
            
            self.startScrollAnimate()
        }
    }
    
    func onVideoStop(noti:Notification)
    {
        DispatchQueue.main.async {
            
            self.stopScrollAnimate()
        }
        
        
    }
    
    // MARK: 更新UI
    func updateResultTip(tipText:String, isHide:Bool)
    {
        self.resultTipLabel!.text = tipText
        self.resultContainerView!.isHidden = isHide
    }
    
    
    var isAnimating:Bool = false
    // MARK: 扫描动画
    func startScrollAnimate()
    {
        if isAnimating
        {
           return
        }
        
        scrollImageView!.isHidden = false; //hide
        isAnimating = true;
        
        self.loopScrollAnimate()
    }
    
    //
    func stopScrollAnimate()
    {
        self.scrollImageView!.isHidden = true; //hide
        self.isAnimating = false;
    }
    
    func loopScrollAnimate()
    {
        
        if  !isAnimating {
            return ;
        }
        
        scrollTopLayoutStraint?.constant =  cropContainerView!.frame.size.height - 8 //底部位置
        self.setNeedsLayout()
        
        UIView.animate(withDuration: 2.0, animations: {
            
            self.layoutIfNeeded()
            
            }) { (isFinished) in
                
                self.scrollTopLayoutStraint!.constant = 0
                self.setNeedsLayout()
                self.layoutIfNeeded()
                self.loopScrollAnimate() //循环
        }
    }
    
    
    

}
