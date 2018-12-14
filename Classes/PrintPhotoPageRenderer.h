//
//  PrintPhotoPageRenderer.h
//  iPadCamera
//
//  Created by MacBook on 11/05/12.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PrintPhotoPageRenderer : UIPrintPageRenderer {
	UIImage *imageToPrint;
}

@property (readwrite, retain) UIImage *imageToPrint;

@end
