//
//  SQTestViewController.m
//  SQBetaUI
//
//  Created by Nate Parrott on 2/18/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQExampleViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface SQExampleViewController ()

@end

@implementation SQExampleViewController

-(void)loadView {
    [super loadView];
    // this example will alternate between the contents of each word list as its source of row data. It'll animate the transition between them.
    wordLists = @[
@[@"0",@"1",@"2",@"3",@"4",@"5",@"7",@"8",@"9",@"11",@"12",@"13",@"14",@"16",@"17",@"18",@"19",@"20",@"21",@"22",@"23",@"24",@"25",@"26",@"28",@"29",@"30",@"31",@"32",@"33",@"34",@"35",@"36",@"37",@"38",@"39",@"40",@"41",@"42",@"43",@"44",@"45",@"46",@"47",@"48",@"49"],
  @[@"0",@"1",@"2",@"3", @"pi",@"4",@"6",@"7",@"8",@"9",@"11",@"12",@"14",@"15",@"16",@"17",@"19",@"20",@"21",@"22",@"23",@"24",@"25",@"27",@"28",@"29",@"30",@"32",@"33",@"34",@"36",@"37",@"38",@"39",@"40",@"41",@"42",@"43",@"44",@"45",@"46",@"47",@"48",@"49"]
                  ].mutableCopy;
    SQExpandingTableView* tv = [[SQExpandingTableView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    self.view = tv;
    tv.scrollCoefficient = 0.5; // slow down the scrolling
    tv.delegate = self;
}
-(void)viewDidLoad {
    [super viewDidLoad];
    [(SQExpandingTableView*)self.view reloadAnimated:NO];
}
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationController.toolbarHidden = NO;
    self.navigationController.navigationBarHidden = YES;
}
-(NSArray*)toolbarItems {
    return @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)]];
}
-(void)refresh {
    // switch the word list, and animate the transition between them
    NSArray* list = wordLists.firstObject;
    [wordLists removeObjectAtIndex:0];
    [wordLists addObject:list];
    [(SQExpandingTableView*)self.view reloadAnimated:YES];
}
-(int)numberOfRowsInTableView:(SQExpandingTableView *)tableView {
    return [wordLists.firstObject count];
}
-(CGFloat)heightForCellsInTableView:(SQExpandingTableView *)tableView {
    return 40;
}
-(CGFloat)expandedHeightForCellsInTableView:(SQExpandingTableView *)tableView {
    return 130;
}
-(UIView*)tableView:(SQExpandingTableView *)tableView viewAtIndex:(int)index {
    NSString* word = [wordLists.firstObject objectAtIndex:index];
    word = [NSString stringWithFormat:@"Cell %@", word];
    
    UIView* view = nil;
    // first, try to find an old view (from the previous reload) with the same content. the tableView will smoothly animate it to its new position
    for (UIView* existing in tableView.oldViews) {
        UILabel* l = (id)[existing viewWithTag:1];
        if ([[l text] isEqual:word]) {
            view = existing;
            [tableView.oldViews removeObject:existing];
            break;
        }
    }
    
    if (!view) {
        view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 40)];
        UILabel* l = [UILabel new];
        l.tag = 1;
        l.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:24];
        [view addSubview:l];
        l.frame = view.bounds;
        l.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleWidth;
        l.text = word;
        l.textAlignment = NSTextAlignmentCenter;
        view.layer.borderColor = [UIColor blackColor].CGColor;
        view.layer.borderWidth = 1;
        view.clipsToBounds = YES;
        UITapGestureRecognizer* gestureRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
        [view addGestureRecognizer:gestureRec];
    }
    
    return view;
}
-(void)tapped:(UITapGestureRecognizer*)sender {
    SQExpandingTableView* table = (id)self.view;
    UIView* v = sender.view;
    NSDictionary* cellsForIndices = table.cellsForIndices;
    for (NSNumber* index in cellsForIndices) {
        if (cellsForIndices[index]==v) {
            [table scrollToCellAtIndex:index.integerValue animated:YES];
            break;
        }
    }
}
-(void)tableView:(SQExpandingTableView *)tableView willExpandViewAtIndex:(int)index {
    // we're gonna add an extra label to the expanded cell
    // first, find the cell corresponding to this index:
    UIView* expandedCell = tableView.cellsForIndices[@(index)];
    // first, let's find the previously expanded cell and remove the label
    for (UIView* existing in tableView.cellsForIndices.allValues) {
        if (existing != expandedCell) {
            UILabel* label = (id)[existing viewWithTag:2];
            if (label) {
                [UIView animateWithDuration:0.3 animations:^{
                    label.alpha = 0;
                } completion:^(BOOL finished) {
                    [label removeFromSuperview];
                }];
            }
        }
    }
    // now, add the label again, if it doesn't exist yet:
    UILabel* label = (id)[expandedCell viewWithTag:2];
    if (!label) {
        label = [UILabel new];
        label.tag = 2;
        [expandedCell addSubview:label];
        label.text = @"This is an expanded cell with a bit more content. You could, of course, put controls or other views here—but we're going the boring, static-text way for now.";
        label.frame = CGRectMake(10, 40, self.view.bounds.size.width-20, 130-40);
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    label.alpha = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:14];
    [UIView animateWithDuration:0.3 animations:^{
        label.alpha = 1;
    }];
}
-(BOOL)prefersStatusBarHidden {
    return YES;
}
-(BOOL)automaticallyAdjustsScrollViewInsets {
    return NO;
}

@end
