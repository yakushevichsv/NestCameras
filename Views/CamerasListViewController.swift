//
//  CamerasListViewController.swift
//  NestCameras
//
//  Created by Siarhei Yakushevich on 10/29/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

import UIKit

//MARK: - CamerasListViewController

class CamerasListViewController: TableViewControllerBase {
    
    //TODO: place inside view model...
    
    var structure: Structure! = nil {
        didSet {
            defineCameras()
        }
    }
    
    var cameras = [Camera]()
    
    let manager: NestNetworkCameraSupportable = NestNetworkCameraManager(manager: RESTManager.shared())
    
    var activeCameraLoads = [NameIdSupportable.IdType : UInt]()
    var imageLoads = [URL: UInt]()
    var imageCache = NSCache<NSURL, AnyObject>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        defineCameras()
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    deinit {
        for key in self.activeCameraLoads.keys {
            let item = self.activeCameraLoads.removeValue(forKey: key)!
            self.manager.manager.cancelTask(item)
        }
        
    }
    
    func defineCameras()  {
        guard isViewLoaded && structure != nil else {
            return
        }
        
        startActivityIndicatorView()
        
        structure.cameraIds.forEach { (cId) in
           self.activeCameraLoads[cId] = self.manager.accessCamera(id: cId, completion: { [weak self] (cameraPtr, errorPtr) in
                guard let sSelf = self else { return }
                sSelf.process(cameraPtr: cameraPtr, errorPtr: errorPtr)
            })
        }
        
    }
    
    func process(cameraPtr: Camera?, errorPtr: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let sSelf = self else { return }
            
            sSelf.stopActivityIndicatorView()
            
            if let camera = cameraPtr {
                if sSelf.activeCameraLoads.removeValue(forKey: camera.id) != nil {
                    sSelf.cameras.append(camera)
                    let nRows = sSelf.tableView.numberOfRows(inSection: 0)
                    
                    sSelf.tableView.insertRows(at: [IndexPath(row: nRows, section:0)], with: .automatic)
                }
                else { assertionFailure("Did not find item \(camera.id)- \(camera.name)")}
            }
            else if let error = errorPtr {
                //TODO: Process rate limits...
                //TODO: Process no internet...
                //TODO: Process cancellation...
                debugPrint("Error \(String(describing: errorPtr))")
            }
        }
    }
    
}

//MARK: - UITableViewDelegate, UITableViewDataSource

extension CamerasListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cameras.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        guard let url = cameras[indexPath.row].accessImageURL(), imageLoads[url] == nil && imageCache.object(forKey: url as NSURL) == nil else {
            return
        }
        
        processLoad(atIndexPath: indexPath, url: url)
    }
    
    func processLoad(atIndexPath indexPath: IndexPath, url: URL) {
       
        imageLoads[url] = manager.accessSnapshot(url: url) {  [weak self]  (dataPtr, errorPtr) in
            guard let sSelf = self else { return }
            //
            if let error = errorPtr as NSError? {
                if error.code == 404 {
                    sSelf.stopLoading(atIndexPath: indexPath, url: url, image: NSNull())
                }
            }
        }
        
        /*DispatchQueue.global(qos: .background).async { [weak self] in
            guard let sSelf = self else { return }
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                sSelf.stopLoading(atIndexPath: indexPath, url: url, image: image)
            }
        } */
    }
    
    func stopLoading(atIndexPath indexPath: IndexPath, url: URL, image anyPtr: AnyObject) {
        DispatchQueue.main.async { [weak self] in
            guard let sSelf = self else { return }
            sSelf.imageLoads.removeValue(forKey: url)
            sSelf.imageCache.setObject(anyPtr, forKey:url as NSURL)
            if let image = anyPtr as? UIImage {
                
                
                guard sSelf.tableView.indexPathsForVisibleRows?.contains(indexPath) == true else {
                    return
                }
                let camera = sSelf.cameras[indexPath.row]
                if camera.accessImageURL() == url {
                    let cell = sSelf.tableView.cellForRow(at: indexPath)
                    cell?.imageView?.image = image
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let camera = cameras[indexPath.row]
        cell.textLabel?.text = camera.nameLong.isEmpty ? camera.name : camera.nameLong
        var image: UIImage? = nil
        if let url = cameras[indexPath.row].accessImageURL() {
            if let fImage = imageCache.object(forKey: url as NSURL) as? UIImage {
                image = fImage
            }
            else {
                processLoad(atIndexPath: indexPath, url: url)
            }
        }
        cell.imageView?.image = image
        return cell
    }
}
