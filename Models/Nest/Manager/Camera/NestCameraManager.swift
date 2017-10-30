//
//  NestCameraManager.swift
//  NestCameras
//
//  Created by Siarhei Yakushevich on 10/29/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

import Foundation


//MARK: - NestNetworkCameraSupportable

protocol NestNetworkCameraSupportable {
    func accessCamera(id: NameIdSupportable.IdType, completion: @escaping ((_ camera: Camera?, _ error: Error?) -> Void)) -> UInt
    func accessSnapshot(url: URL, completion: @escaping ((_ camera: Data?, _ error: Error?) -> Void)) -> UInt
    var manager: RESTManager {get }
}


//MARK: - NestNetworkCameraSupportable

class NestNetworkCameraManager {
    let manager: RESTManager
    init(manager restManager: RESTManager) {
        self.manager = restManager
    }
}

//MARK: - NestNetworkCameraSupportable

extension NestNetworkCameraManager: NestNetworkCameraSupportable {
    func accessCamera(id: NameIdSupportable.IdType, completion: @escaping ((Camera?, Error?) -> Void)) -> UInt {
        
        let successBlock :(Bool, [AnyHashable : Any]?)-> Void = { (redirect, jsonPtr) in
            
            var camera: Camera? = nil
            
            if let json = jsonPtr as? JSONDicType {
                if let errorValue = json["error"] as? String {
                    var nestError: NestError! = nil
                    if errorValue == "Not Found" {
                        nestError = NestError.notFound(itemId: json["instance"] as? String, message: json["message"] as? String)
                    }
                    else {
                        nestError = NestError.unknown(json: json)
                    }
                    completion(nil, nestError)
                    return
                }
                camera = Camera.init(json: json)
            }
            
            completion(camera, nil)
            return
        }
        
        let failureBlock: (Error?) -> Void =  { (errorPtr) in
            completion(nil, errorPtr)
        }
        
        return manager.getData("devices/cameras/\(id)", success: successBlock, failure: failureBlock)
        
    }
    
    func accessSnapshot(url: URL, completion: @escaping ((Data?, Error?) -> Void)) -> UInt {
       
        let successBlock :(Bool, [AnyHashable : Any]?)-> Void = { (redirect, jsonPtr) in
            
            
            if let json = jsonPtr as? JSONDicType {
                if let errorValue = json["error"] as? String {
                    var nestError: NestError! = nil
                    if errorValue == "Not Found" {
                        nestError = NestError.notFound(itemId: json["instance"] as? String, message: json["message"] as? String)
                    }
                    else {
                        nestError = NestError.unknown(json: json)
                    }
                    completion(nil, nestError)
                    return
                }
                //TODO: is it base64 string or what?
            }
            
            completion(nil, nil)
            return
        }
        
        let failureBlock: (Error?) -> Void =  { (errorPtr) in
            completion(nil, errorPtr)
        }
        
        
        return manager.getRawData(url , success: successBlock , failure: failureBlock)
    }
}
