//
//  StlGcodeTools.swift
//  Three3D
//
//  Created by admin on 2020/8/5.
//  Copyright © 2020年 Kairong. All rights reserved.
//

import Foundation


class StlGcode : NSObject{
    var id: Int?
    // stl原始文件名称
    var  sourceStlName: String?
    
    // 真实文件名称
    var  realStlName: String?
    
    // stl压缩文件名称
    var  sourceZipStlName: String?
    
    // 服务器返回文件
    var  serverZipGcodeName: String?
    
    // 本地解压文件
    var  localGcodeName: String?
    
    var  createTime: String?
    
    // 本地缩略图
    var  localImg: String?
    
    // stl 长宽高 大小
    var  length: String?
    var  width: String?
    var  height: String?
    var  size: String?
    
    // 材料长度
    var  material: String?
    
    // 执行打印时间
    var  exeTime: CLong?
    
    var  exeTimeStr: String?
    
    // 是否上传打印机 0未上传 1上传
    var  flag: Int?
    
    // 是否本地文件  1本地文件 0创建文件
    var  localFlag: Int?
    
    override init() {
        super.init()
    }
    
    init(id:Int, sourceStlName:String,realStlName:String,sourceZipStlName:String,serverZipGcodeName:String,localGcodeName:String,createTime:String,
         localImg:String,length:String,width:String,height:String,size:String,material:String,exeTime:CLong,exeTimeStr:String,flag:Int,localFlag:Int){
        
        self.id = id
        self.sourceStlName = sourceStlName
        self.realStlName = realStlName
        self.sourceZipStlName = sourceZipStlName
        self.serverZipGcodeName = serverZipGcodeName
        self.localGcodeName = localGcodeName
        self.createTime = createTime
        self.localImg = localImg
        self.length = length
        self.width = width
        self.height = height
        self.size = size
        self.material = material
        self.exeTime = exeTime
        self.exeTimeStr = exeTimeStr
        self.flag = flag
        self.localFlag = localFlag
    }
    
    
    func getShortLocalGcodeName()-> String{
        if(self.localGcodeName == nil){
            return ""
        }
        let suffixNum = StringTools.positionOf(str: self.localGcodeName!, sub: "/", backwards: true)
        return String(self.localGcodeName!.suffix(self.localGcodeName!.count - suffixNum))
    }
}
