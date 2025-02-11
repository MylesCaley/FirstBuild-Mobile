//
//  FSTStageTableViewController.h
//  FirstBuild
//
//  Created by John Nolan on 8/26/15.
//  Copyright (c) 2015 FirstBuild. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FSTStageTableViewControllerDelegate <NSObject>

-(void)editStageAtIndex:(NSInteger)index;
// this will let editing view controller know what stage to load into the stage editor

-(void)deleteStageAtIndex:(NSInteger)index;
// how does the recipe remove a stage?

-(BOOL)canEditStages;

@end
@interface FSTStageTableViewController : UITableViewController

@property (nonatomic) NSInteger stageCount;

@property (nonatomic) id<FSTStageTableViewControllerDelegate> delegate;

@end
