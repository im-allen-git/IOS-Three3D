//
//  ServerConfig.swift
//  Three3D
//
//  Created by admin on 2020/8/6.
//  Copyright © 2020年 Kairong. All rights reserved.
//

import Foundation
class ServerConfig : NSObject {
    
    static let  SERVER_URL_PRE: String = "https://192.168.1.67"
    
    // 上传stl生成gcode路径
    static let  FILE_UPLOAD_URL: String = SERVER_URL_PRE + "/file/uploadFileAndGenGcodeIos"
    static let  FILE_DOWN_URL: String = SERVER_URL_PRE + "/file/downloadFileIos?fileName="
    
    
    
}
