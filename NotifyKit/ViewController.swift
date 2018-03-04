//
//  ViewController.swift
//  NotifyKit
//
//  Created by Hanyu Koji on 2018/03/02.
//  Copyright © 2018年 gaussbeam. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBAction func showButtonTapped(_ sender: UIButton) {
        self.notify(title: "Hello")
    }
}

