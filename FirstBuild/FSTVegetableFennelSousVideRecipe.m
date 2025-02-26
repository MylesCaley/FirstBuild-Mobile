//
//  FSTVegetableFennelSousVideRecipe.m
//  FirstBuild
//
//  Created by Myles Caley on 12/15/15.
//  Copyright © 2015 FirstBuild. All rights reserved.
//

#import "FSTVegetableFennelSousVideRecipe.h"

@implementation FSTVegetableFennelSousVideRecipe
- (id) init
{
    self = [super init];
    if (self)
    {
        self.name = @"Fennels";
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
