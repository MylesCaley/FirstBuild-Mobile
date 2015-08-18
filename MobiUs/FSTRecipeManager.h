//
//  FSTRecipeManager.h
//  FirstBuild
//
//  Created by John Nolan on 8/17/15.
//  Copyright (c) 2015 FirstBuild. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FSTRecipe.h"

@interface FSTRecipeManager : NSObject

-(void)saveRecipe:(FSTRecipe*)recipe;

-(NSDictionary*)getSavedRecipes;

-(void)removeItemFromDefaults:(NSString*)key;

@end