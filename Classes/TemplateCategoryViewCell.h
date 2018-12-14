//
//  TemplateCategoryViewCell.h
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
@interface TemplateCategoryViewCell : UITableViewCell
{
	IBOutlet UILabel* labelCategoryTitle;
}

/*
 ** PROPERTY
 */
@property(nonatomic, weak) UILabel* labelCategoryTitle;

@end
