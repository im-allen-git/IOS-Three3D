//
//  TestTool.swift
//  Three3D
//
//  Created by admin on 2020/8/31.
//  Copyright © 2020年 Kairong. All rights reserved.
//

import Foundation


let sourceFileName = "/Users/admin/Library/Developer/CoreSimulator/Devices/6ED80540-5C99-472F-AF38-B067F6261DE1/data/Containers/Data/Application/71064BBA-8CBF-4CE9-94B7-132398870C71/Documents/printer3d/1598864169_1493.stl";
let destZipName = "/Users/admin/Library/Developer/CoreSimulator/Devices/6ED80540-5C99-472F-AF38-B067F6261DE1/data/Containers/Data/Application/71064BBA-8CBF-4CE9-94B7-132398870C71/Documents/printer3d/1598864169_1493.zip";
let files = [sourceFileName]
SSZipArchive.createZipFile(atPath: destZipName, withFilesAtPaths: files)
