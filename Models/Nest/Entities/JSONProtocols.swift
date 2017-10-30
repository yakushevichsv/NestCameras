//
//  JSONBase.swift
//  NestCameras
//
//  Created by Siarhei Yakushevich on 10/30/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

import Foundation

public typealias JSONDicType = [String: AnyObject]

protocol NameIdSupportable {
    typealias IdType = String
    var id: IdType {get}
    var name: String {get}
}

public protocol JSONSupportable {
    init(json: JSONDicType)
}
