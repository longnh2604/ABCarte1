//
//  TextLogTableViewController.h
//  iPadCamera
//
//  Created by GIGASJAPAN on 13/06/17.
//
//

#import <UIKit/UIKit.h>

@interface TextLogTableViewController : UITableViewController
{
    NSArray *logArray;
    NSInteger callTaskTag;
}

- (id)initWithStyle:(UITableViewStyle)style cellItemsArray:(NSArray*)itemArray TaskTag:(NSInteger)taskTag;
@end
