//
//  LibraryRootTableViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 21/11/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit

class LibraryRootTableViewController: UITableViewController {

    private var menuLibIcons: [String] = ["artist", "album", "song", "playlist", "mysong"]
    private var menuLibLabel: [String] = ["Artist", "Album", "Song", "Playlist", "My Songs"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.tableView.rowHeight = 60
        self.tableView.separatorStyle = .none
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.menuLibIcons.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MenuLibCell", for: indexPath) as? MenuLibTableViewCell else {
            return UITableViewCell()
        }

        // Configure the cell...
        cell.MenuLibLabel.text = menuLibLabel[indexPath.row]
        cell.MenuLibIconImage.image = UIImage(named: menuLibIcons[indexPath.row])
        cell.MenuLibForwardImage.image = UIImage(named: "Arrow")
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let menuItem = indexPath.row
        switch menuItem {
        case 0:
            performSegue(withIdentifier: "goToArtist", sender: self)
        case 1:
            performSegue(withIdentifier: "goToAlbum", sender: self)
        case 2:
            performSegue(withIdentifier: "goToSong", sender: self)
        case 3:
            performSegue(withIdentifier: "goToPlaylist", sender: self)
        case 4:
            performSegue(withIdentifier: "goToMySong", sender: self)
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
        
        switch segue.identifier {
        case "goToArtist":
            // Create a new variable to store the instance of ArtistViewController
            let destinationVC = segue.destination as! ArtistViewController
            //destinationVC.initData(data: songDataForSegue)
            
        default:
            break
        }
    }
    */

}
