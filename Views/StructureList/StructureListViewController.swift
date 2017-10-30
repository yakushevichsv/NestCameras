//
//  StructureListViewController.swift
//  NestCameras
//
//  Created by Siarhei Yakushevich on 10/29/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

import UIKit

//MARK: - TableViewControllerBase

class TableViewControllerBase: UIViewController {
    
    weak var tableView: UITableView!
    weak var activityIndicatorView: UIActivityIndicatorView!
    
    override func loadView() {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = true
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view = view
        
        createTable()
        createActivityIndicatorView()
    }
    
    private func createTable() {
        let table = UITableView(frame: .zero, style: .plain)
        self.view.addSubview(table)
        self.tableView = table
        
        table.translatesAutoresizingMaskIntoConstraints = false
        table.adjustToSuperview()
        
    }
    
    //MARK: - Activity Indicator View
    
    private func createActivityIndicatorView() {
        let ai = UIActivityIndicatorView(activityIndicatorStyle: .white)
        ai.translatesAutoresizingMaskIntoConstraints = false
        ai.tintColor = UIColor.gray
        ai.hidesWhenStopped = true
        ai.isHidden = true
        view.addSubview(ai)
        activityIndicatorView = ai
        ai.centerToSuperview()
    }
    
    @discardableResult func startActivityIndicatorView() -> Bool {
        guard !activityIndicatorView.isAnimating == false else { return false}
        activityIndicatorView.isHidden = false
        activityIndicatorView.startAnimating()
        return true
    }
    
    @discardableResult func stopActivityIndicatorView() -> Bool {
        guard activityIndicatorView.isAnimating else { return false}
        activityIndicatorView.stopAnimating()
        return true
    }
}

//MARK: - StructureListViewController

class StructureListViewController: TableViewControllerBase {
    
    var model: StructureListViewModel! = nil {
        didSet {
            reset(oldModel: oldValue)
            if isViewLoaded {
                listenToChanges()
                configureTable()
            }
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.separatorStyle = .none
        self.tableView.allowsSelection = true
        
        configureTable()
        listenToChanges()
    }
    
    func configureTable() {
        self.model?.adapter.configure(table: self.tableView)
        self.title = (self.model?.title).valueOrEmpty
    }
    
    func listenToChanges() {
        model?.didStartLoading = { [unowned self] in
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            if self.tableView.numberOfRows(inSection: 0) == 0 {
                self.startActivityIndicatorView()
            }
        }
        
        model?.didFail = { [unowned self] (errorPtr) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.stopActivityIndicatorView()
        }
        
        model.didGetStructures = { [unowned self] (items) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.stopActivityIndicatorView()
            self.tableView.reloadData()
        }
        
        model.launchConsiderCameras = { [unowned self ] (structure) in
            type(of: self).coordinator.moveToCameras(fromVC: self, usingStructure: structure)
        }
    }
    
    func reset(oldModel: StructureListViewModel?) {
        oldModel?.didGetStructures = nil
        oldModel?.didFail = nil
        oldModel?.didStartLoading = nil
        oldModel?.launchConsiderCameras = nil
    }
}


