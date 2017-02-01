//
//  MasterViewController.swift
//  Example
//
//  Created by Serhii Butenko on 11/1/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import UIKit
import DBClient

class MasterViewController: UITableViewController, DBClientInjectable {
    
    fileprivate var objects = [User]()
  
    var observable: RequestObservable<User>!
  
    override func viewDidLoad() {
        super.viewDidLoad()
      
        observable = dbClient.observable(for: FetchRequest<User>())
        
        observable.observe { changeSet in
            switch changeSet {
            case .initial(let initial):
                self.objects.append(contentsOf: initial)
                self.tableView.reloadData()
                
            case .change(objects: let objects, deletions: let deletions, insertions: let insertions, modifications: let modifications):
                self.objects = objects
                self.tableView.beginUpdates()

                let insertedIndexPaths = insertions.map { IndexPath(row: $0.index, section: 0) }
                self.tableView.insertRows(at: insertedIndexPaths, with: .automatic)
                
                let deletedIndexPaths = deletions.map { IndexPath(row: $0, section: 0) }
                self.tableView.deleteRows(at: deletedIndexPaths, with: .automatic)
                
                let updatedIndexPaths = modifications.map { IndexPath(row: $0.index, section: 0) }
                self.tableView.reloadRows(at: updatedIndexPaths, with: .automatic)
                
                self.tableView.endUpdates()
                
            case .error(let error):
                print("Got an error: \(error)")
            }
        }
        
        navigationItem.leftBarButtonItem = editButtonItem
    }
    
    @IBAction func addObject(_ sender: Any) {
        dbClient.save(User.createRandom())
    }
    
    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showDetail", let controller = segue.destination as? DetailViewController else {
            fatalError()
        }
        
        if let indexPath = tableView.indexPathForSelectedRow {
            let object = objects[indexPath.row]
            controller.detailItem = object
        }
    }
    
    // MARK: - Table View
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let object = objects[indexPath.row]
        cell.textLabel!.text = object.name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        let user = objects[indexPath.row]
        dbClient.delete(user)
    }
    
}
