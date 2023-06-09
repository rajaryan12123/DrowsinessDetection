//
//  WelcomeViewController.swift
//  DrowsinessDetection
//
//  Created by Raj Aryan on 22/03/23.
//

import Foundation
import UIKit
import SwiftUI

class WelcomeViewController: UIViewController {
    
    let contentView = UIHostingController(rootView: WelcomeScreen())
    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(contentView)
        view.addSubview(contentView.view)
        setUpConstraints()
    }
    
    fileprivate func setUpConstraints() {
        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        contentView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        contentView.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        contentView.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
    
}
