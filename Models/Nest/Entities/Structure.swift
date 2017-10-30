//
//  Structure.swift
//  NestCameras
//
//  Created by Siarhei Yakushevich on 10/29/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

import Foundation



class NameIdSupportableBase: NSObject  {
    let id: NameIdSupportable.IdType
    let name: String
    
    class var idPrefix: String {
        return ""
    }
    
    required init(json: JSONDicType) {
        
        var item = type(of: self).idPrefix
        if item.isEmpty == false {
            item += "_"
        }
        item += "id"
        
        self.id = json[item] as? String ?? ""
        self.name = json["name"] as? String ?? ""
        super.init()
    }
}

extension NameIdSupportableBase: NameIdSupportable, JSONSupportable {}



class Where: NameIdSupportableBase {
    override class var idPrefix: String {
        return "where"
    }
}


class Structure: NameIdSupportableBase {
    let away: String
    let countryCode: String
    let postalCode: String
    let timeZone: String
    let wheres: [NameIdSupportableBase]
    let cameraIds: [String]
    
    override class var idPrefix: String {
        return "structure"
    }
    
    required init(json: JSONDicType) {
        
        var wheresArray = [Where]()
        
        if let wheres = json["wheres"] as? JSONDicType {
            for whereId in wheres.keys {
                if let whereDic = wheres[whereId] as? JSONDicType {
                    let whereItem = Where(json: whereDic)
                    assert(whereItem.id == whereId)
                    wheresArray.append(whereItem)
                }
            }
        }
        self.wheres = wheresArray
        
        self.away = json["away"] as? String ?? ""
        self.countryCode = json["country_code"] as? String ?? ""
        self.timeZone = json["time_zone"] as? String ?? ""
        self.postalCode = json["postal_code"] as? String ?? ""
        self.cameraIds = json["cameras"] as? [String] ?? [String]()
        
        
        super.init(json: json)
    }
}
