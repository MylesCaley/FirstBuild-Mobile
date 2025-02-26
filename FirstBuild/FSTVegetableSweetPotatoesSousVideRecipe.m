//
//  FSTVegetableSweetPotatoesSousVideRecipe.m
//  FirstBuild
//
//  Created by Myles Caley on 12/15/15.
//  Copyright © 2015 FirstBuild. All rights reserved.
//

#import "FSTVegetableSweetPotatoesSousVideRecipe.h"

@implementation FSTVegetableSweetPotatoesSousVideRecipe
- (id) init
{
    self = [super init];
    if (self)
    {
        self.name = @"Sweet Potatoes";
        FSTParagonCookingStage* stage = [self addStage];
        stage.cookTimeMinimum = @60;
        stage.cookTimeMaximum = @120;
        stage.targetTemperature = @175;
        stage.maxPowerLevel = @10;
        stage.automaticTransition = @2;
    }
    return self;
    
}
@end
