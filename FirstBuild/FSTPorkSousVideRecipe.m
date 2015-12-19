//
//  FSTPorkSousVideRecipe.m
//  FirstBuild
//
//  Created by Myles Caley on 12/18/15.
//  Copyright © 2015 FirstBuild. All rights reserved.
//

#import "FSTPorkSousVideRecipe.h"

@implementation FSTPorkSousVideRecipe
- (id) init
{
    self = [super init];
    if (self)
    {
        self.name = @"Pork";
        self.recipeType = [NSNumber numberWithInt: FSTRecipeTypeFirstBuildSousVide];
    }
    return self;
    
}
@end