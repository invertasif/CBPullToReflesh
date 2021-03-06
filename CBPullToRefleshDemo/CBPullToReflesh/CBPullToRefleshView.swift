//
//  CBPullToRefleshView.swift
//  CBPullToRefleshDemo
//
//  Created by 陈超邦 on 2016/8/7.
//  Copyright © 2016年 陈超邦. All rights reserved.
//

import UIKit

class CBPullToRefleshView: UIView {
    
    var pullDist: CGFloat?
    var bendDist: CGFloat?
    var stopDist: CGFloat?
    var upDuration: CFTimeInterval?
    
    var headerView: CBHearderView!
    var scrollView: UIScrollView?
    
    var scrollViewContentOffSetY: CGFloat?
    var finalScrollViewContentOffSetY: CGFloat?
    
    internal var didPullToRefresh: (()->())?
    
    init(scrollView: UIScrollView,ballSize: CGFloat = 15,ballSpaceBetween: CGFloat = 10,pullDistance: CGFloat = 80,moveUpDuration: CFTimeInterval = 0.5,bendDistance: CGFloat = 50,stopDistance: CGFloat = 70,backgroundColor: UIColor = UIColor.clear(), didPullToRefresh: (()->())? = nil){
        
        if scrollView.frame == CGRect.zero {
            assert(false, "ScrollView got the wrong frame")
        }
        super.init(frame: scrollView.frame)
        self.pullDist = pullDistance
        self.bendDist = bendDistance * 2
        self.stopDist = stopDistance
        self.upDuration = moveUpDuration
        self.didPullToRefresh = didPullToRefresh
        
        headerView = CBHearderView.init(frame: CGRect(x: 0, y: 0, width: scrollView.frame.size.width, height: 0),ballSize: ballSize,moveUpDuration: upDuration!,moveUpDist: stopDist! / 2,ballSpaceBetween: ballSpaceBetween,backColor: backgroundColor,color: UIColor.groupTableViewBackground())
        (scrollView as! UITableView).tableHeaderView = headerView
        
        self.scrollView = scrollView
        scrollView.backgroundColor = UIColor.init(red: 192/255, green: 194/255, blue: 196/255, alpha: 1)
        self.addSubview(scrollView)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.addObserver(self, forKeyPath: contentOffsetKeyPath, options: .initial, context: &KVOContext)
        
    }
    
    deinit {
        scrollView?.removeObserver(self, forKeyPath: contentOffsetKeyPath, context: &KVOContext)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func scrollViewDidScroll() {
        if scrollView?.contentOffset.y < 0 {
            let y = scrollView!.contentOffset.y * -1
            if y < pullDist {
                headerView.frame.height = y
                let bendDistance: CGFloat = bendDist! / 4 + (bendDist! - bendDist! / 4) * y / pullDist!
                headerView.wave(bendDistance)
            }
            else if y > pullDist! {
                scrollView?.isScrollEnabled = false
                headerView.frame.height = y
                scrollViewContentOffSetY = -pullDist!
                finalScrollViewContentOffSetY = -stopDist!
                scrollView?.setContentOffset(CGPoint(x: 0, y: scrollViewContentOffSetY!), animated: false)
                startScrollBackAnimation(scrollDurationInSeconds: CGFloat(upDuration!) / 1.75, distance: pullDist! - stopDist!)
                headerView.wave(bendDist!)
                headerView.didRelease(bendDist!)
                self.didPullToRefresh?()
            }
        }
    }
    
    internal func endReflesh() {
        headerView.endingAnimation {
            self.scrollView?.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
            self.scrollView?.isScrollEnabled = true
            _ = Timer.schedule(delay: 0.5, handler: { (timer) -> Void in
                self.headerView.waveView.endAnimation()
            })
        }
    }
    
    private func startScrollBackAnimation(scrollDurationInSeconds: CGFloat, distance: CGFloat) {
        let stepNum: CGFloat = distance / (scrollDurationInSeconds * 100)
        _ = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(CBPullToRefleshView.scollBackAnimation(_:)), userInfo:stepNum, repeats: true)
    }
    
    func scollBackAnimation(_ timer: Timer) {
        let stepNum = timer.userInfo! as! CGFloat
        scrollViewContentOffSetY = scrollViewContentOffSetY! + stepNum
        if scrollViewContentOffSetY >= finalScrollViewContentOffSetY {
            timer.invalidate()
        }
        scrollView?.setContentOffset(CGPoint(x: 0, y: scrollViewContentOffSetY!), animated: false)
    }
    
    // MARK: ScrollView KVO
    private var KVOContext = "PullToRefreshKVOContext"
    private let contentOffsetKeyPath = "contentOffset"
    override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<()>?) {
        if (context == &KVOContext && keyPath == contentOffsetKeyPath && object as? UIScrollView == scrollView) {
            scrollViewDidScroll()
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
