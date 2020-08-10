//
//  StlGcodeToos.swift
//  Three3D
//
//  Created by admin on 2020/8/5.
//  Copyright © 2020年 Kairong. All rights reserved.
//

import Foundation

class StlDealTools: NSObject {
    /**
     * 原始保存的stl数据
     */
    public static var stlMap: [String: StlGcode] = [:]
    
    /**
     * APP自带gcode的map
     */
    static var localMapStl: [String: StlGcode]  = [:]
    
    /**
     * APP自带gcode集合
     */
    static var localStlList:[StlGcode] = [StlGcode]()
    
    /**
     * 从数据库读取和后续更新的数据
     */
    static var stlDataBaseMap: [String: StlGcode]  = [:]
    
    static var data_list = [[String: String]]()
    
    /**
     保存stl对象到字典中
     */
    static func saveStlInfo(realFilePath :String, stlGcode: StlGcode){
        stlMap[realFilePath] = stlGcode
    }
    
    
    /**
     字典里面判断是否存在的key值
     */
    static func checkIsExistsFile(fileName: String)-> Bool{
        return stlMap.keys.contains(fileName)
    }
    
    static func getNowTheTime() -> String {
        // create a date formatter
        let dateFormatter = DateFormatter()
        // setup formate string for the date formatter
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        // format the current date and time by the date formatter
        let dateStr = dateFormatter.string(from: Date())
        return dateStr
    }
    
    
    /**
     本地文件list列表
     */
    static func getLocalStl() -> [StlGcode]{
        let stlPathPre = HtmlConfig.FILE_BUNDEL_PATH + "models/stl/localModules/"
        if(localStlList.isEmpty){
            localStlList = [StlGcode]()
            let  kitty: StlGcode = StlGcode(id:1, sourceStlName:"",realStlName:stlPathPre + "hello_kitty.stl",sourceZipStlName:"",serverZipGcodeName:"",localGcodeName:stlPathPre + "hello_kitty.gco",createTime:"",
                                            localImg:stlPathPre + "hello_kitty.png",length:"X:74.01",width:"Y:51.22",height:"Z:100.93",size:"18.20M",material:"7318cm",exeTime:1025,exeTimeStr:"",flag:1,localFlag:1)
            localStlList.append(kitty)
            localMapStl[kitty.getShortLocalGcodeName()] = kitty
            
            
            let  chamaeleo_t: StlGcode = StlGcode(id:2, sourceStlName:"chamaeleo_t.stl",realStlName:stlPathPre + "chamaeleo_t.stl",sourceZipStlName:"",serverZipGcodeName:"",localGcodeName:stlPathPre + "chamaeleo_t.gco",createTime:"",
                                                  localImg:stlPathPre + "chamaeleo_t.png",length:"X:92.89",width:"Y:93.08",height:"Z:25.98",size:"5.33M",material:"780cm",exeTime:110,exeTimeStr:"",flag:1,localFlag:1)
            localStlList.append(chamaeleo_t)
            localMapStl[chamaeleo_t.getShortLocalGcodeName()] = chamaeleo_t
            
            
            let  hand_ok: StlGcode = StlGcode(id:3, sourceStlName:"hand_ok.stl",realStlName:stlPathPre + "hand_ok.stl",sourceZipStlName:"",serverZipGcodeName:"",localGcodeName:stlPathPre + "hand_ok.gco",createTime:"",
                                              localImg:stlPathPre + "hand_ok.png",length:"X:42.78",width:"Y:57.72",height:"Z:110.44",size:"16.40M",material:"2168cm",exeTime:304,exeTimeStr:"",flag:1,localFlag:1)
            localStlList.append(hand_ok)
            localMapStl[hand_ok.getShortLocalGcodeName()] = hand_ok
            
            
            let  jet_pack_bunny: StlGcode = StlGcode(id:4, sourceStlName:"jet_pack_bunny.stl",realStlName:stlPathPre + "jet_pack_bunny.stl",sourceZipStlName:"",serverZipGcodeName:"",localGcodeName:stlPathPre + "jet_pack_bunny.gco",createTime:"",
                                                     localImg:stlPathPre + "jet_pack_bunny.png",length:"X:130.43",width:"Y:92.01",height:"Z:131.28",size:"48.20M",material:"2168cm",exeTime:304,exeTimeStr:"",flag:1,localFlag:1)
            localStlList.append(jet_pack_bunny)
            localMapStl[jet_pack_bunny.getShortLocalGcodeName()] = jet_pack_bunny
            
            let  god_of_wealth: StlGcode = StlGcode(id:5, sourceStlName:"god_of_wealth.stl",realStlName:stlPathPre + "god_of_wealth.stl",sourceZipStlName:"",serverZipGcodeName:"",localGcodeName:stlPathPre + "god_of_wealth.gco",createTime:"",
                                                    localImg:stlPathPre + "god_of_wealth.png",length:"X:62.85",width:"Y:57.72",height:"Z:64.23",size:"23.40M",material:"1945cm",exeTime:273,exeTimeStr:"",flag:1,localFlag:1)
            localStlList.append(god_of_wealth)
            localMapStl[god_of_wealth.getShortLocalGcodeName()] = god_of_wealth
        }
        return localStlList;
    }
    
    
}
