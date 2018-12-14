//
//  SendMailHistoryTableViewCell.h
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/03/06.
//
//

/*
 ** IMPORT
 */
#import <UIKit/UIKit.h>

/*
 ** INTERFACE
 */
@interface SendMailHistoryTableViewCell : UITableViewCell
{
	IBOutlet UILabel* labelMailTitle;
	IBOutlet UILabel* labelMailHistory;
	IBOutlet UILabel* labelMailError;
}

/*
 ** PROPERTY
 */
@property(nonatomic, assign) UILabel* labelMailTitle;
@property(nonatomic, assign) UILabel* labelMailHistory;
@property(nonatomic, assign) UILabel* labelMailError;

@end
