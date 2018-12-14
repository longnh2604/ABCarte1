//
//  TemplateListTableViewCell.h
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/03/05.
//
//

/*
 ** IMPORT
 */
#import <UIKit/UIKit.h>

/*
 ** INTERFACE
 */
@interface TemplateListTableViewCell : UITableViewCell
{
	IBOutlet UILabel* _templTitle;
	IBOutlet UILabel* _templUpdateDate;
	IBOutlet UILabel* _templPreview;
}

/*
 ** PROPERTY
 */
@property(nonatomic, assign) UILabel* templTitle;
@property(nonatomic, assign) UILabel* templUpdateDate;
@property(nonatomic, assign) UILabel* templPreview;

@end
