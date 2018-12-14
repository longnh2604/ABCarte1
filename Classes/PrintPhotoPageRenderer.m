//
//  PrintPhotoPageRenderer.m
//  iPadCamera
//
//  Created by MacBook on 11/05/12.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PrintPhotoPageRenderer.h"


@implementation PrintPhotoPageRenderer

@synthesize imageToPrint;

// This code always draws one image at print time.
-(NSInteger)numberOfPages
{
	NSInteger pages = 1;
	
	// return 1;
	
	return (pages);
}

/*  When using this UIPrintPageRenderer subclass to draw a photo at print
 time, the app explicitly draws all the content and need only override
 the drawPageAtIndex:inRect: to accomplish that.
 
 The following scaling algorithm is implemented here:
 1) On borderless paper, users expect to see their content scaled so that there is
 no whitespace at the edge of the paper. So this code scales the content to
 fill the paper at the expense of clipping any content that lies off the paper.
 2) On paper which is not borderless, this code scales the content so that it fills
 the paper. This reduces the size of the photo but does not clip any content.
 */
- (void)drawPageAtIndex:(NSInteger)pageIndex inRect:(CGRect)printableRect
{
	if(self.imageToPrint){
		CGRect destRect;
		// When drawPageAtIndex:inRect: paperRect reflects the size of
		// the paper we are printing on and printableRect reflects the rectangle
		// describing the imageable area of the page, that is the portion of the page
		// that the printer can mark without clipping.
		CGSize paperSize = self.paperRect.size;
		CGSize imageableAreaSize = self.printableRect.size;
		// If the paperRect and printableRect have the same size, the sheet is borderless and we will use
		// the fill algorithm. Otherwise we will uniformly scale the image to fit the imageable area as close
		// as is possible without clipping.
		BOOL fillSheet = paperSize.width == imageableAreaSize.width && paperSize.height == imageableAreaSize.height;
		CGSize imageSize = [self.imageToPrint size];
		if(fillSheet){
			destRect = CGRectMake(0, 0, paperSize.width, paperSize.height);
		}
		else
			destRect = self.printableRect;
		
		// Calculate the ratios of the destination rectangle width and height to the image width and height.
		CGFloat width_scale = (CGFloat)destRect.size.width/imageSize.width, height_scale = (CGFloat)destRect.size.height/imageSize.height;
		CGFloat scale;
		if(fillSheet)
			scale = width_scale > height_scale ? width_scale : height_scale;	  // This produces a fill to the entire sheet and clips content.
		else
			scale = width_scale < height_scale ? width_scale : height_scale;	  // This shows all the content at the expense of additional white space.
		
		// Locate destRect so that the scaled image is centered on the sheet. 
		destRect = CGRectMake((paperSize.width - imageSize.width*scale)/2,
							  (paperSize.height - imageSize.height*scale)/2, 
							  imageSize.width*scale, imageSize.height*scale);
		// Use UIKit to draw the image to destRect.
		[self.imageToPrint drawInRect:destRect];
	}else {
		NSLog(@"%s No image to draw!", __func__);
	}
	
	NSLog(@"%s printer complete", __func__);
}

@end
