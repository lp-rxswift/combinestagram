//
//  UIViewController+rx.swift
//  Combinestagram
//
//  Created by Lucas Pedrazoli on 06/11/20.
//  Copyright © 2020 Underplot ltd. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

extension UIViewController {
func alert(title: String, text: String?) -> Completable {
  return Completable.create { [weak self] completable in
    let alertVC = UIAlertController(title: title, message: text, preferredStyle: .alert)
    alertVC.addAction(UIAlertAction(title: "Close", style: .default, handler: {_ in
      completable(.completed)
    }))
    self?.present(alertVC, animated: true, completion: nil)
    return Disposables.create {
      self?.dismiss(animated: true, completion: nil)
    }
  }
  }
}
