//
//  StudentLocationsCollectionViewController.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 5/31/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import UIKit

// StudentLocationsCollectionViewController
// Displays all student locations in a collection view
class StudentLocationsCollectionViewController: OnTheMapBaseViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    var pinImage: UIImage!
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        pinImage = UIImage(named: "Pin")
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }

    // MARK: Overrides from super class
    
    override func updateDisplayFromModel() {
        dispatch_async(dispatch_get_main_queue()) {
            self.collectionView.reloadData()
        }
    }
}

// MARK: - UICollectionViewDelegate

extension StudentLocationsCollectionViewController: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let item = dataManager?.studentLocationAtIndex(indexPath.item),
            urlString = item.mediaUrl {
                self.sendToUrlString(urlString)
        }
    }
    
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if let currentCount = dataManager?.studentLocationCount
            where indexPath.item == currentCount - PreFetchTrigger {
                if preFetchEnabled {
                    fetchNextPage()
                }
        }
    }
}

// MARK: - UICollectionViewDataSource

extension StudentLocationsCollectionViewController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataManager?.studentLocationCount ?? 0
    }
    
    func collectionView(collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
            let studentLocationData = dataManager?.studentLocationAtIndex(indexPath.item)
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.StudentLocationCollectionItem, forIndexPath: indexPath) as! StudentLocationCollectionViewCell
            
            cell.firstNameLabel?.text = studentLocationData?.firstname
            cell.lastNameLabel?.text = studentLocationData?.lastname
            cell.imageView?.image = pinImage
            return cell
    }
}

// MARK: - StudentLocationCollectionViewCell

// StudentLocationCollectionViewCell
// represents cell of a collection view containing a single student location item.
class StudentLocationCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView?
    @IBOutlet weak var firstNameLabel: UILabel?
    @IBOutlet weak var lastNameLabel: UILabel?
 
}
