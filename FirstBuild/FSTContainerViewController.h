//
//  FSTContainerViewController.h
//  FirstBuild
//
//  Created by John Nolan on 8/6/15.
//  Copyright (c) 2015 FirstBuild. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FSTParagon.h"
#import "CookingStateModel.h"

@interface FSTContainerViewController : UIViewController

-(void) segueToStateWithIdentifier:(NSString*)identifier sender:(id)sender; // called at embed segue, switch to one of the child view controllers

@property (nonatomic, weak) CookingStateModel* cookingData;

@end
