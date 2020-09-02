import UIKit
import JavaScriptCore
import WebKit

class ViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
    
    let appDeleagte = UIApplication.shared.delegate as! AppDelegate
    var message = "";
    
    var screenWidth:CGFloat = 0;
    var screenHeight:CGFloat = 0;
    var isFlag = false;
    
    
    lazy var webView: WKWebView = {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.userContentController = WKUserContentController()
        
        //监听js
        configuration.userContentController.add(WeakScriptMessageDelegate.init(self), name: "callbackHandle")
        configuration.userContentController.add(WeakScriptMessageDelegate.init(self), name: "callbackHandle2")
        configuration.userContentController.add(WeakScriptMessageDelegate.init(self), name: "jumpPage")
        configuration.userContentController.add(WeakScriptMessageDelegate.init(self), name: "logMessage")
        configuration.userContentController.add(WeakScriptMessageDelegate.init(self), name: "saveStl")
        
        
        var webView = WKWebView(frame: self.view.frame, configuration: configuration)
        webView.scrollView.bounces = true
        webView.scrollView.alwaysBounceVertical = true
        webView.navigationDelegate = self
        webView.scrollView.bounces = false
        return webView
    }()
    
    // let HTML = try! String(contentsOfFile: Bundle.main.path(forResource: "index", ofType: "html")!, encoding: String.Encoding.utf8)
    
    override func viewDidLoad() {
        self.navigationController?.navigationBar.isTranslucent = false
        
        super.viewDidLoad()
        // title = "WebViewJS交互Demo"
        view.backgroundColor = .white
        view.addSubview(webView)
        
        screenWidth = self.view.frame.width;      //the main screen size of width;
        screenHeight = self.view.frame.height;    //the main screen size of height;
        
        
        if(StringTools.isEmpty(str: message)){
            loadHtml(htmlUrl: HtmlConfig.INDEX_HTML)
        } else{
            checkAndJump(code: message)
        }
        
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        
        if(isFlag){
            let rotation : UIInterfaceOrientationMask = [.landscapeLeft, .landscapeRight]
            appDeleagte.blockRotation = rotation
            
            self.webView.frame = CGRect(x: 0, y: 0, width: screenHeight, height: screenWidth )
        } else{
            let rotation : UIInterfaceOrientationMask = [.portrait]
            appDeleagte.blockRotation = rotation
            
            self.webView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        switch message.name {
        case "callbackHandle":
            //单个参数
            print("\(message.body)")
            break
        case "callbackHandle2":
            //多个参数
            if let dic = message.body as? NSDictionary {
                let key: String = (dic["key"] as AnyObject).description
                let value: String = (dic["value"] as AnyObject).description
                
                print("key: \(key)")
                print("value: \(value)")
                
            }
            break
        case "jumpPage":
            let code = message.body
            checkAndJump(code: code as! String)
            break
        case "logMessage":
            print(message.body)
            break
        case "saveStl":
            var fileTxt = ""
            var fileName = ""
            var imgData = ""
            
            if let dic = message.body as? NSDictionary{
                
                fileTxt = (dic["fileTxt"] as AnyObject).description
                fileName = (dic["fileName"] as AnyObject).description
                imgData = (dic["imgData"] as AnyObject).description
            }
            
            if(StringTools.isNotEmpty(str: fileTxt) && StringTools.isNotEmpty(str: fileName) && StringTools.isNotEmpty(str: imgData)){
                
                
                // 将 base64的图片字符串转化成Data
                let imageData2 = Data(base64Encoded: imgData)
                // 将Data转化成图片
                let image2 = UIImage(data: imageData2!)
                
                // 随机生成的唯一文件名称
                let randomFileName = FileTools.getRandomFilePath();
                
                // 保存图片信息
                let imgName = FileTools.printer3dPath + "/" + randomFileName + ".png"
                try? image2!.pngData()?.write(to: URL(fileURLWithPath: imgName))
                
                var isSu = FileManager.default.fileExists(atPath: imgName)
                if(isSu){
                    print("save img success:" + imgName)
                    isSu = WebHost.saveStl(fileTxt : fileTxt, fileName : fileName ,imgName : imgName, randomFileName : randomFileName)
                    print("saveStl:" + String(isSu))
                } else{
                    print("save img errror")
                }
                if(isSu){
                    webView.evaluateJavaScript("afterSTLImg()") { (response, error) in
                        print("response:", response ?? "No Response", "\n", "error:", error ?? "No Error")
                    }
                }
                else{
                    webView.evaluateJavaScript("saveImgFalse()") { (response, error) in
                        print("response:", response ?? "No Response", "\n", "error:", error ?? "No Error")
                    }
                    
                }
            }
            
            break
        default: break
        }
        //print(message.body)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func checkAndJump(code : String){
        switch code {
        case "1":
            loadHtml(htmlUrl : HtmlConfig.MYMODULE_HTML)
        case "2":
            loadHtml(htmlUrl : HtmlConfig.SHOP_HTML)
        case "3":
            loadHtml(htmlUrl : HtmlConfig.INDEX_HTML)
        case "4":
            self.webView.frame = CGRect(x: 0, y: 0, width: screenHeight, height: screenWidth )
            loadHtml(htmlUrl : HtmlConfig.BULID_MODULE_URL)
        case "5":
            loadHtml(htmlUrl : HtmlConfig.INDEX_HTML)
        case "6":
            loadHtml(htmlUrl : HtmlConfig.INDEX_HTML)
        case "61":
            loadHtml(htmlUrl : HtmlConfig.INDEX_HTML)
        case "7":
            loadHtml(htmlUrl : HtmlConfig.INDEX_HTML)
        case "8":
            loadHtml(htmlUrl : HtmlConfig.INDEX_HTML)
        default: break
        }
        if(code == "4"){
            print("screenWidth:")
            print(screenWidth)
            print("screenHeight:")
            print(screenHeight)
            isFlag = true
            
            
            //强制设置成横屏
            //进入下一页面，转换为横屏
            //            let rotation : UIInterfaceOrientationMask = [.landscapeLeft, .landscapeRight]
            //            appDeleagte.blockRotation = rotation
            //            self.webView.frame = CGRect(x: 0, y: 0, width: screenHeight, height: screenWidth )
            
            
            
            
            //            let secondView = BulidModuleController()
            //            //跳转
            //            self.navigationController?.pushViewController(secondView , animated: true)
            
            
            
        } else{
            isFlag = false
            
            //            let rotation : UIInterfaceOrientationMask = [.portrait]
            //            appDeleagte.blockRotation = rotation
            //            self.webView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
        }
    }
    
    
    func loadHtml(htmlUrl : String){
        // 加载本地Html页面
        guard let url = URL(string: htmlUrl) else {
            print("load html error!!!!!!!")
            return
        }
        let request = URLRequest(url: url)
        print("load html -----" + htmlUrl)
        webView.load(request)
        
        //        webView.loadHTMLString(htmlUrl, baseURL: nil)
        //        print("load html -----")
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //如果不设置该页面的竖屏， 在屏幕锁定打开的情况下，竖屏First -> 横屏Second -> 切换到后台 -> 进入前台 -> 返回竖屏First 会出现状态栏已竖屏，其他内容仍然横屏切换的问题
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    
    
    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "saveStl")
        print("WKWebViewController is deinit")
    }
    
    
}
