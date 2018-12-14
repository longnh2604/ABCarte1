//
//  SearchResultTableViewCell.m
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/03/04.
//
//

/*
 ** IMPORT
 */
#import "defines.h"
#import "SearchResultTableViewCell.h"
#import "Common.h"

/*
 ** INTERFACE
 */
@interface SearchResultTableViewCell()
{
}
- (IBAction) OnSelectCell:(id)sender;
@end


@implementation SearchResultTableViewCell

/*
 ** PROPERTY
 */
@synthesize userName;
@synthesize userMailAddress;
@synthesize blockMail;
@synthesize userId = _userId;
@synthesize mailUserInfo = _mailUserInfo;
@synthesize enableSelect = _enableSelect;

#pragma mark iOS_Frmaework
/**
 initWithStyle
 */
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
	{
        // Initialization code
		[selectedCell setHidden:YES];
		[unselectedCell setHidden:NO];
		[self setEnableSelect:YES];
    }
    return self;
}

/**
 dealloc
 */
- (void)dealloc
{
	[selectedCell release];
	[unselectedCell release];
	[super dealloc];
}

/**
 setSelected
 */
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

/**
 UITableViewCellの横幅を調整する
 */
- (void)setFrame:(CGRect)frame
{
	frame.origin.x += self.inset;
	frame.size.width -= 2 * self.inset;
	[super setFrame:frame];
}


#pragma mark SearchResultTableView_Method
/**
 初期化処理
 */
- (void) initialize
{
	// 名前ラベルImageの角を丸くする
//    [Common cornerRadius4Control:titleImageView];
}

-(void) setCallbackDelegate:(id<SearchResultTableViewDelegate>) delegate
{
    self->btnCallbackDelegate = delegate;
}

/**
 setRegistNumberWithIntValue
 */
- (void) setRegistNumberWithIntValue:(NSInteger)registId isNameSet:(BOOL)isSet
{
	// コントロールの表示
	BOOL isDisplay = YES;
	
	// 設定されていない場合は、表示しない
	if (registId == REGIST_NUMBER_INVALID)
		isDisplay = NO;
	
	// ユーザ名が設定されていない場合は、お客様番号がユーザ名となるので表示しない
	if (!isSet)
		isDisplay = NO;
	
	// 表示する
//	userRegistIdTitle.hidden = ! isDisplay;
	
	// 書式指定で設定する
	userMailAddress.text = [NSString stringWithFormat:REGIST_NUMBER_STRING_FORMAT, (long)registId];
}

/**
 選択ボタンの状態を変更する
 */
- (void) setSelectedButton:(BOOL)selected
{
	[self OnSelectCell:selected ? unselectedCell : selectedCell];
}


#pragma mark SearchResultTableViewCell_Handler
/**
 選択状態を変更する
 */
- (IBAction) OnSelectCell:(id)sender
{
	if ( [self enableSelect] == NO )
		return;

	if ( sender == selectedCell )
	{
		// 非選択
		[selectedCell setHidden:YES];
		[unselectedCell setHidden:NO];
		[[self mailUserInfo] setSelected:NO];
	}
	else
	{
		// 選択
		[selectedCell setHidden:NO];
		[unselectedCell setHidden:YES];
		[[self mailUserInfo] setSelected:YES];
	}
    
    [self->btnCallbackDelegate touchSelectedButtonDelegate];
}

@end
