//
//  Camera.swift
//  NestCameras
//
//  Created by Siarhei Yakushevich on 10/29/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

import Foundation


//MARK: - Event

class Event: JSONSupportable {
    let imageURL: URL?
    required init(json: JSONDicType) {
       imageURL = URL(string: (json["image_url"] as? String).valueOrEmpty)
    }
}

//MARK: - Camera

class Camera:  NameIdSupportableBase {
    let nameLong: String
    let snapShotURL: URL?
    let structureId: String
    let isOnline:Bool
    let isStreaming: Bool
    let lastEvent: Event?
    
    override class var idPrefix: String {
        return "device"
    }
    
    required init(json: JSONDicType) {
        nameLong = (json["name_long"] as? String).valueOrEmpty
        snapShotURL = URL(string: (json["snapshot_url"] as? String).valueOrEmpty)
        if let json = json["last_event"] as? JSONDicType {
            lastEvent =  Event(json: json)
        }
        else {
            lastEvent = nil
        }
        structureId = (json["structure_id"] as? String).valueOrEmpty
        isOnline = (json["is_online"] as? Bool) == true
        isStreaming = (json["is_streaming"] as? Bool ) == true
        super.init(json: json)
    }
    
    func accessImageURL() -> URL? {
        var url: URL?
        if isOnline && isStreaming  {
            url = snapShotURL
        }
        else {
            url = lastEvent?.imageURL
        }
        
        
        return url?.appendingPathComponent("/device_id/\(id)")
    }
}
