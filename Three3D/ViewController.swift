import UIKit
import JavaScriptCore
import WebKit


extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}




class ViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler, ESPTouchControllerDelegate {
    
    var espController = ESPTouchController()
    func handleConnectionTimeoutAlert(resultCount:Int){
        if(resultCount == 0 ){
            if let ok = self.okAction{
                ok.isEnabled = true
            }
            self.alertController.title = "Connection Timeout"
            self.alertController.message = "no devices found, check if your ESP is in Connection mode!"
        }
    }
    func handleAddedResult(resultCount:Int, bssid: String!, ip:String!){
        if(resultCount >= self.resultExpected ){ //bug on condition, must know why!
            espController.interruptESP();
            if let ok = self.okAction{
                ok.isEnabled = true
            }
        }
        if(resultCount >= 1 ){
            self.resultCount = self.resultCount + 1
            self.alertController.title = "\(self.resultCount) ESP\(self.resultCount > 1 ? "(s)" :" ") connected"
            self.messageResult  += "\(String(describing: bssid)) - ip: \(String(describing: ip))\n";
            self.alertController.message = self.messageResult;
            
            let url = "http://" + ip
            print(url)
            var isSu = FileTools.saveToPlist(keyName: HtmlConfig.WiFi_URL_KEY, val: url)
            if(!isSu){
                isSu = FileTools.saveToPlist(keyName: HtmlConfig.WiFi_URL_KEY, val: url)
            }
        }
    }
    
    
    
    var resultExpected = 0
    var alertController = UIAlertController()
    var messageResult = ""
    var resultCount = 0
    var okAction:UIAlertAction?
    var bssid: String?
    
    @IBOutlet var numberOfDevicesLabel: UILabel!
    @IBOutlet var passwordInputText: UITextField!
    @IBOutlet var ssidInputText: UITextField!
    @IBOutlet var isHiddenSwitch: UISwitch!
    
    @IBAction func onNumberDevicesChange(_ sender: UISlider) {
        resultExpected = Int(sender.value)
        numberOfDevicesLabel.text = resultExpected == 0 ? "All" : resultExpected.description
    }
    
    @IBAction func onChangeIsHidden(_ sender: Any) {
        if(self.isHiddenSwitch.isOn){
            self.ssidInputText.isUserInteractionEnabled = true;
            self.ssidInputText.borderStyle =  UITextField.BorderStyle.roundedRect;
        }
        else {
            self.ssidInputText.isUserInteractionEnabled = false;
            self.ssidInputText.borderStyle =  UITextField.BorderStyle.none;
        }
    }
    

    @IBAction func send(_ sender: UIButton) {
        if  self.ssidInputText.text?.compare("Not Connected to Wifi").rawValue != 0{
            self.espController.delegate = self;
            self.showAlertWithResult(title:"Connetting...",message:"");
            self.espController.sendSmartConfig(bssid: self.bssid!, ssid: self.ssidInputText.text!, password: self.passwordInputText.text!, resultExpected: Int32(self.resultExpected));
        }
    }
    
    
    
    var wifiInfo: Dictionary<String, String> = Dictionary<String, String>()
    
    let appDeleagte = UIApplication.shared.delegate as! AppDelegate
    var message = "";
    
    var screenWidth:CGFloat = 0;
    var screenHeight:CGFloat = 0;
    var isFlag = false;
    var codeStl:String = "0";
    
    lazy var webView: WKWebView = {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true

//        preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
//        preferences.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
//        preferences.setValue(true, forKey: "allowFileAccess")

        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.userContentController = WKUserContentController()
        
        //监听js
//        configuration.userContentController.add(WeakScriptMessageDelegate.init(self), name: "callbackHandle")
//        configuration.userContentController.add(WeakScriptMessageDelegate.init(self), name: "callbackHandle2")
        configuration.userContentController.add(WeakScriptMessageDelegate.init(self), name: "jumpPage")
        configuration.userContentController.add(WeakScriptMessageDelegate.init(self), name: "logMessage")
        configuration.userContentController.add(WeakScriptMessageDelegate.init(self), name: "saveStl")
        configuration.userContentController.add(WeakScriptMessageDelegate.init(self), name: "deleteStl")
        configuration.userContentController.add(WeakScriptMessageDelegate.init(self), name: "sendWifiPass")
        
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
        
//        webView.configuration.preferences.setValue("Yes", forKey: "allowFileAccessFromFileURLs")
//        webView.configuration.preferences.setValue("Yes", forKey: "allowUniversalAccessFromFileURLs")
//        webView.configuration.preferences.setValue("Yes", forKey: "allowFileAccess")

        super.viewDidLoad()
        // title = "WebViewJS交互Demo"
        view.backgroundColor = .white
        view.addSubview(webView)
        
        
        
        
        // wifi准备
        super.viewDidLoad()
        // self.isHiddenSwitch.setOn(false, animated: true);
        //self.ssidInputText.isUserInteractionEnabled = false;
        //self.ssidInputText.borderStyle =  UITextField.BorderStyle.none;
        self.hideKeyboardWhenTappedAround() ;
        
        
        
        // screenWidth = self.view.frame.width      //the main screen size of width;
        // screenHeight = self.view.frame.height    //the main screen size of height;
        
        screenHeight = UIScreen.main.bounds.height
        screenWidth = UIScreen.main.bounds.width

        
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
        
        print("----code"+codeStl+"-----")
        switch(codeStl){
            
        case "0":
            let tempStr = StlDealTools.getLocalStl()
            webView.evaluateJavaScript("getDefaultStl('" + tempStr + "')") { (response, error) in
                print("response:", response ?? "No Response", "\n", "error:", error ?? "No Error")
            }
        break
        
        case "1":
            let tempStr = StlDealTools.getStlList()
            webView.evaluateJavaScript("thisParamInfo(2,'" + tempStr + "')") { (response, error) in
                print("response:", response ?? "No Response", "\n", "error:", error ?? "No Error")
            }
        break
            
        case "3":
            let tempStr = StlDealTools.getLocalStl()
            webView.evaluateJavaScript("getDefaultStl('" + tempStr + "')") { (response, error) in
                print("response:", response ?? "No Response", "\n", "error:", error ?? "No Error")
            }
        break
            
            
        case "4":
            let tempStr = StlDealTools.getStlList()
            webView.evaluateJavaScript("getLocalAppSTL('" + tempStr + "')") { (response, error) in
                print("response:", response ?? "No Response", "\n", "error:", error ?? "No Error")
            }
            break
        case "6":
            let wifiUrl =  FileTools.getByPlist(keyName: HtmlConfig.WiFi_URL_KEY)
            let flag = StringTools.isEmpty(str: wifiUrl) ? 0 : 1
            webView.evaluateJavaScript("connectStatus('" + String(flag) + "')") { (response, error) in
                print("response:", response ?? "No Response", "\n", "error:", error ?? "No Error")
            }
            break
        case "61":
            self.wirteWifiInfo()
            break
        default:
            break
        }
        
    }
    
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        switch message.name {
//        case "callbackHandle":
//            //单个参数
//            print("\(message.body)")
//            break
//        case "callbackHandle2":
//            //多个参数
//            if let dic = message.body as? NSDictionary {
//                let key: String = (dic["key"] as AnyObject).description
//                let value: String = (dic["value"] as AnyObject).description
//
//                print("key: \(key)")
//                print("value: \(value)")
//
//            }
//            break
        case "jumpPage":
            let code = message.body
            checkAndJump(code: code as! String)
            break
        case "logMessage":
            print(message.body)
            
//            let millisecond = Date().timeIntervalSince1970
//
//            let isSu = FileTools.saveToPlist(keyName: "key_" + String(millisecond), val: "99")
//            if(!isSu){
//                print("save error")
//            }
            
            
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
//                let image2 = UIImage(data: imageData2!)
                
                 let image2 = UIImage.init(data: imageData2!)
                
                // 随机生成的唯一文件名称
                let randomFileName = FileTools.getRandomFilePath();
                
                var isSu = FileTools.createDir(dirPath: FileTools.printer3dPath)
                
                if(isSu){
                    // 保存图片信息
                    let imgName = FileTools.printer3dPath + "/" + randomFileName + ".png"
                    do {
                        try image2!.pngData()?.write(to: URL(fileURLWithPath: imgName))
                    } catch  {
                        print(error)
                    }
                    
                    // FileTools.saveFile(fileName: imgName, receivedString: imageData2)
                    // FileManager.default.createFile(atPath: imgName, contents: imageData2, attributes: nil)
                    
                    isSu = FileManager.default.fileExists(atPath: imgName)
                    // var isSu = true

                    if(isSu){
                        print("save img success:" + imgName)
                        isSu = WebHost.saveStl(fileTxt : fileTxt, fileName : fileName ,imgName : imgName, randomFileName : randomFileName)
                        print("saveStl:" + String(isSu))
                    } else{
                        print("save img errror")
                    }
                    if(isSu){
                        webView.evaluateJavaScript("afterSTLImg(\""+StlDealTools.getStlList()+"\")") { (response, error) in
                            print("response:", response ?? "No Response", "\n", "error:", error ?? "No Error")
                        }
                    }
                    else{
                        webView.evaluateJavaScript("saveImgFalse()") { (response, error) in
                            print("response:", response ?? "No Response", "\n", "error:", error ?? "No Error")
                        }
                        
                    }
                } else{
                    print("create img dir error")
                }
                
                
            }
            
            break
        case "deleteStl":
            // print("\(message.body)")
            let realName = message.body;
            let flag = StlDealTools.deleteStl(fileName: realName as! String);
            webView.evaluateJavaScript("deletedAfter("+String(flag)+")") { (response, error) in
                print("response:", response ?? "No Response", "\n", "error:", error ?? "No Error")
            }
            break;
            
            case "sendWifiPass":
            // print("\(message.body)")
            let passWord = message.body as! String;
            
            if(StringTools.isNotEmpty(str: self.wifiInfo["ssid"]!) && StringTools.isNotEmpty(str: self.wifiInfo["bssid"]!)
                && StringTools.isNotEmpty(str: passWord)){
                
                print("ssid:")
                print(self.wifiInfo["ssid"]!)
                print("bssid:")
                print(self.wifiInfo["bssid"]!)
                print("password:")
                print(passWord)
                
                self.espController.delegate = self;
                self.showAlertWithResult(title:"Connetting...",message:"");
                self.espController.sendSmartConfig(bssid: self.wifiInfo["bssid"]!, ssid: self.wifiInfo["ssid"]!, password: passWord, resultExpected: Int32(self.resultExpected));
                
            }
            break;
            
        default: break
        }
        //print(message.body)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // 判断服务器采用的验证方法
        if(challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust){
            if(challenge.previousFailureCount == 0){
                // 如果没有错误的情况下，创建一个凭证，并且使用证书
                let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
                completionHandler(.useCredential,  credential)
            } else{
                completionHandler(.cancelAuthenticationChallenge,  nil)
            }
        }else{
            completionHandler(.cancelAuthenticationChallenge,  nil)
        }
    }
    
    func checkAndJump(code : String){
        codeStl = code;
        switch code {
        case "1":
            loadHtml(htmlUrl : HtmlConfig.MYMODULE_HTML)
        case "2":
            loadHtml(htmlUrl : HtmlConfig.SHOP_HTML)
        case "3":
            loadHtml(htmlUrl : HtmlConfig.INDEX_HTML)
        case "4":
            if(isFlag){
                let rotation : UIInterfaceOrientationMask = [.landscapeLeft, .landscapeRight]
                appDeleagte.blockRotation = rotation
                self.webView.frame = CGRect(x: 0, y: 0, width: screenHeight, height: screenWidth )
            } else{
                let rotation : UIInterfaceOrientationMask = [.portrait]
                appDeleagte.blockRotation = rotation
                self.webView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
            }
            // self.webView.frame = CGRect(x: 0, y: 0, width: screenHeight, height: screenWidth )
            loadHtml(htmlUrl : HtmlConfig.BULID_MODULE_URL)
        case "5":
            loadHtml(htmlUrl : HtmlConfig.PRINTER_INTRO_HTML)
        case "6":
            loadHtml(htmlUrl : HtmlConfig.PRINTER_INTRO_HTML)
        case "61":
            loadHtml(htmlUrl : HtmlConfig.WIFI_PASS_HTML)
        case "7":
            loadHtml(htmlUrl : HtmlConfig.INDEX_HTML)
        case "8":
            loadHtml(htmlUrl : HtmlConfig.INDEX_HTML)
        default:
            codeStl = "0"
            break
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
        // let temoHtmlUrl = "https://www.baidu.com";
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
    
    
    func wirteWifiInfo(){
        let ssid: String = self.wifiInfo["ssid"]!
        let bssid: String = self.wifiInfo["bssid"]!
        
        let jsStr = "wirteWifiInfo('" + ssid + "','" + bssid + "')"
//        webView.evaluateJavaScript(jsStr){
//            (response, error) in
//            print(response)
//            print(error)
//        }
        
        
        webView.evaluateJavaScript(jsStr) { (response, error) in
            print("response:", response ?? "No Response", "\n", "error:", error ?? "No Error")
        }
    }
    
    func showAlertWithResult(title : String,  message: String){
        
        alertController = UIAlertController(title: title, message:
            message, preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel,handler: {
            action in self.espController.interruptESP()
        }))
        
        self.okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default,handler: nil)
        if let ok = self.okAction {
            ok.isEnabled = false
            alertController.addAction(ok)
        }
        self.present(alertController, animated: true, completion: nil)
    
    }
    
    
    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "jumpPage")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "logMessage")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "saveStl")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "deleteStl")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "sendWifiPass")

        print("WKWebViewController is deinit")
    }
    
    
}
