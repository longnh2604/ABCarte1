//
//  PhotoCommentPopup.m
//  iPadCamera
//
//  Created by 聡史 伊藤 on 12/06/29.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PhotoCommentPopup.h"
#import "Common.h"
#import "userDbManager.h"
#import "OKDImageFileManager.h"
#import "MovieResource.h"

@implementation PhotoCommentPopup

@synthesize pictureURL;
@synthesize selectUserID;
@synthesize selectHistID;


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    // titleの角を丸める
	[Common cornerRadius4Control:lblTitle];

    textTitle.text = @"";
    textMemo.text = @"";
	userDbManager *dbMng = [[userDbManager alloc] init];

    [btnOk setBackgroundColor:[UIColor whiteColor]];
    [[btnOk layer] setCornerRadius:6.0];
    [btnOk setClipsToBounds:YES];
    [[btnOk layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[btnOk layer] setBorderWidth:1.0];

    [btnCancel setBackgroundColor:[UIColor whiteColor]];
    [[btnCancel layer] setCornerRadius:6.0];
    [btnCancel setClipsToBounds:YES];
    [[btnCancel layer] setBorderColor:[[UIColor colorWithRed:0.863 green:0.078 blue:0.235 alpha:1.0] CGColor]];
    [[btnCancel layer] setBorderWidth:1.0];

    OKDImageFileManager *imgFileMng
    = [[OKDImageFileManager alloc]initWithUserID:self.selectUserID];
    if ([pictureURL hasSuffix:@"tmb"]){
        // 動画の内容の編集
        MovieResource *movieResource = [[MovieResource alloc] initWithUserId:self.selectUserID fileName:pictureURL];
        selectImage.image = [imgFileMng getThumbnailSizeImage:[movieResource.thumbnailPath lastPathComponent]];
        NSArray *defaultText = [[NSArray alloc] initWithArray:[dbMng getVideoProfile:movieResource.path]];
        textTitle.text = [defaultText objectAtIndex:0];
        
        NSString *checkStr = [defaultText objectAtIndex:1];
        if ([checkStr containsString:@"_________retun___"]) {
            checkStr = [checkStr stringByReplacingOccurrencesOfString:@"_________retun___"
                                                   withString:@"\n"];
        }
        textMemo.text = checkStr;
        
//        textMemo.text = [defaultText objectAtIndex:1];
        // タイトル入力欄にフォーカスする
        [textTitle becomeFirstResponder];
        [defaultText release];
    } else {
        selectImage.image = [imgFileMng getRealSizeImage:pictureURL];
        NSArray *defaultText = [[NSArray alloc] initWithArray:[dbMng getImageProfile:[imgFileMng getDocumentFolderFilename:pictureURL]]];
        textTitle.text = [defaultText objectAtIndex:0];
        textMemo.text = [defaultText objectAtIndex:1];
#ifdef CALULU_IPHONE
        scrView.contentSize = baseView.frame.size;
#endif
        
        // タイトル入力欄にフォーカスする
        [textTitle becomeFirstResponder];
        
        [defaultText release];
    }
    [imgFileMng release];
    [dbMng release];
}


- (id) initPhotoSettingWithPictureURL:(NSString *)selectPictureURL    
                         selectUserID:(USERID_INT)userID
                         selectHistID:(HISTID_INT)histID
                              popUpID:(NSUInteger)popUpID 
                             callBack:(id)callBack
{
#ifndef CALULU_IPHONE
    
    if ( (self = [super initWithPopUpViewContoller:popUpID
                                 popOverController:nil
                                          callBack:callBack
                                           nibName:@"PhotoCommentPopup"])){
        self.contentSizeForViewInPopover = CGSizeMake(720.0f, 314.0f);
#else
        if ( (self = [super initWithPopUpViewContoller:popUpID popOverController:nil callBack:callBack nibName:@"ip_PhotoCommentPopup"])){            
#endif
        self.pictureURL = selectPictureURL;
        self.selectUserID = userID;
        self.selectHistID = histID;
    }
    return  (self);
}

- (id) setDelegateObject{
#ifdef DEBUG
    NSLog(@"setDelegateObject selecthistID : %d",self.selectHistID);
#endif
    OKDImageFileManager *imgFileMng
    = [[OKDImageFileManager alloc]initWithUserID:self.selectUserID];
    userDbManager *dbMng = [[userDbManager alloc] init];
    
    if ([pictureURL hasSuffix:@"tmb"]){
        MovieResource *movieResource = [[MovieResource alloc] initWithUserId:self.selectUserID fileName:pictureURL];
        if(![dbMng setVideoProfile:textTitle.text
                              memo:textMemo.text
                           fileURL:movieResource.path
                            histID:self.selectHistID]){
            [imgFileMng release];
            [movieResource release];
            [dbMng release];
            return nil;
        }
        [movieResource release];
    }else {
        if(![dbMng setImageProfile:textTitle.text
                              memo:textMemo.text
                           fileURL:[imgFileMng getDocumentFolderFilename:pictureURL]
                            histID:self.selectHistID]){
            [imgFileMng release];
            [dbMng release];
            return nil;
        }
    }
    NSString *succeed = @"Success";
    [imgFileMng release];
    [dbMng release];
    return succeed;
}

#pragma mark - control_events    
    
- (IBAction) OnCancelButton:(id)sender
{
	if (delegate != nil) 
    {
		// クライアントクラスへcallback
		[delegate OnPopUpViewSet:-1 setObject:nil];
	}	
	
	[self closeByPopoverContoller];
}
    
// タイトルTextFieldのEnterキーイベント
- (IBAction)onTextTitleDidEnd:(id)sender
{
    // メモにフォーカス
    [textMemo becomeFirstResponder];
}

    - (void)dealloc {
        [btnOk release];
        [btnCancel release];
        [super dealloc];
    }
    - (void)viewDidUnload {
        [btnOk release];
        btnOk = nil;
        [btnCancel release];
        btnCancel = nil;
        [super viewDidUnload];
    }
@end
