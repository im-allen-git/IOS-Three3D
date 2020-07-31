//
//  ViewController.swift
//  Three3D
//
//  Created by admin on 2020/7/31.
//  Copyright © 2020年 Kairong. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, ESPTouchDelegate  {
@IBOutlet weak var nextStepBtn: UIButton!
    let fileManager = FileManager.default
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.et webView = WKWebView()
        
        let webView = WKWebView()
        
        webView.frame = self.view.bounds
        
        // 禁止顶部下拉和底部上拉效果，适用在  不让webview 有多余的滚动   设置后，滚动范围跟网页内容的高度相同
        webView.scrollView.bounces = false	
        
        // 打开左划回退功能：
        webView.allowsBackForwardNavigationGestures = true
        
        let bundlePath = Bundle.main.bundlePath
        
        let path = "file://\(bundlePath)/assets/src/index.html"
        
        guard let url = URL(string: path) else {
            return
        }
        
        let request = URLRequest(url: url)
        
        webView.load(request)
        self.view.addSubview(webView)
        


    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /** ESPTouch处理完成 代理方法 */
    func onEsptouchResultAdded(with result: ESPTouchResult!) {
        print("\(result.description)")
    }
    /** 开始网络配置 */
    @IBAction func nextStepTap(_ sender: UIButton) {
        // 初始化task
        let configTask = ESPTouchTask(apSsid: "TP-LINK_XXX", andApBssid: "", andApPwd: "123456789")
        // 设置代理
        configTask?.setEsptouchDelegate(self)
        // 显示等待框
//        UIApplication.shared.windows[0].makeToastActivity()
        // 开始配置
        DispatchQueue.global(qos: .userInitiated).async {
            let result = configTask?.executeForResult()!
            // 在主线程中显示结果
            DispatchQueue.main.async {
                // 隐藏等待框
//                UIApplication.shared.windows[0].hideToastActivity()
                // 重新启用连接按钮
//                self.nextStepBtn.enable()
                // 判断配置结果
                if (result?.isSuc)! {
//                    UIAlertView().alert(message: "配置成功")
                } else {
//                    UIAlertView().alert(message: "连接超时")
                }
            }
        }
    }
    
    /**
     进行文件保存
     */
    
    func saveFile(fileName: String, receivedString: String){
        let filePath:String = NSHomeDirectory() + "/Documents/printer3d/" + fileName;
        let exist = fileManager.fileExists(atPath: filePath);//将 文件地址存到 变量 exist中
        if exist{
            try! fileManager.removeItem(atPath: filePath)
        }
        
        
        let createSuccess = fileManager.createFile(atPath: filePath,contents:nil,attributes:nil)
        
        print("文件创建结果: \(createSuccess)")
        
        
        try! receivedString.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
        
    }
}

