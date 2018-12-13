//
//  AccountRootTableViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 04/12/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class AccountRootTableViewController: UITableViewController {
    
    private var userid: String = ""
    private var accessToken: String = ""
    private var profileName: String = ""
    private var profilePhoto: String?
    
    private var menuAccIcons: [String] = ["User", "Password", "Payment", "Purchase", "Logout"]
    private var menuAccLabel: [String] = ["Update Profile", "Change Password", "Payment", "Purchase History", "Sign Out"]
    
    @IBOutlet weak var profileImage: KxCustomImageView!
    @IBOutlet weak var profileNameLabel: UILabel!
    @IBOutlet weak var headerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
         self.clearsSelectionOnViewWillAppear = false
        
        profileImage.layer.cornerRadius = 50
        profileImage.clipsToBounds = true
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.tableView.rowHeight = 50
        self.tableView.separatorStyle = .none
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
    }

    override func viewDidAppear(_ animated: Bool) {
        accessToken = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Token)!
        userid = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Userid)!
        
        profileName = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Name)!
        if let proPhoto = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.UserPhoto) {
            if proPhoto == APPCONSTANT.NoPhoto {
                //No Action
            } else {
                profilePhoto = proPhoto
                profileImage.loadImageUsingUrlString(urlString: proPhoto)
            }
        }
        profileNameLabel.text = profileName
        
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.menuAccIcons.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MenuAccountCell", for: indexPath) as? MenuAccountTableViewCell else {
            return UITableViewCell()
        }
        
        // Configure the cell...
        cell.menuAccountLabel.text = menuAccLabel[indexPath.row]
        cell.menuAccountIconImage.image = UIImage(named: menuAccIcons[indexPath.row])
        cell.menuAccountArrowImage.image = UIImage(named: "Arrow")
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let menuItem = indexPath.row
        switch menuItem {
        case 0:
            performSegue(withIdentifier: "goToUpdateProfile", sender: self)
        case 1:
            performSegue(withIdentifier: "goToChangePasswd", sender: self)
        case 2:
            performSegue(withIdentifier: "goToPaymentProfile", sender: self)
        case 3:
            performSegue(withIdentifier: "goToPurchaseInfo", sender: self)
        case 4:
            logout(presentingVc: self)
        default:
            break
        }
    }
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
