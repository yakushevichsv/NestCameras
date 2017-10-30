//
//  NestStructureManager.swift
//  NestCameras
//
//  Created by Siarhei Yakushevich on 10/29/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

import Foundation

protocol NestNetworkStructureSupportable {
    func accessStructures( completion: @escaping ((_ structures: [Structure], _ error: Error?) -> Void)) -> UInt
    var manager: RESTManager {get }
}


class NestStructureManager {
    let manager: RESTManager
    init(manager restManager: RESTManager) {
        self.manager = restManager
    }
}

//MARK: - NestStructureSupportable

extension NestStructureManager: NestNetworkStructureSupportable {
    
    func accessStructures( completion: @escaping ((_ structures: [Structure], _ error: Error?) -> Void)) -> UInt {
        
        let successBlock :(Bool, [AnyHashable : Any]?)-> Void = { (redirect, jsonPtr) in
            
            var structures = [Structure]()
            
            if let json = jsonPtr as? JSONDicType {
                structures = json.values.map({ Structure.init(json: $0 as! JSONDicType) } )
            }
            
            completion(structures, nil)
            return
        }
        
        let failureBlock: (Error?) -> Void =  { (errorPtr) in
            completion([Structure](), errorPtr)
        }
        
        return manager.getData("structures", success: successBlock, failure: failureBlock)
    }
}

