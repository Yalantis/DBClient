//
//  DetailViewController.swift
//  DBClient-Example
//
//  Created by Serhii Butenko on 11/1/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController, DBClientInjectable {

    var detailItem: User!
    
    @IBOutlet private weak var userNameTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        userNameTextField.text = detailItem.name
        title = detailItem.id
    }
    
    @IBAction private func saveButtonAction() {
        detailItem.name = userNameTextField.text ?? ""
        dbClient.update(detailItem) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }
    }
    
}
