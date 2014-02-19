//
//  SQExpandingTableView.m
//  SQBetaUI
//
//  Created by Nate Parrott on 2/18/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQExpandingTableView.h"

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
}
#pragma mark API
-(void)reloadAnimated:(BOOL)animated {
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
    
    CGFloat scrollProgress = _scrollView.contentOffset.y / [self maxScroll];
    CGFloat yAdjust = scrollProgress * ([self maxScroll] - [self contentHeight] + self.bounds.size.height);
    
    CGFloat expandedRow = scrollProgress*([self.delegate numberOfRowsInTableView:self]-1);
    
    CGFloat cellHeight = [self.delegate heightForCellsInTableView:self];
    CGFloat expandedCellHeight = [self.delegate expandedHeightForCellsInTableView:self];
    
    CGRect visibleRect = CGRectMake(0, _scrollView.contentOffset.y, self.bounds.size.width, self.bounds.size.height);
    
    CGFloat y = yAdjust;
    for (int i=0; i<[self.delegate numberOfRowsInTableView:self]; i++) {
        CGFloat expansion = MAX(0, 1-MAX(i-expandedRow, expandedRow-i));
        CGFloat height = expansion*expandedCellHeight + (1-expansion)*cellHeight;
        
        CGRect frame = CGRectMake(0, y, self.bounds.size.width, height);
        BOOL visible = CGRectIntersectsRect(visibleRect, frame);
        
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
                        [view removeFromSuperview];
                    }];
                } else {
                    [view removeFromSuperview];
                }
            }
        }
        
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
-(void)willExpandCellAtIndex:(int)index {
    self.currentlyExpandedCell = index;
    if (_cellsAtIndices[@(index)]) {
        // if the cell isn't yet loaded, don't notify yet. We'll notify the delegate when it's loaded
        if ([self.delegate respondsToSelector:@selector(tableView:willExpandViewAtIndex:)])
            [self.delegate tableView:self willExpandViewAtIndex:index];
    }
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self setNeedsLayout];
}
-(void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    if ([self.delegate numberOfRowsInTableView:self]) {
        [self willExpandCellAtIndex:0];
    }
}

@end
