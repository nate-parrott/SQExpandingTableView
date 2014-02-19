//
//  SQTestViewController.h
//  SQBetaUI
//
//  Created by Nate Parrott on 2/18/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SQExpandingTableView.h"

@interface SQExampleViewController : UIViewController <SQExpandingTableViewDelegate> {
    NSMutableArray* wordLists;
}

@end
