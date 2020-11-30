//
//  WebHost.swift
//  Three3D
//
//  Created by admin on 2020/8/5.
//  Copyright © 2020年 Kairong. All rights reserved.
//

import Foundation
import Alamofire



// 定义一个模型 该模型实现SwiftJavaScriptDelegate协议
class  WebHost : NSObject{
    
    
    static func getRadomFileName(){
        
        
    }
    
    /**
     保存stl和img文件信息
     */
    static func saveStl(fileTxt: String,  fileName: String, imgName: String, randomFileName: String, imgData: Data,shortImgName: String)-> Bool{
        
        var isSu:Bool = false
        
        if(StlDealTools.checkIsExistsFile(fileName: fileName)){
            return false;
        }
        
        // 倒序获取定位数据
        let suffixNum = StringTools.positionOf(str:fileName,sub:".", backwards:true)
        // 头部截取
        //let fileNamePre: String = String(fileName.prefix(suffixNum))
        // 尾部截取
        let endSuffix: String = String(fileName.suffix(fileName.count - suffixNum))
        
        // stl文件全路径（无后缀）
        let realPathPre: String = FileTools.printer3dPath + "/" + randomFileName
        let realFileName = realPathPre + endSuffix
        
        
        var uuid = HtmlConfig.uuid
        if(StringTools.isEmpty(str: HtmlConfig.uuid)){
            uuid = HTKeychainManager.getUserAccount(server: HTKeychainManager.serverName)
        }
        if(StringTools.isEmpty(str: uuid)){
            uuid = UUID().uuidString
            isSu = HTKeychainManager.save(server: HTKeychainManager.serverName, account: uuid, password: "")
            if(isSu){
                HtmlConfig.uuid = uuid
            }
        } else{
            isSu = true
        }
        
        if(isSu){
            // 保存stl文件
            isSu = FileTools.saveFile(fileName:realFileName, receivedString: fileTxt);
            if(isSu){
                
                let tempStlName  = StringTools.replaceString(str: realFileName, subStr: "/Documents/", replaceStr: "/tmp/")
                if(!FileTools.fileIsExists(path: tempStlName)){
                    isSu = FileTools.copyFile(sourceUrl: realFileName, targetUrl: tempStlName)
                }
                
                // let time: TimeInterval = 1.0
                // DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + time) {
                // 进行文件压缩
                let zipName = realPathPre + ".zip"
                isSu = FileTools.zipFile(sourceFileName: realFileName, destZipName: zipName)
                // isSu = FileTools.zipFile(sourceFileName: imgName, destZipName: FileTools.printer3dPath + "/" + randomFileName + ".zip")
                if(isSu){
                    // 保存到数据库
                    let stlGcode:StlGcode = StlGcode()
                    
                    stlGcode.id = 0
                    stlGcode.size = "0 K"
                    stlGcode.height = "0"
                    stlGcode.length = "0"
                    stlGcode.width = "0"
                    stlGcode.material = "0 MM"
                    stlGcode.realStlName = realFileName
                    stlGcode.sourceStlName = fileName
                    stlGcode.sourceZipStlName = zipName
                    stlGcode.createTime = StlDealTools.getNowTheTime()
                    stlGcode.localImg = imgName
                    stlGcode.exeTime = 0
                    stlGcode.exeTimeStr = "00:00:00"
                    stlGcode.flag = 0
                    stlGcode.localFlag = 0
                    // 保存到字典中，相当于Java的map
                    StlDealTools.saveStlInfo(realFilePath: realFileName, stlGcode: stlGcode)
                    
                    // 异步处理上传任务
                    DispatchQueue.global().async {
                        print("异步执行上传任务")
                        self.uploadStl(zipName: zipName, pathPre: realPathPre, stlGcode:  stlGcode, tempRandomName: randomFileName, realFileName: realFileName, uuid: uuid, imgData: imgData,shortImgName: shortImgName)
                        // DispatchQueue.main.async {//串行、异步 print("在主队列执行刷新界面任务") }
                    }
                }
                //}
            }
        }
        return isSu
    }
    
    
    
    
    /**
     上传stl文件
     */
    static func uploadStl(zipName: String,pathPre: String, stlGcode:  StlGcode, tempRandomName: String, realFileName: String, uuid: String, imgData: Data,shortImgName: String){
        
        // ssl授权
        AlamofireTools.authSsl()
        
        let suffixNum = StringTools.positionOf(str:zipName,sub:"/", backwards:true)
        // 头部截取
        //let fileNamePre: String = String(fileName.prefix(suffixNum))
        // 尾部截取
        let endSuffix: String = String(zipName.suffix(zipName.count - suffixNum - 1))
        let shortName = endSuffix
        
        let parameters:NSMutableDictionary = NSMutableDictionary()
        parameters.setValue("token", forKey: "token")
        parameters.setValue("telephone", forKey: "telephone")
        parameters.setValue(uuid, forKey: "uuid")
        
        print("uuid:" + uuid)
        let url = URL(string: ServerConfig.FILE_UPLOAD_URL)
        
        
        AlamofireTools.sharedSessionManager.upload(multipartFormData: { (multipartFormData) in
            // Alamofire.upload(multipartFormData: { (multipartFormData) in
            
            let upData = NSData.init(contentsOfFile: zipName)
            let mimeType = FileTools.mimeType(pathExtension: zipName)
            multipartFormData.append(Data.init(referencing: upData!), withName: "file", fileName: shortName, mimeType: mimeType)
            multipartFormData.append(imgData, withName: "file", fileName: shortImgName, mimeType: "image/png")
            
            //遍历字典
            for (key, value) in parameters {
                let str:String = value as! String
                let _datas:Data = str.data(using: String.Encoding.utf8)!
                multipartFormData.append(_datas, withName: key as! String)
            }
        }, to: url!) { (result) in
            switch result { 
            case .success(let upload, _, _):
                upload.responseJSON(completionHandler: { (response) in
                    if let value = response.result.value{
                        let rs = value as! NSDictionary
                        print(rs)
                        self.dealUploadJson(rs: rs, stlGcode: stlGcode, tempRandomName: tempRandomName, realFileName: realFileName, uuid: uuid)
                    }
                })
            case .failure:
                print("网络异常")
            }
        }
        
    }
    
    
    
    /**
     处理上传stl后返回结果
     */
    static func dealUploadJson(rs: NSDictionary, stlGcode: StlGcode, tempRandomName: String, realFileName: String, uuid: String){
        
        // 将返回结果做json处理
        //首先判断能不能转换
        //  && JSONSerialization.isValidJSONObject(rs)
        
        // StringTools.isNotEmpty(str: rs) && JSONSerialization.isValidJSONObject(rs)
        //let json =  try JSONSerialization.jsonObject(with: rs.data(using: .utf8)!, options: .mutableContainers) as AnyObject
        //let code:Int = json["code"] as! Int
        
        let code:Int = rs.object(forKey: "code")! as! Int
        
        if(code == 200){
            let rsMap = rs.object(forKey: "data")! as! String
            
            let rsJson = StringTools.stringValueDic(rsMap)
            
            // 网络图片
            let imgUrl = rsJson!["img"] as! String
            let tempLocal:Int = StringTools.positionOf(str: imgUrl, sub: "/ios/", backwards: true)
            let tempUrlImg = String(imgUrl.suffix(imgUrl.count - tempLocal))
            stlGcode.urlImg = ServerConfig.SERVER_URL_PRE + tempUrlImg
            
            
            let currentGcode = rsJson!["gcode"] as! String
            stlGcode.serverZipGcodeName = currentGcode
            // 如果上传成功后，下载gcode文件
            if(StringTools.isNotEmpty(str: currentGcode)){
                let outFileName = tempRandomName + ".gcode.zip"
                AlamofireTools.downFile(urlString: ServerConfig.FILE_DOWN_URL + currentGcode + "&uuid=" + uuid,outFileName: outFileName, tempRandomName : tempRandomName, realFileName : realFileName, stlGcode : stlGcode, currentGcode: currentGcode)
            }
        }
        
    }
    
    
    // 设置打印机打印界面
    static func setPrinterInfo(){
        if(PrinterConfig.STL_GCODE != nil && StringTools.isNotEmpty(str: (PrinterConfig.STL_GCODE?.localGcodeName)!)){
            let tampMap: [String:String]  = [:]
            // 显示打印信息
            print("显示打印信息")
        }
    }
    
    
    // 上传到marlin打印机
    static func postTo3dPrinter(stlGcode: StlGcode){
        if(FileTools.fileIsExists(path: stlGcode.localGcodeName!)){
            
            // ssl授权
            // AlamofireTools.authSsl()
            let url = URL(string: PrinterConfig.getPostFileUrl())
            
            
            print("url:" + url!.description)
            
            var headers = [String: String]()
            headers["Content-Type"] = "multipart/form-data"
            headers["Connection"] = "keep-alive"
            headers["Accept"] = "*/*"
            headers["User-Agent"] = "Mozilla/5.0 (Windows Nt 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.75 Safari/537.36"
            
            let fileSize = StlDealTools.getSize(filePath: stlGcode.localGcodeName!)
            headers["Content-Length"] = String(fileSize)
            
            print(headers.description)
            
            
            
            //AlamofireTools.sharedSessionManagerEsp.upload(Data.init(referencing: upData!), to: url!, method: .post, headers: headers)
            
            AlamofireTools.sharedSessionManager.upload(multipartFormData: { (multipartFormData) in
                // Alamofire.upload(multipartFormData: { (multipartFormData) in
                
                let upData = NSData.init(contentsOfFile: stlGcode.localGcodeName!)
                let mimeType = FileTools.mimeType(pathExtension: stlGcode.localGcodeName!)
                
                var shortName = stlGcode.sourceStlName!
                
                shortName = StringTools.replaceString(str: shortName, subStr: ".stl", replaceStr: ".gco")
                print("mimeType:" + mimeType)
                print("shortName:" + shortName)
                multipartFormData.append(Data.init(referencing: upData!), withName: "file", fileName: shortName, mimeType: mimeType)
                
            }, to: url!) { (result) in
                switch result {
                case .success(let upload, _, _):
                    upload.responseJSON(completionHandler: { (response) in
                        if let responSEObject = response.result.value{
                            print("responSEObject")
                            print(responSEObject)
                            
                            if let jsonResult = responSEObject as? Dictionary<String,AnyObject> {
                                // do whatever with jsonResult
                                let rs = (jsonResult["status"] as! String).lowercased()
                                if(StringTools.isNotEmpty(str: rs) && (rs.contains("OK") || rs.contains("ok"))){
                                    // 上传成功，开始打印
                                    // 更新上传成功标示
                                    stlGcode.flag = 1
                                    StlDealTools.saveStlInfo(realFilePath: stlGcode.realStlName!, stlGcode: stlGcode)
                                    self.printNow()
                                } else{
                                    // 上传失败
                                    print("上传失败")
                                }
                            } else{
                                print("上传返回结果异常")
                            }
                        }
                    })
                case .failure:
                    print("网络异常")
                }
            }
            
            
        } else{
            // 本地文件找不到
            print("本地文件找不到")
        }
    }
    
    // 调用marlin命令进行打印
    static func printNow(){
        var rs: String  = "";
        let tempGcode = PrinterConfig.STL_GCODE?.sourceStlName
        let gcodeName = StringTools.replaceString(str: tempGcode!, subStr: "stl", replaceStr: "gco")
        print("tempGcode:" + tempGcode!)
        print("gcodeName:" + gcodeName)
        
        let tempUrl = PrinterConfig.getPrinterCommond(gcodeName: gcodeName)
        
        print("tempUrl:" + tempUrl)
        
        // ssl授权
        // AlamofireTools.authSsl()
        Alamofire.request(tempUrl).validate().responseData{(DDataRequest) in
            if DDataRequest.result.isSuccess {
                rs = String.init(data: DDataRequest.data!, encoding: String.Encoding.utf8)!
                print("getUrl:" + tempUrl + "--" + rs)
                // 调用成功，准备打印
                
            }
            if DDataRequest.result.isFailure {
                print("getUrl:" + tempUrl + "失败！！！")
            }
        }
    }
    
    
}







