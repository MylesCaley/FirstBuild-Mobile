//
//  FSTStateBarView.h
//  FirstBuild
//
//  Created by John Nolan on 7/14/15.
//  Copyright (c) 2015 FirstBuild. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FSTCookingProgressLayer.h"
#import "FSTParagon.h"

@interface FSTStateBarView : UIView

@property (nonatomic)  ParagonCookMode circleState;
@property (strong, nonatomic) NSNumber* numberOfStates;

@end
