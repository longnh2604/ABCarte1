//
//  CameraModePopup.m
//  iPadCamera
//
//  Created by TMS on 2018/01/5.
//
//

#import "CameraModePopup.h"

@interface CameraModePopup ()

@end

@implementation CameraModePopup

@synthesize cm_delegate;

UISegmentedControl *sc;

- (id)initWithPopUpViewContoller:(NSUInteger)popUpID
               popOverController:(UIPopoverController *)controller
                        callBack:(id)callBackDelegate
{
    self = [super initWithPopUpViewContoller:popUpID
                           popOverController:controller
                                    callBack:callBackDelegate];
    if (self) {
        cm_delegate = callBackDelegate;
    }
    
    return self;
}

- (void)setCameraMode:(NSInteger)cameraMode{
    //sc.selectedSegmentIndex = cameraMode;
    NSString *title;
    if(cameraMode == 0){
        title = @"写真";
    }else if(cameraMode == 1){
        title = @"動画";
    }else if(cameraMode == 2){
        title = @"動画(自動停止)";
    }else if(cameraMode == 3){
        title = @"Webカメラ";
    }else if(cameraMode == 4){
        title = @"Webカメラ";
    }else if(cameraMode == 5){
        title = @"AirMicro";
    } else if(cameraMode == 6){
        title = @"3RCamera";
    }
    
    [self searchIndex:title];
}


- (void)searchIndex:(NSString*)str{

    for(int i = 0;i < sc.numberOfSegments;i++){
        NSString *title = [sc titleForSegmentAtIndex:i];
        if([str compare:title] == NSOrderedSame){
            sc.selectedSegmentIndex = i;
            break;
        }else if([str compare:title] == NSOrderedSame){
            sc.selectedSegmentIndex = i;
            break;
        }else if([str compare:title] == NSOrderedSame){
            sc.selectedSegmentIndex = i;
            break;
        }else if([str compare:title] == NSOrderedSame){
            sc.selectedSegmentIndex = i;
            break;
        }else if([str compare:title] == NSOrderedSame){
            sc.selectedSegmentIndex = i;
            break;
        }else if ([str compare:title] == NSOrderedSame){
            sc.selectedSegmentIndex = i;
            break;
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat xp,yp = 30,w,h = 30;

    NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
    // AirMicroが有効になっている場合
    /*
    if ([defaluts boolForKey:@"airmicro_enable"]) {
        if ([AccountManager isWebCam] || [AccountManager isWebCam2]) {
            arr = [NSArray arrayWithObjects:@"写真", @"動画", @"動画(自動停止)", @"Webカメラ", @"AirMicro", nil];
            xp = 5;
            yp = 30;
            w = 500;
            h = 30;
        }else{
            arr = [NSArray arrayWithObjects:@"写真", @"動画", @"動画(自動停止)", @"AirMicro", nil];
            xp = 30;
            yp = 30;
            w = 450;
            h = 30;
        }
    }else{
        xp = 30;
        yp = 30;
        w = 450;
        h = 30;
        if ([AccountManager isWebCam] || [AccountManager isWebCam2]) {
            arr = [NSArray arrayWithObjects:@"写真", @"動画", @"動画(自動停止)", @"Webカメラ", nil];
        }else{
            arr = [NSArray arrayWithObjects:@"写真", @"動画", @"動画(自動停止)", nil];
        }
    }*/
    NSMutableArray *arr = [NSMutableArray arrayWithObjects:@"写真", nil];
    
    if ([AccountManager isMovie]) {
        [arr addObject:@"動画"];
         [arr addObject:@"動画(自動停止)"];
    }
    
    if ([AccountManager isWebCam] || [AccountManager isWebCam2]) {
        [arr addObject:@"Webカメラ"];
    }
    
    if ([defaluts boolForKey:@"airmicro_enable"]) {
        [arr addObject:@"AirMicro"];
    }
    
    if ([defaluts boolForKey:@"3rcamera_enable"]) {
        [arr addObject:@"3RCamera"];
    }
    
    if ([arr count] == 6) {
        xp = 0;
        w = 600;
    }else if([arr count] == 5){
        xp = 30;
        w = 500;
    }else if([arr count] == 4){
        xp = 50;
        w = 400;
    }else if([arr count] == 3){
        xp = 85;
        w = 300;
    }else if([arr count] == 2){
        xp = 85;
        w = 200;
    }else{
        xp = 125;
        w = 100;
    }
    
    xp = 5;
    w  = 500;
    
    sc =
    [[[UISegmentedControl alloc] initWithItems:arr] autorelease];
    sc.frame = CGRectMake(xp, yp, w, h);
    [sc addTarget:self action:@selector(SegChanged:)
  forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:sc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)dealloc {
    [super dealloc];
}
- (void)viewDidUnload {
    [super viewDidUnload];
}

#pragma mark アクション処理部

- (void)SegChanged:(id)sender {
    NSInteger mode;
    NSString *title = [sc titleForSegmentAtIndex:sc.selectedSegmentIndex];
    
    if([title compare:@"写真"] == NSOrderedSame){
        mode = 0;
    }else if([title compare:@"動画"] == NSOrderedSame){
        mode = 1;
    }else if([title compare:@"動画(自動停止)"] == NSOrderedSame){
        mode = 2;
    }else if([title compare:@"Webカメラ"] == NSOrderedSame){
        if ([AccountManager isWebCam2]) {
            mode = 4;
        }else{
            mode = 3;
        }
    }else if([title compare:@"AirMicro"] == NSOrderedSame){
        mode = 5;
    } else if ([title compare:@"3RCamera"] == NSOrderedSame) {
        mode = 6;
    }
    /*
    NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
    if ([defaluts boolForKey:@"airmicro_enable"]) {
        if ([AccountManager isWebCam] || [AccountManager isWebCam2]) {
            if(index == 4){
                index = 5;
            }else if(index == 3){
                if ([AccountManager isWebCam2]) {
                    index = 4;
                }
            }
        }else{
            if(index == 3){
                index = 5;
            }
        }
    }else{
        if ([AccountManager isWebCam] || [AccountManager isWebCam2]) {
            if(index == 3){
                if ([AccountManager isWebCam2]) {
                    index = 4;
                }
            }
        }else{
        }
    }*/
    [self onCameraModeSet:mode];
}

- (IBAction)onCameraModeSet:(id)sender {
    NSInteger index = (NSInteger)sender;
    if([cm_delegate respondsToSelector:@selector(onCameraModeSet:)]) {
        [cm_delegate onCameraModeSet:index];
    }
    
    [self closeByPopoverContoller];
}

@end
