//
//  courseOptionItemViewController.h
//  BodyCheck
//
//  Created by TMS on 16/02/18.
//
//

#import "courseItemBaseViewController.h"

@interface courseOptionItemViewController : courseItemBaseViewController
{
    IBOutlet UIImageView    *imgPanst;
    IBOutlet UIButton       *btnPanst;
    IBOutlet UILabel        *lblPanst;
    IBOutlet UILabel        *lblPanstName;
    
    IBOutlet UIImageView    *imgSpats;
    IBOutlet UIButton       *btnSpats;
    IBOutlet UILabel        *lblSpats;
    IBOutlet UILabel        *lblSpatsName;
}

// パンストの表示設定
-(NSInteger) setPanstVisible:(BOOL)isShow;

// スパッツの表示設定
-(NSInteger) setSpatsVisible:(BOOL)isShow;

@end
