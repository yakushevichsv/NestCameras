//
//  StructureListViewModel.swift
//  NestCameras
//
//  Created by Siarhei Yakushevich on 10/29/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

import Foundation


//MARK: - StructureListViewModel

class StructureListViewModel {
    let structures: StructureSupportable
    let network: NestNetworkStructureSupportable
    let adapter = StructureListAdapter()
    
    
    var structuresId: UInt = UInt.min {
        didSet {
            if oldValue != UInt.min {
                network.manager.cancelTask(oldValue)
            }
            indicateLoad()
        }
    }
    
    let title = "Available Structures".localizedCapitalized
    
    var networkOpIsRunning: Bool {
        return structuresId != UInt.min
    }
    
    var didStartLoading: (()->Void)? = nil {
        didSet {
            if didStartLoading == nil {
                return
            }
            
           indicateLoad()
        }
    }
    var didFail:((_ error: Error) ->Void)? = nil
    var didGetStructures:((_ structures: [Structure]) -> Void)? = nil {
        didSet {
            if didGetStructures == nil  {
                return
            }
            
            loadLocalStructures()
        }
    }
    
    var launchConsiderCameras: ((_ structute: Structure) -> Void)? = nil
    
    init(network: NestNetworkStructureSupportable, structures: StructureSupportable) {
        self.network = network
        self.structures = structures
        
        loadRemoteStructures()
        
        self.adapter.didSelect = { [unowned self] (structure) in
            self.launchConsiderCameras?(structure)
        }
    }
    
    //MARK: - Local items
    
    func loadLocalStructures() {
        structures.accessStructures { (items, error) in
            guard error == nil else { return }
            self.process(items: items)
        }
    }
    
    //MARK: - Remote items
    
    func loadRemoteStructures() {
        structuresId = self.network.accessStructures { [weak self] (items, errorPtr) in
            guard let sSelf = self else { return }
            sSelf.structuresId = UInt.min
            if let error = errorPtr {
                sSelf.indicate(error: error)
            }
            else {
                sSelf.structures.store(structures: items, completion: { (success, errorPtr) in
                    sSelf.process(items: items)
                })
            }
        }
    }
    
    //MARK: - UI Indication
    
    func process(items: [Structure]) {
        DispatchQueue.main.async {
            self.adapter.items = items
            self.didGetStructures?(items)
        }
    }
    
    func indicateLoad() {
        DispatchQueue.main.async {
            if self.networkOpIsRunning {
                self.didStartLoading?()
            }
        }
    }
    
    func indicate(error: Error) {
        DispatchQueue.main.async {
            self.didFail?(error)
        }
    }
}
