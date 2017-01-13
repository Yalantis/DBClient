//
//  DetailViewController.swift
//  Example
//
//  Created by Serhii Butenko on 11/1/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    var detailItem: User!
    
    @IBOutlet private weak var detailLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        detailLabel.text = detailItem.name
    }
    
}
