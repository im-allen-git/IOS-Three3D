//
//  AlamofireTools.swift
//  Three3D
//
//  Created by admin on 2020/8/5.
//  Copyright © 2020年 Kairong. All rights reserved.
//
//  网络工具类

import Foundation
import Alamofire

class AlamofireTools: NSObject {
    
    
    
    static func uploadFile(dataPath: String, urlString: String)-> String{
        
        
        
        var rs: String = ""
        Alamofire.upload(URL.init(fileURLWithPath: dataPath), to: urlString).validate().responseData { (DDataRequest) in
            if DDataRequest.result.isSuccess {
                rs = String.init(data: DDataRequest.data!, encoding: String.Encoding.utf8)!
                print("上传结果---------------" + rs)
            }
            if DDataRequest.result.isFailure {
                print("上传失败！！！")
            }
        }
        return rs
        
    }
    
    
    static func downFile(urlString : String, outFileName : String)-> Bool{
        
        var isSu: Bool = false
        
        //指定下载路径和保存文件名
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("/Documents/printer3d/" + outFileName)
            //两个参数表示如果有同名文件则会覆盖，如果路径中文件夹不存在则会自动创建
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        Alamofire.download(urlString, to: destination)
            .downloadProgress { progress in
                print("当前进度: \(progress.fractionCompleted)")
            }
            .responseData { response in
                
                if(response.result.isSuccess){
                    print("下载完毕!")
                    isSu = true
                }
        }
        if(isSu){
            return FileTools.fileIsExists(path: FileTools.printer3dPath + "/" + outFileName)
        }
        
        return isSu
        
        // Alamofire 4
        //        Alamofire.request(urlString).response { response in // method defaults to `.get`
        //            debugPrint(response)
        //        }
        //
        //        let parameters: Parameters = ["foo": "bar"]
        //
        //        Alamofire.request(urlString, method: .get, parameters: parameters, encoding: JSONEncoding.default)
        //            .downloadProgress(queue: DispatchQueue.global(qos: .utility)) { progress in
        //                print("Progress: \(progress.fractionCompleted)")
        //            }
        //            .validate { request, response, data in
        //                // Custom evaluation closure now includes data (allows you to parse data to dig out error messages if necessary)
        //                return .success
        //            }
        //            .responseJSON { response in
        //                debugPrint(response)
        //        }
        //
        //        // Alamofire 4
        //        let destination = DownloadRequest.suggestedDownloadDestination()
        //
        
        
    }
    
    
    static func getUrl(urlString: String)-> String{
        var rs: String  = "";
        Alamofire.request(urlString).validate().responseData{(DDataRequest) in
            if DDataRequest.result.isSuccess {
                rs = String.init(data: DDataRequest.data!, encoding: String.Encoding.utf8)!
                print("getUrl---------------" + rs)
            }
            if DDataRequest.result.isFailure {
                print("getUrl失败！！！")
            }
        }
        return rs
    }
    
    
}
