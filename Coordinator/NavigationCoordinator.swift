//
//  NavigationCoordinator.swift
//  NestCameras
//
//  Created by Siarhei Yakushevich on 10/28/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

import UIKit

//MARK: - NavigationCoordinator

final class NavigationCoordinator {
    let authorization: NestAuthManager
    
    init(authorization: NestAuthManager) {
        self.authorization = authorization
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NestManagerDidDetectToken, object: nil, queue: OperationQueue.main) { (notification) in
            var vc = UIApplication.shared.delegate!.window??.rootViewController
            if let navVC = vc as? UINavigationController {
                vc = navVC.viewControllers.last
            }
            self.moveToStructures(currentVC: vc!, animated: true)
        }
        
        //TODO: subscribe for token experation...
    }
    
    //MARK: - Main Screen
    
    func defineRootViewController() -> UIViewController? {
        let navVC = UINavigationController()
        if self.authorization.isValidSession() {
            moveToStructures(currentVC: navVC, animated: false)
        }
        else {
            let connectVC = NestConnectViewController()
            navVC.viewControllers = [connectVC]
        }
        return navVC
    }
    
    //MARK: - Navigate to Structure List
    
    func moveToStructures(currentVC vc: UIViewController, animated:Bool = true) {
        
        let navVC = vc.findNavigationController()
        
        let structureVC = StructureListViewController()
        structureVC.model = StructureListViewModel(network: NestStructureManager(manager: RESTManager.shared()),  structures: Repository.sharedRepository)
        
        navVC?.pushViewController(structureVC, animated: animated)
    }
    
    func moveToCameras(fromVC vc: UIViewController, usingStructure structure: Structure, animated:Bool = true) {
        let navVC =  vc.findNavigationController()
        
        let camerasVC = CamerasListViewController()
        camerasVC.structure = structure
        //TODO: define model.. camerasVC.
        navVC?.pushViewController(camerasVC, animated: animated)
    }
}
