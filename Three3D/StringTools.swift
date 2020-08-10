//
//  StringTools.swift
//  Three3D
//
//  Created by admin on 2020/8/5.
//  Copyright © 2020年 Kairong. All rights reserved.
//

import Foundation

class StringTools : NSObject {
    static func positionOf(str: String , sub:String, backwards:Bool = false)->Int {
        var pos = -1
        if let range = str.range(of:sub, options: backwards ? .backwards : .literal ) {
            if !range.isEmpty {
                pos = str.distance(from:str.startIndex, to:range.lowerBound)
            }
        }
        return pos
    }
    
    
    static func isEmpty(str: String)-> Bool{
        if(str == nil){
            return true
        }
        return str == "" || str == "(null)" || 0 == str.count
    }
    
    static func isNotEmpty(str: String)-> Bool{
        return isEmpty(str: str) ? false : true
    }
    
    
    //数组转json
    static func getJSONStringFromArray(array:NSArray) -> String {
        
        if (!JSONSerialization.isValidJSONObject(array)) {
            print("无法解析出JSONString")
            return ""
        }
        
        let data : NSData! = try? JSONSerialization.data(withJSONObject: array, options: []) as NSData!
        let JSONString = NSString(data:data as Data,encoding: String.Encoding.utf8.rawValue)
        return JSONString! as String
        
    }
    
}

