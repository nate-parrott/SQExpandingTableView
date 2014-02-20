//
//  SQExpandingTableView.h
//  SQBetaUI
//
//  Created by Nate Parrott on 2/18/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SQExpandingTableView;
@protocol SQExpandingTableViewDelegate <NSObject>

-(int)numberOfRowsInTableView:(SQExpandingTableView*)tableView;
-(UIView*)tableView:(SQExpandingTableView*)tableView viewAtIndex:(int)index;
-(CGFloat)heightForCellsInTableView:(SQExpandingTableView*)tableView;
-(CGFloat)expandedHeightForCellsInTableView:(SQExpandingTableView*)tableView;
@optional
-(void)tableView:(SQExpandingTableView*)tableView willExpandViewAtIndex:(int)index;

@end

// this is an optional protocol that views used as rows can implement:
@protocol SQExpandingTableViewRowView <NSObject>
@optional
-(void)prepareForReuse;
@end


@interface SQExpandingTableView : UIView <UIScrollViewDelegate> {
    NSMutableDictionary* _cellsAtIndices;
    BOOL _animateLayoutChanges;
    CGFloat _lastFullLayoutUpdateY;
    NSMutableArray* _reuseQueue;
    
    int _layoutStartIndex;
    CGFloat _layoutStartY;
    
    NSTimeInterval _lastScrollTime;
    CGPoint _lastContentOffset;
    CGPoint _scrollViewVelocity;
}

@property(strong)UIScrollView* scrollView;
@property(weak)id<SQExpandingTableViewDelegate> delegate;
-(void)reloadAnimated:(BOOL)animated;

-(NSDictionary*)cellsForIndices;

// during an animated reload, you can query the oldViews property for views currently onscreen; if you return them from -tableView:viewAtIndex:, they'll animate smoothly to their new position (if applicable)
@property(strong,readonly)NSMutableArray* oldViews;

-(void)scrollToCellAtIndex:(int)index animated:(BOOL)animated;

-(UIView*)dequeueViewForReuse;

@property CGFloat scrollCoefficient;

@property int currentlyExpandedCell;

/*
 scrollCoefficient determines how much a the tableview content should move in response to scrolling.
 at 1 (default), there is a nearly 1-1 mapping between finger dragging and content scrolling
 at 0.5, it takes twice as much scrolling to move the content the same amount
 */

@end
