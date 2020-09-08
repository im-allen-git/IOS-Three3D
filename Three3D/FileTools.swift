//
//  File.swift
//  Three3D
//
//  Created by admin on 2020/8/5.
//  Copyright © 2020年 Kairong. All rights reserved.
//

import Foundation
import MobileCoreServices

class FileTools: NSObject {
    static let fileManager = FileManager.default
    
    //Documents目录
    static let ducumentPath = NSHomeDirectory() + "/Documents"
    //Library目录
    static let libraryPath = NSHomeDirectory() + "/Library"
    //Cache目录
    static let cachePath = NSHomeDirectory() + "/Library/Caches"
    
    // 用于存放临时文件，保存应用程序再次启动过程中不需要的信息，重启后清空
    static let tmpDir = NSTemporaryDirectory()
    static let tmpDir2 = NSHomeDirectory() + "/tmp"
    // 3d文件存放位置
    static let printer3dPath = ducumentPath + "/printer3d"
    
    static let plistName = printer3dPath + "/printer3d.plist"
    // plist的字典
    static var plistData: NSMutableDictionary = [:]
    
    
    /**
     进行文件保存
     */
    
    static func saveFile(fileName: String, receivedString: String)-> Bool{
        
        if(StringTools.isEmpty(str: receivedString)){
            return false
        }
        
        let _isParentPath = createDir(dirPath: printer3dPath)
        // let filePath = printer3dPath + "/" + fileName
        
        // 如果是创建的目录，则不需要判断文件是否存在
        if(_isParentPath){
            let _exist = fileManager.fileExists(atPath: fileName);//将 文件地址存到 变量 exist中
            if _exist{
                try! fileManager.removeItem(atPath: fileName)
            }
        }
        
        let f_exist = fileManager.createFile(atPath: fileName, contents: nil, attributes:nil)
        print(fileName + "文件创建结果: \(f_exist)")
        if(f_exist){
            let handle = FileHandle(forWritingAtPath: fileName)
            handle?.write(receivedString.data(using: String.Encoding.utf8)!)
        }
        
        
//        f_exist = fileManager.fileExists(atPath: fileName);
//        let data2 = fileManager.contents(atPath: fileName)
//        let readString2 = String(data: data2!, encoding: String.Encoding.utf8)
//        print("文件内容: \(String(describing: readString2))")
        
        
        return f_exist
    }
    
    // 创建文件目录
    static func createDir(dirPath: String)-> Bool{
        var _isParentPath =  directoryIsExists(path: dirPath)
        if(!_isParentPath){
            try! fileManager.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
            _isParentPath = true
        }
        return _isParentPath
    }
    
    
    /**
     文件删除
     */
    static func deleteFile(fileName: String){
        let _exist = fileManager.fileExists(atPath: fileName);//将 文件地址存到 变量 exist中
        if(_exist){
            try! fileManager.removeItem(atPath: fileName);
        }
        
    }
    
    /**
     解压文件
     */
    static func unzipFile(zipPath: String, destPath: String){
        SSZipArchive.unzipFile(atPath: zipPath, toDestination: destPath)
    }
    
    
    /**
     压缩文件
     */
    static func zipFile(sourceFileName: String,destZipName: String)-> Bool{
        
        print("zipFile:")
        
        print(sourceFileName)
        print(destZipName)
        
//        let prePath = sourceFileName.prefix(StringTools.positionOf(str: sourceFileName, sub: "."))
//        print(prePath)
//        let jsonPath = Bundle.main.path(forResource: String(prePath), ofType: "stl")
        
        let files = [sourceFileName]
        SSZipArchive.createZipFile(atPath: destZipName, withFilesAtPaths : files)
        
        
//        do{
            // 先拷贝到临时目录中
//            let tempDir = tempDestPath()
//            // 倒序获取定位数据
//            let suffixNum = StringTools.positionOf(str:sourceFileName,sub:"/", backwards:true)
//            // 尾部截取
//            let endSuffix: String = String(sourceFileName.suffix(sourceFileName.count - suffixNum))
//            let tempAllPath =  tempDir! + "/" + endSuffix
//            try fileManager.copyItem(at: NSURL(fileURLWithPath: sourceFileName) as URL, to: NSURL(fileURLWithPath:tempAllPath) as URL)
//            // 进行ZIP压缩
//            SSZipArchive.createZipFile(atPath: destZipName, withContentsOfDirectory: tempDir!)
//            // print(tempDir!)
//            // 删除临时文件
//            try fileManager.removeItem(at: NSURL(fileURLWithPath: tempDir!) as URL)
//        }catch{
//            print(error)
//        }
        return fileManager.fileExists(atPath: destZipName)
    }
    
    
    //在Caches文件夹下随机创建一个文件夹，并返回路径
    static func tempDestPath() -> String? {
        var path = NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                       .userDomainMask, true)[0]
        path += "/\(NSUUID().uuidString)"
        let url = NSURL(fileURLWithPath: path)
        
        do {
            try fileManager.createDirectory(at: url as URL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return nil
        }
        
        if let path = url.path {
            print("path:\(path)")
            return path
        }
        return nil
    }
    
    
    /**
     判断是否是文件夹的方法
     */
    static func directoryIsExists(path: String) -> Bool {
        var directoryExists = ObjCBool.init(false)
        let fileExists = fileManager.fileExists(atPath: path, isDirectory: &directoryExists)
        return fileExists && directoryExists.boolValue
    }
    
    static func fileIsExists(path: String) -> Bool {
        return fileManager.fileExists(atPath: path)
    }
    
    /**
     获取文件全路径
     */
    static func getFileAllPath(fileName: String)-> String{
        return printer3dPath + "/" + fileName;
    }
    
    
    static func getRandomFilePath()-> String{
        // 随机数
        let randomNum = Int.random(in: 1000...9999)
        // 时间戳
        let date = Date(timeIntervalSinceNow: 0)
        let a = date.timeIntervalSince1970
        let timeStamp = String.init(format: "%.f", a)
        
        return timeStamp + "_" +  String(randomNum);
    }
    
    
    //根据后缀获取对应的Mime-Type
    static func mimeType(pathExtension: String) -> String {
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                           pathExtension as NSString,
                                                           nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?
                .takeRetainedValue() {
                return mimetype as String
            }
        }
        //文件资源类型如果不知道，传万能类型application/octet-stream，服务器会自动解析文件类
        return "application/octet-stream"
    }
    
    
    /**
     创建 printer3d的plist，用于存储使用信息，如打印机Wi-Fi，启动页加载等
     */
    static func saveToPlist(keyName: String, val : String)-> Bool{
        if(!fileIsExists(path: plistName)){
            let _isParentPath = createDir(dirPath: printer3dPath)
            if(!_isParentPath){
                return false
            }
            let f_create = fileManager.createFile(atPath: plistName, contents: nil, attributes:nil)
            if(!f_create){
                return false
            }
        }
        //读取属性列表文件，并转化为可变字典对象
        plistData = NSMutableDictionary(contentsOfFile: plistName)!
        //plistData是根据路径，得到的文件对象。 "key"为文件对象中的键，“value”为你想为此key设置的值
        plistData.setObject(val, forKey: keyName as NSCopying)
        return plistData.write(toFile: plistName, atomically: true)
    }
    
    /**
     获取plist里面的数据
     */
    static func getByPlist(keyName: String)-> String{
        if(fileIsExists(path: plistName)){
            plistData = NSMutableDictionary.init(contentsOfFile: plistName)!  //获取文件的路径，获取文件的类型，我的例子是字典型（有字典型和数组型可选）
            return plistData[keyName]! as! String   //利用键-值对的方式，进行存取
        }
        return ""
    }
    
    

    
}
