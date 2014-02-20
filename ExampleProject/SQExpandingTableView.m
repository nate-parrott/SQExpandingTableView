//
//  SQExpandingTableView.m
//  SQBetaUI
//
//  Created by Nate Parrott on 2/18/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQExpandingTableView.h"
#define MAX_REUSE_QUEUE_SIZE 7

#define RELOAD_Y_INTERVAL 150

@implementation SQExpandingTableView

#pragma mark Setup
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

-(void)setup {
    self.scrollView = [UIScrollView new];
    [self addSubview:self.scrollView];
    self.scrollView.delegate = self;
    self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    
    self.scrollCoefficient = 1;
    
    _cellsAtIndices = [NSMutableDictionary new];
    _reuseQueue = [NSMutableArray new];
}
#pragma mark API
-(void)reloadAnimated:(BOOL)animated {
    _lastFullLayoutUpdateY = MAXFLOAT;
    
    _oldViews = _cellsAtIndices.allValues.mutableCopy;
    [_cellsAtIndices removeAllObjects];
    
    _animateLayoutChanges = animated;
    [self setNeedsLayout];
    [self layoutIfNeeded];
    _animateLayoutChanges = NO;
    
    for (UIView* view in self.oldViews) {
        if (animated) {
            [UIView animateWithDuration:0.3 animations:^{
                view.alpha = 0;
            } completion:^(BOOL finished) {
                view.alpha = 1;
                [view removeFromSuperview];
            }];
        } else {
            [view removeFromSuperview];
        }
    }
    _oldViews = nil;
    
    CGPoint contentOffset = self.scrollView.contentOffset;
    [self scrollViewWillEndDragging:self.scrollView withVelocity:CGPointZero targetContentOffset:&contentOffset];
    self.scrollView.contentOffset = contentOffset;
}
-(NSDictionary*)cellsForIndices {
    return _cellsAtIndices.copy;
}
-(void)scrollToCellAtIndex:(int)index animated:(BOOL)animated {
    CGFloat y = 0;
    if (index>0) {
        y = [self maxScroll] / ([self.delegate numberOfRowsInTableView:self]-1) * index;
    }
    [self.scrollView setContentOffset:CGPointMake(0, y) animated:animated];
    [self.delegate tableView:self willExpandViewAtIndex:index];
}
-(UIView*)dequeueViewForReuse {
    if (_reuseQueue.count) {
        UIView* v = _reuseQueue.lastObject;
        v.hidden = NO;
        [_reuseQueue removeLastObject];
        return v;
    } else {
        return nil;
    }
}
#pragma mark Layout
-(CGFloat)maxScroll {
    return ([self contentHeight] - [self.delegate heightForCellsInTableView:self]) / self.scrollCoefficient;
}
-(CGFloat)contentHeight {
    return [self.delegate heightForCellsInTableView:self]*([self.delegate numberOfRowsInTableView:self]-1) + [self.delegate expandedHeightForCellsInTableView:self];
}
-(void)layoutSubviews {
    [super layoutSubviews];
    if (!CGRectEqualToRect(_scrollView.frame, self.bounds)) {
        _scrollView.frame = self.bounds;
    }
    CGSize contentSize = CGSizeMake(self.bounds.size.width, self.bounds.size.height + [self maxScroll]);
    if (!CGSizeEqualToSize(contentSize, _scrollView.contentSize)) {
        _scrollView.contentSize = contentSize;
    }
    
    BOOL fullLayoutUpdate = fabsf(_lastFullLayoutUpdateY - _scrollView.contentOffset.y) > RELOAD_Y_INTERVAL;
    if (fullLayoutUpdate) {
        _lastFullLayoutUpdateY = _scrollView.contentOffset.y;
        _layoutStartIndex = 0;
        _layoutStartY = 0;
    }
    
    CGFloat scrollProgress = _scrollView.contentOffset.y / [self maxScroll];
    CGFloat yAdjust = scrollProgress * ([self maxScroll] - [self contentHeight] + self.bounds.size.height);
    
    CGFloat expandedRow = scrollProgress*([self.delegate numberOfRowsInTableView:self]-1);
    
    CGFloat cellHeight = [self.delegate heightForCellsInTableView:self];
    CGFloat expandedCellHeight = [self.delegate expandedHeightForCellsInTableView:self];
    
    CGRect visibleRect = CGRectMake(0, _scrollView.contentOffset.y-RELOAD_Y_INTERVAL, self.bounds.size.width, self.bounds.size.height+RELOAD_Y_INTERVAL*2);
    
    // expansion cooling: gradually turn off the expansion effect above certain velocities
    CGFloat expansionCoolingStartVelocity = 900;
    CGFloat expansionCoolingEndVelocity = 1300;
    CGFloat velocity = fabsf(_scrollViewVelocity.y);
    CGFloat kExpansion = 1;
    if (velocity > expansionCoolingEndVelocity) {
        kExpansion = 0;
    } else if (velocity > expansionCoolingStartVelocity) {
        kExpansion = 1-(velocity - expansionCoolingStartVelocity)/(expansionCoolingEndVelocity-expansionCoolingStartVelocity);
    }
    //NSLog(@"%f, %f", velocity, kExpansion);
    
    BOOL lastRowWasVisible = NO;
    
    CGFloat y = _layoutStartY + yAdjust;
    for (int i=_layoutStartIndex; i<[self.delegate numberOfRowsInTableView:self]; i++) {
        CGFloat expansion = MAX(0, 1-MAX(i-expandedRow, expandedRow-i)) * kExpansion;
        CGFloat height = expansion*expandedCellHeight + (1-expansion)*cellHeight;
        
        CGRect frame = CGRectMake(0, y, self.bounds.size.width, height);
        BOOL visible = CGRectIntersectsRect(visibleRect, frame);
        
        if (lastRowWasVisible && !visible && !fullLayoutUpdate) {
            break;
        }
        
        UIView* view = _cellsAtIndices[@(i)];
        if (visible) {
            BOOL isViewNew = NO;
            if (!view) {
                view = [self.delegate tableView:self viewAtIndex:i];
                _cellsAtIndices[@(i)] = view;
                isViewNew = YES;
            }
            if (view.superview==nil) {
                view.frame = frame;
                view.alpha = 0;
                [self.scrollView addSubview:view];
                if (_animateLayoutChanges) {
                    [UIView animateWithDuration:0.3 animations:^{
                        view.alpha = 1;
                    }];
                } else {
                    view.alpha = 1;
                }
            } else {
                if (_animateLayoutChanges) {
                    [UIView animateWithDuration:0.3 animations:^{
                        view.frame = frame;
                    }];
                } else {
                    view.frame = frame;
                }
            }
            if (isViewNew && i==_currentlyExpandedCell) {
                [self willExpandCellAtIndex:i];
            }
        } else {
            if (view) {
                [_cellsAtIndices removeObjectForKey:@(i)];
                if (_animateLayoutChanges) {
                    [UIView animateWithDuration:0.3 animations:^{
                        view.frame = frame;
                    } completion:^(BOOL finished) {
                        [self removeFromSuperview];
                    }];
                } else {
                    if (_reuseQueue.count < MAX_REUSE_QUEUE_SIZE) {
                        view.hidden = YES;
                        if ([view respondsToSelector:@selector(prepareForReuse)]) {
                            [(id<SQExpandingTableViewRowView>)view prepareForReuse];
                        }
                        [_reuseQueue addObject:view];
                    } else {
                        [view removeFromSuperview];
                    }
                }
            }
        }
        lastRowWasVisible = visible;
        y += height;
    }
}
#pragma mark Scrolling / expansion
-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    int index;
    if ([self.delegate numberOfRowsInTableView:self]==0) {
        targetContentOffset->y = 0;
        index = 0;
    } else {
        CGFloat roundTo = [self maxScroll] / ([self.delegate numberOfRowsInTableView:self]-1);
        CGFloat y = roundf(targetContentOffset->y / roundTo)*roundTo;
        targetContentOffset->y = y;
        index = y/roundTo;
    }
    [self willExpandCellAtIndex:index];
}
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    _scrollViewVelocity = CGPointZero;
}
-(void)willExpandCellAtIndex:(int)index {
    self.currentlyExpandedCell = index;
    if (_cellsAtIndices[@(index)]) {
        // if the cell isn't yet loaded, don't notify yet. We'll notify the delegate when it's loaded
        if ([self.delegate respondsToSelector:@selector(tableView:willExpandViewAtIndex:)])
            [self.delegate tableView:self willExpandViewAtIndex:index];
    }
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval dt = now - _lastScrollTime;
    if (dt < 0.2) {
        _scrollViewVelocity = CGPointMake((scrollView.contentOffset.x-_lastContentOffset.x)/dt, (scrollView.contentOffset.y-_lastContentOffset.y)/dt);
    }
    _lastScrollTime = now;
    _lastContentOffset = scrollView.contentOffset;
    
    [self setNeedsLayout];
}
-(void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    if ([self.delegate numberOfRowsInTableView:self]) {
        [self willExpandCellAtIndex:0];
    }
}

@end
