//
//  MenuToolbar.swift
//  kaxet
//
//  Created by LEONARD GURNING on 23/10/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit

class MenuToolbar: UIView {
    
    let cellId = "cellId"
    private var activeItem: Int = 0
    
    let menuImages = ["Home" ,"Search", "Library", "Account"]
    var TapAction : (()->())?
    
    private var parentVC: UIViewController?
    
    lazy var tbCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = self.backgroundColor
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()
    
    func attachCollectionView() {

        tbCollectionView.register(MenuCell.self, forCellWithReuseIdentifier: cellId)
        
        self.addSubview(tbCollectionView)
        self.addConstraintsWithFormat(format: "H:|[v0]|", views: tbCollectionView)
        self.addConstraintsWithFormat(format: "V:|[v0]|", views: tbCollectionView)
        
        let selectedIndexPath = NSIndexPath(item: self.activeItem, section: 0)
        tbCollectionView.selectItem(at: selectedIndexPath as IndexPath, animated: true, scrollPosition: .init(rawValue: 0))
    }
    
    func setActiveItem(index: Int) {
         self.activeItem = index
    }
    
    func setParentVC(vc: UIViewController) {
        self.parentVC = vc
    }
}

extension MenuToolbar: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! MenuCell
        
        if indexPath.item == self.activeItem {
            cell.imageView.image = UIImage(named: "\(menuImages[indexPath.item])-act")
        } else {
            cell.imageView.image = UIImage(named: menuImages[indexPath.item])
        }
        cell.imageName = menuImages[indexPath.item]
        cell.setupViews()
        
        /*cell.addButtonTapAction = {
            self.TapAction?()
        }*/
        //cell.backgroundColor = UIColor.blue
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //print(indexPath.item)
        //infoAlert(title: "Screen: \(indexPath.item)", message: "Screen no \(indexPath.item) displayed", presentingVC: self.parentVC!)
        
        if let topVC = UIApplication.getTopMostViewController() {
            let StartVc = topVC as! StartViewController
            let MainTabBar = StartVc.children[0] as! KaxetTabBarViewController
            MainTabBar.selectedIndex = indexPath.item
            let navController = MainTabBar.viewControllers![indexPath.item] as! BaseNavigationController
            navController.popToRootViewController(animated: true)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: frame.width / 4, height: frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
}

class MenuCell: BaseCell {
    
    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "Home")
        return iv
    }()
    
    let baseView: UIView = {
        let cv = UIView()
        cv.layer.cornerRadius = 20
        cv.backgroundColor = UIColor(hex: 0xFFFFFF, alpha: 1)
        return cv
    }()
    
    var isActif: Bool = false
    var imageName: String = ""
    //var addButtonTapAction : (()->())?
    
    override var isHighlighted: Bool {
        didSet {
            //reOrgImage()
        }
    }
    override var isSelected: Bool {
        didSet {
            reOrgImage()
        }
    }
    
    func setActif(actif: Bool) {
        self.isActif = actif
    }
    
    func reOrgImage() {
        
        imageView.image = isSelected ? UIImage(named: self.imageName+"-act") : UIImage(named: self.imageName)
        baseView.backgroundColor = isSelected ? UIColor(hex: 0x333, alpha: 1) : UIColor(hex: 0xFFFFFF, alpha: 1)
        
    }
    
    override func setupViews() {
        super.setupViews()
        
        addSubview(baseView)
        
        addConstraintsWithFormat(format: "H:[v0(40)]", views: baseView)
        addConstraintsWithFormat(format: "V:[v0(40)]", views: baseView)
        
        baseView.translatesAutoresizingMaskIntoConstraints = false
        addConstraint(NSLayoutConstraint(item: baseView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: baseView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        
        baseView.addSubview(imageView)
        
        addConstraintsWithFormat(format: "H:[v0(20)]", views: imageView)
        addConstraintsWithFormat(format: "V:[v0(20)]", views: imageView)
        
        addConstraint(NSLayoutConstraint(item: imageView, attribute: .centerX, relatedBy: .equal, toItem: baseView, attribute: .centerX, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: imageView, attribute: .centerY, relatedBy: .equal, toItem: baseView, attribute: .centerY, multiplier: 1, constant: 0))
        
    }
}
