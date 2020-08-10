//
//  WebHost.swift
//  Three3D
//
//  Created by admin on 2020/8/5.
//  Copyright © 2020年 Kairong. All rights reserved.
//

import Foundation
import UIKit
import JavaScriptCore
import Alamofire

// 定义协议SwiftJavaScriptDelegate 该协议必须遵守JSExport协议
@objc protocol SwiftJavaScriptDelegate: JSExport {
    
    // js调用App方法时传递多个参数 并弹出对话框 注意js调用时的函数名
    func showDialog(_ title: String, message: String)
    
    // js调用App的功能后 App再调用js函数执行回调
    func callHandler(_ handleFuncName: String)
    
    // 保存页面传递过来的stl和截图文件
    func saveStl(_ fileTxt: String,  fileName: String,  imgData: String)-> Bool
    
    func getStlList()-> String
    
}

// 定义一个模型 该模型实现SwiftJavaScriptDelegate协议
@objc class SwiftJavaScriptModel: NSObject, SwiftJavaScriptDelegate {
    
    weak var controller: UIViewController?
    weak var jsContext: JSContext?
    
    func showDialog(_ title: String, message: String) {
        
        // 弹框
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
        self.controller?.present(alert, animated: true, completion: nil)
    }
    
    func callHandler(_ handleFuncName: String) {
        
        let jsHandlerFunc = self.jsContext?.objectForKeyedSubscript("\(handleFuncName)")
        let dict = ["name": "sean", "age": 18] as [String : Any]
        let _ = jsHandlerFunc?.call(withArguments: [dict])
    }
    
    
    /**
     获取本地stl的数据
     */
    func getStlList()-> String{
        return StringTools.getJSONStringFromArray(array: StlDealTools.getLocalStl() as NSArray)
    }
    
    
    /**
     保存stl和img文件信息
     */
    func saveStl(_ fileTxt: String,  fileName: String,  imgData: String)-> Bool{
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
        // 随机生成的唯一文件名称
        let randomFileName = FileTools.getRandomFilePath();
        // stl文件全路径（无后缀）
        let realPathPre: String = FileTools.printer3dPath + "/" + randomFileName
        let realFileName = realPathPre + endSuffix
        
        // 保存图片信息
        let imgName = FileTools.printer3dPath + "/" + randomFileName + ".png"
        isSu = FileTools.saveFile(fileName: imgName, receivedString: imgData)
        
        if(isSu){
            // 保存stl文件
            isSu = FileTools.saveFile(fileName:realFileName, receivedString: fileTxt);
            if(isSu){
                // 进行文件压缩
                let zipName = realPathPre + ".zip"
                isSu = FileTools.zipFile(sourceFileName: realFileName, destZipName: zipName)
                if(isSu){
                    // 保存到数据库
                    let stlGcode:StlGcode = StlGcode()
                    
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
                    stlGcode.exeTimeStr = "00:00:00"
                    // 保存到字典中，相当于Java的map
                    StlDealTools.saveStlInfo(realFilePath: realFileName, stlGcode: stlGcode)
                    
                    // 异步处理上传任务
                    DispatchQueue.global().async {
                        print("异步执行上传任务")
                        self.uploadStl(zipName: zipName, pathPre: realPathPre, stlGcode:  stlGcode, tempRandomName: randomFileName, realFileName: realFileName)
                        // DispatchQueue.main.async {//串行、异步 print("在主队列执行刷新界面任务") }
                    }
                }
            }
        }
        return isSu
    }
    
    

    
    /**
     上传stl文件
     */
    func uploadStl(zipName: String,pathPre: String, stlGcode:  StlGcode, tempRandomName: String, realFileName: String){
        
        
        let parameters:NSMutableDictionary = NSMutableDictionary()
        parameters.setValue("token", forKey: "token")
        parameters.setValue("telephone", forKey: "telephone")
        let url = URL(string: ServerConfig.FILE_UPLOAD_URL)
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            
            let upData = NSData.init(contentsOfFile: zipName)
            let mimeType = FileTools.mimeType(pathExtension: zipName)
            multipartFormData.append(Data.init(referencing: upData!), withName: "file", fileName: zipName, mimeType: mimeType)
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
                    if let value = response.result.value {
                        self.dealUploadJson(rs: value as! String, stlGcode: stlGcode, tempRandomName: tempRandomName, realFileName: realFileName)
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
    func dealUploadJson(rs: String, stlGcode: StlGcode, tempRandomName: String, realFileName: String){
        do{
            // 将返回结果做json处理
            //首先判断能不能转换
            if (StringTools.isNotEmpty(str: rs) && JSONSerialization.isValidJSONObject(rs)) {
                let json =  try JSONSerialization.jsonObject(with: rs.data(using: .utf8)!, options: .mutableContainers) as AnyObject
                let code:Int = json["code"] as! Int
                if(code == 200){
                    let currentGcode = json["data"] as! String
                    stlGcode.serverZipGcodeName = currentGcode
                    // 如果上传成功后，下载gcode文件
                    if(StringTools.isNotEmpty(str: currentGcode)){
                        let outFileName = tempRandomName + ".gcode.zip"
                        let isSu: Bool = AlamofireTools.downFile(urlString: ServerConfig.FILE_UPLOAD_URL + currentGcode,outFileName: outFileName)
                        if(isSu){
                            let downGcodeFileName = FileTools.printer3dPath + "/" + outFileName
                            // 解压gcode文件
                            FileTools.unzipFile(zipPath: downGcodeFileName, destPath: FileTools.printer3dPath)
                            let gcodePath = FileTools.printer3dPath + "/" + tempRandomName + ".gcode"
                            if(FileTools.fileIsExists(path: gcodePath)){
                                stlGcode.serverZipGcodeName = gcodePath
                                StlDealTools.saveStlInfo(realFilePath: realFileName, stlGcode: stlGcode)
                                // 解析gcode代码，设置文件的大小，耗材等数据
                            }else{
                                print("解压gcode文件异常")
                            }
                        } else{
                            print("下载gcode文件异常")
                        }
                    }
                }
            }else{
                print("上传stl文件结果不能解析:" + rs)
            }
            
        }catch{
            print(error)
        }
    }
    
    
}
