//
//  FSTVegetableTurnipsSousVideRecipe.m
//  FirstBuild
//
//  Created by Myles Caley on 12/15/15.
//  Copyright © 2015 FirstBuild. All rights reserved.
//

#import "FSTVegetableTurnipsSousVideRecipe.h"

@implementation FSTVegetableTurnipsSousVideRecipe
- (id) init
{
    self = [super init];
    if (self)
    {
        self.name = @"Turnips";
        FSTParagonCookingStage* stage = [self addStage];
        stage.cookTimeMinimum = @30;
        stage.cookTimeMaximum = @60;
        stage.targetTemperature = @185;
        stage.maxPowerLevel = @10;
        stage.automaticTransition = @2;
    }
    return self;
    
}
@end
