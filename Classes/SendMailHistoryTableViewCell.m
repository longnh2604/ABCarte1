//
//  SendMailHistoryTableViewCell.m
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/03/06.
//
//

/*
 ** IMPORT
 */
#import "SendMailHistoryTableViewCell.h"

@implementation SendMailHistoryTableViewCell

/*
 ** PROPERTY
 */
@synthesize labelMailTitle;
@synthesize labelMailHistory;
@synthesize labelMailError;

/**
 initWithStyle
 */
- (id) initWithStyle:(UITableViewCellStyle) style reuseIdentifier:(NSString *) reuseIdentifier
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
- (void) setSelected:(BOOL) selected animated:(BOOL) animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
