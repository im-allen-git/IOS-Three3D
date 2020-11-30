import UIKit
import JavaScriptCore
import WebKit
import Alamofire


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
            
            PrinterConfig.ESP_8266_URL = "http://" + ip
            print(PrinterConfig.ESP_8266_URL)
            var isSu = FileTools.saveToPlist(keyName: ServerConfig.WiFi_URL_KEY, val: PrinterConfig.ESP_8266_URL)
            if(!isSu){
                isSu = FileTools.saveToPlist(keyName: ServerConfig.WiFi_URL_KEY, val: PrinterConfig.ESP_8266_URL)
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
    var codeStl:String = "-1";
    
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
        configuration.userContentController.add(WeakScriptMessageDelegate.init(self), name: "printerGcode")
        configuration.userContentController.add(WeakScriptMessageDelegate.init(self), name: "firstAccess")
        configuration.userContentController.add(WeakScriptMessageDelegate.init(self), name: "firstBuild")
        configuration.userContentController.add(WeakScriptMessageDelegate.init(self), name: "firstMyWorld")
        
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
        
        view.translatesAutoresizingMaskIntoConstraints = Bool(truncating: 0);
        
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
            loadHtml(htmlUrl: HtmlConfig.FIRST_WELCOME)
        } else{
            checkAndJump(code: message)
        }
        
        if(codeStl == "0" && StlDealTools.stlMap.count == 0){
            FileTools.getFromstlGcodeList()
        }
        
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        StlDealTools.webView = webView
        
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
            
        case "-1":
            
            var accessFlag = FileTools.getByPlist(keyName: ServerConfig.FIRST_ACCESS)
            if(StringTools.isEmpty(str: accessFlag)){
                accessFlag = "0"
            }
            var bulidFlag = FileTools.getByPlist(keyName: ServerConfig.FIRST_BUILD)
            if(StringTools.isEmpty(str: bulidFlag)){
                bulidFlag = "0"
            }
            
            var myWorldFlag = FileTools.getByPlist(keyName: ServerConfig.FIRST_MY_WORLD)
            if(StringTools.isEmpty(str: myWorldFlag)){
                myWorldFlag = "0"
            }
            
            webView.evaluateJavaScript("firstCheck('" + accessFlag + "','" + bulidFlag + "','" + myWorldFlag + "')") { (response, error) in
                //print("response:", response ?? "No Response", "\n", "error:", error ?? "No Error")
            }
            break
            
        case "0":
            PrinterConfig.setWifiInfo()
            
            let tempStr = StlDealTools.getLocalStl()
            webView.evaluateJavaScript("getDefaultStl('" + tempStr + "')") { (response, error) in
                //print("response:", response ?? "No Response", "\n", "error:", error ?? "No Error")
            }
            break
        case "1":
            let tempStr = StlDealTools.getStlList()
            webView.evaluateJavaScript("thisParamInfo(2,'" + tempStr + "')") { (response, error) in
                //print("response:", response ?? "No Response", "\n", "error:", error ?? "No Error")
            }
            break
        case "3":
            PrinterConfig.setWifiInfo()
            
            let tempStr = StlDealTools.getLocalStl()
            webView.evaluateJavaScript("getDefaultStl('" + tempStr + "')") { (response, error) in
                //print("response:", response ?? "No Response", "\n", "error:", error ?? "No Error")
            }
            break
        case "4":
            let tempStr = StlDealTools.getStlList()
            var bulidFlag = FileTools.getByPlist(keyName: ServerConfig.FIRST_BUILD)
            if(StringTools.isEmpty(str: bulidFlag)){
                bulidFlag = "0"
            }
            var myWorldFlag = FileTools.getByPlist(keyName: ServerConfig.FIRST_MY_WORLD)
            if(StringTools.isEmpty(str: myWorldFlag)){
                myWorldFlag = "0"
            }
            webView.evaluateJavaScript("getLocalAppSTL('" + tempStr + "','" + bulidFlag + "','" + myWorldFlag + "')") { (response, error) in
                //print("response:", response ?? "No Response", "\n", "error:", error ?? "No Error")
            }
            break
        case "5":
            let flag: Int = PrinterConfig.checkWifi()
            webView.evaluateJavaScript("connectStatus('" + String(flag) + "')") { (response, error) in
                //print("response:", response ?? "No Response", "\n", "error:", error ?? "No Error")
            }
            break
        case "6":
            let flag: Int = PrinterConfig.checkWifi()
            webView.evaluateJavaScript("connectStatus('" + String(flag) + "')") { (response, error) in
                //print("response:", response ?? "No Response", "\n", "error:", error ?? "No Error")
            }
            break
        case "61":
            PrinterConfig.setWifiInfo()
            self.wirteWifiInfo()
            break
        case "7":
            if(StringTools.isNotEmpty(str: PrinterConfig.LOCAL_GCODE) || StringTools.isNotEmpty(str: PrinterConfig.GEN_GCODE)){
                if(CacheUtil.sdGcodeMap.count == 0){
                    CacheUtil.getSDList(flag: 1)
                }
                var tempStlGcode: StlGcode = StlGcode()
                if(StringTools.isNotEmpty(str: PrinterConfig.LOCAL_GCODE)){
                    tempStlGcode = StlDealTools.localMapStl[PrinterConfig.LOCAL_GCODE]!
                } else if(StringTools.isNotEmpty(str: PrinterConfig.GEN_GCODE)){
                    tempStlGcode = StlDealTools.stlMap[PrinterConfig.GEN_GCODE]!
                }
                if(StringTools.isNotEmpty(str: tempStlGcode.localGcodeName!)){
                    PrinterConfig.STL_GCODE = tempStlGcode
                    WebHost.setPrinterInfo()
                    if(tempStlGcode.flag == 0){
                        self.beforePostTo3dPrinter(stlGcode: tempStlGcode)
                    } else{
                        WebHost.printNow()
                    }
                }
            } else{
                print("no print gcode")
            }
            break;
        default:
            break
        }
        
    }
    
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        switch message.name {
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
                let image2 = UIImage.init(data: imageData2!)
                
                // 随机生成的唯一文件名称
                let randomFileName = FileTools.getRandomFilePath();
                
                
                var isSu = FileTools.createDir(dirPath: FileTools.printer3dPath)
                if(isSu){
                    // 保存图片信息
                    let imgName = FileTools.printer3dPath + "/" + randomFileName + ".png"
                    let shortName = randomFileName + ".png"
                    
                    print("imgName:")
                    print(imgName)
                    
                    do {
                        try image2!.pngData()?.write(to: URL(fileURLWithPath: imgName))
                    } catch  {
                        print(error)
                    }
                    isSu = FileManager.default.fileExists(atPath: imgName)
                    if(isSu){
                        // 文件copy到 APP_TEMP_PATH
                        isSu = FileTools.createDir(dirPath: FileTools.APP_TEMP_PATH)
                        if(isSu){
                            isSu = FileTools.copyFile(sourceUrl: imgName, targetUrl: FileTools.APP_TEMP_PATH + "/" + randomFileName + ".png")
                        }
                    }
                    
                    
                    if(isSu){
                        print("save img success:" + imgName)
                        // 图片也上传到服务器
                        let image = UIImage(named: imgName)
                        //将图片转化为JPEG类型的data 后面的参数是压缩比例
                        let pngImage = image!.pngData()
                        
                        isSu = WebHost.saveStl(fileTxt : fileTxt, fileName : fileName ,imgName : imgName, randomFileName : randomFileName, imgData: pngImage!, shortImgName: shortName)
                        print("saveStl:" + String(isSu))
                        
                        
                    } else{
                        print("save img errror")
                    }
                    if(isSu){
                         let tempStr = StlDealTools.getStlList()
                        webView.evaluateJavaScript("afterSTLImg('" + tempStr + "')") { (response, error) in
                                        print("response:", response ?? "No Response", "\n", "error:", error ?? "No Error")
                                    }
                    } else{
                        webView.evaluateJavaScript("saveImgFalse()") { (response, error) in
                            //print("response:", response ?? "No Response", "\n", "error:", error ?? "No Error")
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
            
        case "printerGcode":
            
            var moduleName = ""
            var type = ""
            
            if let dic = message.body as? NSDictionary{
                moduleName = (dic["moduleName"] as AnyObject).description
                type = (dic["type"] as AnyObject).description
            }
            
            if(type == "0"){
                PrinterConfig.LOCAL_GCODE = moduleName;
                PrinterConfig.GEN_GCODE = "";
            } else{
                PrinterConfig.LOCAL_GCODE = "";
                PrinterConfig.GEN_GCODE = moduleName;
            }
            
            if(StringTools.isNotEmpty(str: PrinterConfig.ESP_8266_URL)){
                checkAndJump(code: "7")
            } else{
                checkAndJump(code: "61")
            }
            
            break;
            
        case "firstAccess":
            var isSu = FileTools.saveToPlist(keyName: ServerConfig.FIRST_ACCESS, val: "1")
            if(!isSu){
                isSu = FileTools.saveToPlist(keyName: ServerConfig.FIRST_ACCESS, val: "1")
            }
            checkAndJump(code: "3")
            break;
            
        case "firstBuild":
            var isSu = FileTools.saveToPlist(keyName: ServerConfig.FIRST_BUILD, val: "1")
            if(!isSu){
                isSu = FileTools.saveToPlist(keyName: ServerConfig.FIRST_BUILD, val: "1")
            }
            break;
            
        case "firstMyWorld":
            var isSu = FileTools.saveToPlist(keyName: ServerConfig.FIRST_MY_WORLD, val: "1")
            if(!isSu){
                isSu = FileTools.saveToPlist(keyName: ServerConfig.FIRST_MY_WORLD, val: "1")
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
        
        StlDealTools.code = codeStl
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
            loadHtml(htmlUrl : HtmlConfig.PRINTER_STATUS_HTML)
        case "8":
            loadHtml(htmlUrl : HtmlConfig.INDEX_HTML)
        case "9":
            loadHtml(htmlUrl : HtmlConfig.WELCOME_SLIDE)
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
        
    }
    
    
    
    func beforePostTo3dPrinter(stlGcode: StlGcode){
        if(StringTools.isNotEmpty(str: PrinterConfig.ESP_8266_URL)){
            WebHost.postTo3dPrinter(stlGcode: stlGcode)
        } else{
            // 无记录或者打印机没有连接
            print("打印机没有连接")
            checkAndJump(code: "61")
        }
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
        
        self.okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default,handler: {
            action in if(StringTools.isNotEmpty(str: PrinterConfig.ESP_8266_URL) && (StringTools.isNotEmpty(str: PrinterConfig.GEN_GCODE) || StringTools.isNotEmpty(str: PrinterConfig.LOCAL_GCODE))){
                self.checkAndJump(code: "7")
            } else{
                self.checkAndJump(code: "5")
            }
        })
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
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "printerGcode")
        
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "firstAccess")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "firstBuild")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "firstMyWorld")
        
        
        print("WKWebViewController is deinit")
    }
    
    
}
