//
//  MMBCaptureManager.swift
//  meimabang
//
//  Created by Robin on 21/11/16.
//  Copyright © 2016年 广州雅特网络科技. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

let WindowHeight  =  UIScreen.main.bounds.size.height
let WindowWidth   =  UIScreen.main.bounds.size.width
let ScreenSize    =  UIScreen.main.bounds.size

extension Int {
    var f: CGFloat { return CGFloat(self) }
    var swf: Float { return Float(self) }
    
}

extension Float {
    var f: CGFloat { return CGFloat(self) }
    
}

extension Double {
    var f: CGFloat { return CGFloat(self) }
    var swf: Float { return Float(self) }
}

extension CGFloat {
    var swf: Float { return Float(self) }
}

@objc  protocol QISCaptureManagerDelegate : NSObjectProtocol {
  @objc   optional  func didChangeAccessCameraState(isGranted:Bool);
  @objc   optional  func didOutputDecodeStringValue(stringValue:NSString);
  @objc   optional  func didDecodeUnmatchType(codeType:NSString);
}

class MMBCaptureManager : NSObject, AVCaptureMetadataOutputObjectsDelegate
{
    private var _cropRect:CGRect?;
    var captureSession:AVCaptureSession = AVCaptureSession()
    var delegate:QISCaptureManagerDelegate? = nil
    var nextTipDate : Date? = nil
    weak var rootViewController : UIViewController? = nil
    
    /* 此对象将output封装到layer是一张便利的对象*/
    var videoPreViewLayer:AVCaptureVideoPreviewLayer? = nil
    
    /* 开始捕捉*/;
    var isReading:Bool = false ;
    
    override init() {
        super.init()
    }
    init(croRect:CGRect)
    {
        _cropRect  =  croRect;
        
    }
    
    deinit
    {
        self.clearCaputure()
    }
    
    // #pragma MARK: - 授权
    func  authCaputre()
    {
        
        let authStatus:AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        
        if(authStatus == .notDetermined)
        {
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: {
               granded  in
                
                if(granded){
                    self.setupCature()
                    self.didChangeAccessCameraState(isGranted: true);
                }
                else
                {
                    self.didChangeAccessCameraState(isGranted: false);
                }
                
            })
        }
        else if(authStatus == .authorized || authStatus == .restricted)
        {
            self.setupCature()
        }
        else if(authStatus == .denied)
        {
            (self.rootViewController as! MMBScanCodeViewController).alertCameraAuth()
        }
        
    }
    

    // MARK: 开始捕捉
    func setupCature()
    {
        // MARK : 配置
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)!
        
        do
        {
          try captureDevice.lockForConfiguration()
        }
        catch { }
        
        //设置自动对焦
        if (captureDevice.isFocusModeSupported(.continuousAutoFocus))
        {
            
            captureDevice.focusPointOfInterest = CGPoint(x:0.5 , y:0.5)
            captureDevice.focusMode = .continuousAutoFocus
            
        }
        
        
        if(captureDevice.hasTorch && captureDevice.isTorchModeSupported(.auto))
        {
            captureDevice.torchMode = .auto
        }
        
        captureDevice.videoZoomFactor = captureDevice.activeFormat.videoZoomFactorUpscaleThreshold
        
        captureDevice.unlockForConfiguration()
        
        // MARK: 设置session
        var isHighPresent : Bool = false
        let idiom = UIDevice.current.userInterfaceIdiom
        if idiom == .pad || CGFloat(WindowHeight) < 480 + 1
        { isHighPresent = true}
        
        if isHighPresent {
            
           captureSession.sessionPreset = AVCaptureSessionPresetHigh
        }
        else if captureSession.canSetSessionPreset(AVCaptureSessionPreset1920x1080)
        {
            captureSession.sessionPreset = AVCaptureSessionPreset1920x1080
        }
        
        
        let captureInput = try? AVCaptureDeviceInput.init(device: captureDevice)
        
        if captureInput == nil { debugPrint("captureInput init falied!")
            return }
        
        if captureSession.canAddInput(captureInput)
        {
            captureSession.addInput(captureInput)
        }
        
        let captureOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(captureOutput)
        {
            captureSession.addOutput(captureOutput)
        }
        
        let queue  = DispatchQueue.init(label: "captureOutputQueue")
        captureOutput.setMetadataObjectsDelegate(self, queue: queue)
        
        
        captureOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        
        captureOutput.rectOfInterest = self.rectOfInterest()

        videoPreViewLayer = AVCaptureVideoPreviewLayer.init(session: self.captureSession)
        videoPreViewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        
    }
    
    /** 开始捕捉*/
    func startReader()
    {
        self.isReading = true;
        if !captureSession.isRunning
        {
            self.captureSession.startRunning()
        }
    }
    
    /* 停止捕捉*/
    func stopReader()
    {
        self.isReading = false;
        if captureSession.isRunning
        {
            captureSession.stopRunning()
        }
        
    }
    
    
    /* 清楚资源*/
    func clearCaputure()
    {
        self.isReading = false
        
        self.stopReader()
        
        if captureSession.inputs.count > 0
        {
            captureSession.removeInput(captureSession.inputs[0] as! AVCaptureInput)
        }
        
        if captureSession.outputs.count > 0
        {
            captureSession.removeOutput(captureSession.outputs[0] as! AVCaptureOutput)
        }
    }
    
    // MARK : AVCaptureMetadataOutputObjectsDelegate
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!)
    {
        if !self.isReading { return};
        
        if metadataObjects != nil && metadataObjects.count > 0
        {
            let   metadataObject:AVMetadataMachineReadableCodeObject = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            let   codeType:NSString = metadataObject.type as NSString
            let   stringValue:NSString = metadataObject.stringValue as NSString
            let   currentDate = Date()
            
            if  codeType.hasSuffix("QRCode") || codeType.hasSuffix("Code128")
            {
                
                if nextTipDate != nil //2s回调一次，避免频繁的回调
                {
                    if currentDate.compare(nextTipDate!) == .orderedAscending
                    {
                       return
                    }
                    else
                    {
                        self.nextTipDate = currentDate.addingTimeInterval(2.0)
                    }
                
                }
                else
                {
                    nextTipDate = currentDate.addingTimeInterval(2.0)
                }
                
                DispatchQueue.main.async {
                    
                    if self.delegate != nil && (self.delegate?.responds(to: #selector(QISCaptureManagerDelegate.didOutputDecodeStringValue(stringValue:))))!
                    {
                       self.delegate!.didOutputDecodeStringValue!(stringValue: stringValue)
                     
                    }
                }
                return
            }
            
            DispatchQueue.main.async {
                
                if self.delegate != nil && (self.delegate?.responds(to: #selector(QISCaptureManagerDelegate.didDecodeUnmatchType(codeType:))))!
                {
                    self.delegate!.didDecodeUnmatchType!(codeType: stringValue)
                    
                }

                
            }
            
        }
        
    }
    
    
    
    func  rectOfInterest() -> CGRect
    {
        var rectOfInterest = CGRectFromString("{{0.0,0.0},{1.0,1.0}}")
        var photoSize  = CGSizeFromString("{1920,1080}")
        
        var  isFixScale:Bool = false;
        if UIDevice.current.userInterfaceIdiom == .pad || WindowHeight < 481
        {
            isFixScale = true
        }
        
        if(isFixScale)
        {
            
            photoSize = CGSizeFromString("1280,720")
            let p1 = WindowHeight / WindowWidth
            let p2 = photoSize.width / photoSize.height
            
            if(p1 < p1)
            {
                
                let fixHeight = ceilf( ScreenSize.width.swf * p2.swf)
                let fixPadding = (fixHeight - ScreenSize.height.swf)/2
                let x = (( _cropRect!.origin.y.swf + fixPadding)/fixHeight).f
                let width = ( _cropRect!.size.height.swf / fixHeight).f
                rectOfInterest = CGRect.init(x: x,
                                        y: _cropRect!.origin.x + ScreenSize.width,
                                        width: width,
                                        height:_cropRect!.size.width / ScreenSize.width);
            }
            else
            {
                let fixWidth = ceil( ScreenSize.height.swf / p2.swf ).f
                let fixPadding = ceil( (fixWidth.swf - ScreenSize.width.swf)/2 )
                rectOfInterest = CGRect(
                    x: _cropRect!.origin.y / ScreenSize.height ,
                    y: (_cropRect!.origin.x + fixPadding.f)/fixWidth,
                    width: _cropRect!.size.height / ScreenSize.height ,
                    height: _cropRect!.size.width / fixWidth
                )
                
            }
        }
        else
        {
            rectOfInterest = CGRect(
                x: _cropRect!.origin.y / ScreenSize.height ,
                y: _cropRect!.origin.x /  ScreenSize.width,
                width: _cropRect!.size.height / ScreenSize.height ,
                height: _cropRect!.size.width /  ScreenSize.width
            )
            
        }
        
        
        return rectOfInterest;
    }
  
    
    func didChangeAccessCameraState(isGranted:Bool)
    {
        DispatchQueue.main.async {
            
            if self.delegate != nil &&  (self.delegate?.responds(to: #selector(QISCaptureManagerDelegate.didChangeAccessCameraState(isGranted:))))!
            {
                self.delegate?.didChangeAccessCameraState!(isGranted: isGranted)
               
            }
        }
    }
    
    
    
    
}


