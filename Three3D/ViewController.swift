//
//  ViewController.swift
//  SwiftJavaScriptCore
//
//  Created by myl on 16/6/8.
//  Copyright © 2016年 Mayanlong. All rights reserved.
//

import UIKit
import JavaScriptCore


class ViewController: UIViewController, UIWebViewDelegate {
    
    var webView: UIWebView!
    var jsContext: JSContext!
    
    //获取 AppDelegate 对象
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addWebView()
    }
    
 
    
    
    func addWebView() {
        
        self.webView = UIWebView(frame: self.view.bounds)
        self.view.addSubview(self.webView)
        self.webView.delegate = self
        self.webView.scalesPageToFit = true
        
        // 加载本地Html页面
        guard let url = URL(string: HtmlConfig.INDEX_HTML) else {
            print("load html error!!!!!!!")
            return
        }
        let request = URLRequest(url: url)
    
        // 加载网络Html页面 请设置允许Http请求
//        let url = NSURL(string: "http://www.baidu.com");
//        print(url)
//        let request = NSURLRequest(url: url! as URL)
        
        
        self.webView.loadRequest(request as URLRequest)
        
        // 打开左划回退功能：
        // self.webView.allowsBackForwardNavigationGestures = true
    }
    
    
//    //连接改变时
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool{
        let rurl =  request.url?.absoluteString
        print(rurl)
        if (rurl!.hasPrefix("ios:")){
            let method =  rurl!.components(separatedBy: "@")[1]
            var tempUrl = ""
            if (method == "1"){
                // 我的模型
                tempUrl = HtmlConfig.MYMODULE_HTML
            }else if(method == "2"){
                // 购物商城
                tempUrl = HtmlConfig.SHOP_HTML
            }else if(method == "3"){
                // 模型库首页
                tempUrl = HtmlConfig.INDEX_HTML
            }else if(method == "4"){
                // 创建模型
                tempUrl = HtmlConfig.BULID_MODULE_URL
            }else if(method == "5"){
                // back
                // tempUrl = HtmlConfig.INDEX_HTML
            }else if(method == "6"){
                // 3d打印机
                tempUrl = HtmlConfig.INDEX_HTML
            }else if(method == "61"){
                // PrinterConfig.ESP_8266_URL = "http://10.0.0.34/";
                // 3d打印机
                // tempUrl = HtmlConfig.INDEX_HTML
            }else if(method == "7"){
                // 3d打印机 状态页 status
                tempUrl = HtmlConfig.INDEX_HTML
            }else if(method == "8"){
                // 上传gcode文件给打印机sd卡
                tempUrl = HtmlConfig.INDEX_HTML
            }
            if(method == "4"){
                //该页面显示时可以横竖屏切换
                appDelegate.interfaceOrientations = .allButUpsideDown
            } else{
                //页面退出时还原强制横屏状态
                appDelegate.interfaceOrientations = [.landscapeLeft, .landscapeRight]
            }
            // 加载本地Html页面
            guard let url = URL(string: tempUrl) else {
                return false
            }
            let request = URLRequest(url: url)
            self.webView.loadRequest(request)
            // return true
        }
        return true
    }
    
    
    /**
     加载完成后绑定js调用
     */
    func webViewDidFinishLoad(_ webView: UIWebView) {
        
        self.jsContext = webView.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as! JSContext
        let model = SwiftJavaScriptModel()
        model.controller = self
        model.jsContext = self.jsContext
        
        // 这一步是将SwiftJavaScriptModel模型注入到JS中，在JS就可以通过JsBridge调用我们暴露的方法了。
        self.jsContext.setObject(model, forKeyedSubscript: "JsBridge" as NSCopying & NSObjectProtocol)
        
        // 注册到本地的Html页面中
        guard let url = URL(string: HtmlConfig.INDEX_HTML) else {
            return
        }
        self.jsContext.evaluateScript(try? String(contentsOf: url, encoding: String.Encoding.utf8))
        
        // 注册到网络Html页面 请设置允许Http请求
        //let url = "http://www.mayanlong.com";
        //let curUrl = self.webView.request?.URL?.absoluteString    //WebView当前访问页面的链接 可动态注册
        //self.jsContext.evaluateScript(try? String(contentsOfURL: NSURL(string: url)!, encoding: NSUTF8StringEncoding))
        self.jsContext.exceptionHandler = { (context, exception) in
            print("exception：", exception as Any)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    
    
    
}

