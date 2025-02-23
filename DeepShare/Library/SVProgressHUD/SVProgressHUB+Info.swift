//
//  SVProgressHUB+Info.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/22.
//

import SVProgressHUD

extension SVProgressHUD {
    static func displayingSuccessInfo(title: String) async {
        await SVProgressHUD.dismiss()
        guard let image = UIImage(systemName: "checkmark") else {
            fatalError("[\(Self.self)][\(#function)] Cannot find `checkmark` symbol.")
        }
        SVProgressHUD.show(image, status: title)
        await SVProgressHUD.dismiss(withDelay: 1.5)
    }
    static func displayingFailuredInfo(title: String) async {
        await SVProgressHUD.dismiss()
        guard let image = UIImage(systemName: "xmark") else {
            fatalError("[\(Self.self)][\(#function)] Cannot find `xmark` symbol.")
        }
        SVProgressHUD.show(image, status: title)
        await SVProgressHUD.dismiss(withDelay: 1.5)
    }
    
}
