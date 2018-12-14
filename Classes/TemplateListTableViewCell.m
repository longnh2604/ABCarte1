//
//  TemplateListTableViewCell.m
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/03/05.
//
//

/*
 ** IMPORT
 */
#import "TemplateListTableViewCell.h"

@implementation TemplateListTableViewCell

/*
 ** PROPERTY
 */
@synthesize templTitle = _templTitle;
@synthesize templUpdateDate = _templUpdateDate;
@synthesize templPreview = _templPreview;


#pragma mark iOS_Frmaework
/**
 initWithStyle
 */
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if ( self )
	{
        // Initialization code
    }
    return self;
}

/**
 setSelected
 */
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
