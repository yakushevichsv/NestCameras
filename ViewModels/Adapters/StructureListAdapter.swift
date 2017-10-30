//
//  File.swift
//  NestCameras
//
//  Created by Siarhei Yakushevich on 10/30/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

import Foundation
//MARK: - Adapter
class StructureListAdapter: NSObject {
    weak var tableView: UITableView!
    
    var items = [Structure]() {
        didSet {
            if self.tableView?.window != nil {
                self.tableView?.reloadData()
            }
        }
    }
    
    var didSelect: ((_ item: Structure ) -> Void)? = nil
    
    func configure(table: UITableView) {
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
}

//MARK: - UITableViewDataSource , UITableViewDelegate
extension StructureListAdapter : UITableViewDataSource , UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let structure = items[indexPath.row]
        cell.selectionStyle = .none
        cell.textLabel?.text = structure.name
        cell.accessoryType = structure.cameraIds.count > 0 ? .disclosureIndicator : .none
        //cell.detailTextLabel?.text = ""
        //cell.detailTextLabel?.textColor = UIColor.gray
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let structure = items[indexPath.row]
        
        didSelect?(structure)
    }
}
