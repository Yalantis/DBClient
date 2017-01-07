//
//  ViewController.swift
//  DBClient-Example
//
//  Created by Roman Kyrylenko on 1/6/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import UIKit
import DBClient
import BoltsSwift

func print(_ str: String) {
    NSLog(str)
}

class ViewController: UIViewController, DBClientInjectable {

    func createUsers() {
        let n = 500
        print("going to create \(n) users")
        var users: [User] = []
        for i in 0..<n {
            users.append(User(id: "\(i)", name: "User#\(i)"))
        }
        coreDataClient
            .save(users)
            .continueWith { task in
                if let savedUsers = task.result {
                    print("saved \(savedUsers.count)/\(users.count) to CoreData")
                } else if let error = task.error {
                    print("reached error while saving to CoreData: \(error)")
                }
        }
        realmClient
            .save(users)
            .continueWith { task in
                if let savedUsers = task.result {
                    print("saved \(savedUsers.count)/\(users.count) to Realm")
                } else if let error = task.error {
                    print("reached error while saving to Realm: \(error)")
                }
        }
    }

    func deleteUsers() {
        print("going to delete users")
        let fetchTasks = fetchUsers()
        fetchTasks.coreData.continueWith { task in
            if let users = task.result {
                print("fetched \(users.count) from CoreData")
                self.coreDataClient
                    .delete(users)
                    .continueWith { task in
                        if let result = task.result {
                            print("removed \(result.count) from CoreData")
                        } else if let error = task.error {
                            print("reached error while deleting from CoreData: \(error)")
                        }
                }
            }
        }

        fetchTasks.realm.continueWith { task in
            if let users = task.result {
                print("fetched \(users.count) from Realm")
                self.coreDataClient
                    .delete(users)
                    .continueWith { task in
                        if let result = task.result {
                            print("removed \(result.count) from Realm")
                        } else if let error = task.error {
                            print("reached error while deleting from Realm: \(error)")
                        }
                }
            }
        }
    }

    func fetchUsers() -> (coreData: Task<[User]>, realm: Task<[User]>) {
        let fetchRequest: FetchRequest<User> = FetchRequest()
        return (coreDataClient.execute(fetchRequest), realmClient.execute(fetchRequest))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        createUsers()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
            self.deleteUsers()
        }
    }

}

