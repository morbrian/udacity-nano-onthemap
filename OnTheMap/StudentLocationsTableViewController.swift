//
//  MarkerListViewController.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/26/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import UIKit

// StudentLocationsTableViewController
// Displays all student locations in a table view
class StudentLocationsTableViewController: OnTheMapBaseViewController {

    var topRefreshView: RefreshView!
    
    @IBOutlet weak var tableView: UITableView!

    var pinImage: UIImage!
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        pinImage = UIImage(named: "Pin")
        super.viewDidLoad()

        if let navigationBar = navigationController?.navigationBar {
            navigationBar.translucent = false
            topRefreshView = produceRefreshViewWithHeight(navigationBar.bounds.height)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    // figure out the best height for the activity spinner area
    private func produceRefreshViewWithHeight(spinnerAreaHeight: CGFloat) -> RefreshView {
        let refreshViewHeight = view.bounds.height
        let refreshView = RefreshView(frame: CGRect(x: 0, y: -refreshViewHeight, width: CGRectGetWidth(view.bounds), height: refreshViewHeight), spinnerAreaHeight: spinnerAreaHeight, scrollView: tableView)
        refreshView.translatesAutoresizingMaskIntoConstraints = false
        refreshView.delegate = self
        tableView.insertSubview(refreshView, atIndex: 0)
        return refreshView
    }
    
    // MARK: Overrides from super class
    
    override func updateDisplayFromModel() {
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }
}

// MARK: - UITableViewDelegate

extension StudentLocationsTableViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let item = dataManager?.studentLocationAtIndex(indexPath.item),
            urlString = item.mediaUrl {
            self.sendToUrlString(urlString)
        }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let currentCount = dataManager?.studentLocationCount
            where indexPath.item == currentCount - PreFetchTrigger {
                if preFetchEnabled {
                    fetchNextPage()
                }
        }
    }
}

// MARK: - UITableViewDataSource

extension StudentLocationsTableViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataManager?.studentLocationCount ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let studentLocationData = dataManager?.studentLocationAtIndex(indexPath.item)
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.StudentLocationCell, forIndexPath: indexPath) 
 
        cell.textLabel?.text = studentLocationData?.fullname
        cell.imageView?.image = pinImage
        return cell
    }
}

// MARK: - UIScrollViewDelegate

extension StudentLocationsTableViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        topRefreshView.scrollViewDidScroll(scrollView)
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        topRefreshView.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
}

// MARK: - RefreshViewDelegate

extension StudentLocationsTableViewController: RefreshViewDelegate {
    func refreshViewDidRefresh(refreshView: RefreshView) {
        fetchNextPage(completionHandler: refreshView.endRefreshing)
    }
}



