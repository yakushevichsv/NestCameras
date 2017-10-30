//
//  RepositorySupportable.swift
//  NestCameras
//
//  Created by Siarhei Yakushevich on 10/29/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

import Foundation


//MARK: - RepositorySupportable

protocol StructureSupportable {
    func accessStructures(completion: @escaping (( _ structures: [Structure], _ error: Error?) -> Void))
    func store(structures: [Structure], completion: @escaping ((_ success:Bool, _ error: Error?)->Void))
}

protocol RepositorySupportable: StructureSupportable {}

//MARK: - Repository

final class Repository {
    
    let queue: OperationQueue!
    
    static let sharedRepository = Repository()
    
    
    fileprivate var structures = [Structure]() //Could be core data or realm...
    
    init() {
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 10
        queue.name = "com.test.repository.queue"
    }
}

//MARK: - StructureSupportable

extension Repository: StructureSupportable {
    
    func accessStructures(completion: @escaping (([Structure], Error?) -> Void)) {
        queue.addOperation {
            completion(self.structures, nil)
        }
    }
    
    func store(structures: [Structure], completion: @escaping ((Bool, Error?) -> Void)) {
        queue.addOperation {
            objc_sync_enter(self)
            self.structures = structures
            objc_sync_exit(self)
            completion(true, nil)
        }
    }
}

//MARK: - RepositorySupportable

extension Repository: RepositorySupportable {}
