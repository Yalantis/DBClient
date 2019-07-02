//
//  MasterViewController.swift
//  DBClient-Example
//
//  Created by Serhii Butenko on 11/1/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import UIKit
import DBClient

final class MasterViewController: UITableViewController, DBClientInjectable {
    
    fileprivate var objects = [User]()
    
    private var userChangesObservable: RequestObservable<User>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let observable = dbClient.observable(for: FetchRequest<User>(sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]))
        userChangesObservable = observable
        observable.observe { [weak self] changeSet in
            self?.observeChanges(changeSet)
        }
        
        navigationItem.leftBarButtonItem = editButtonItem
    }
    
    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showDetail",
            let controller = segue.destination as? DetailViewController else {
                fatalError()
        }
        
        if let indexPath = tableView.indexPathForSelectedRow {
            let object = objects[indexPath.row]
            controller.detailItem = object
        }
    }
    
    // MARK: - Actions
    
    @IBAction private func addObject(_ sender: Any) {
        dbClient.insert(User.createRandom()) { _ in }
    }
    
    private func observeChanges(_ changeSet: ObservableChange<User>) {
        switch changeSet {
        case .initial(let initial):
            objects.append(contentsOf: initial)
            tableView.reloadData()
            
        case .change(let change):
            self.objects = change.objects
            tableView.beginUpdates()
            
            let insertedIndexPaths = change.insertions.map { IndexPath(row: $0.index, section: 0) }
            tableView.insertRows(at: insertedIndexPaths, with: .automatic)
            
            let deletedIndexPaths = change.deletions.map { IndexPath(row: $0, section: 0) }
            tableView.deleteRows(at: deletedIndexPaths, with: .automatic)
            
            let updatedIndexPaths = change.modifications.map { IndexPath(row: $0.index, section: 0) }
            tableView.reloadRows(at: updatedIndexPaths, with: .automatic)
            
            tableView.endUpdates()
            
        case .error(let error):
            print("Got an error: \(error)")
        }
    }
}

// MARK: - Table View

extension MasterViewController {
    
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
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {
            return
        }
        
        let user = objects[indexPath.row]
        dbClient.delete(user) { _ in }
    }
}
