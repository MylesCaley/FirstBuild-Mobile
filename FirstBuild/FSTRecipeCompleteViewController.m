//
//  FSTRecipeCompleteViewController.m
//  FirstBuild
//
//  Created by Myles Caley on 12/19/15.
//  Copyright © 2015 FirstBuild. All rights reserved.
//

#import "FSTRecipeCompleteViewController.h"
#import "FSTCookingViewController.h"
#import "MobiNavigationController.h"
#import "FSTRevealViewController.h"

@interface FSTRecipeCompleteViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *pushButtonImageView;

@end

@implementation FSTRecipeCompleteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.hidesBackButton = YES;
    // remove the back button
    NSMutableArray* pushImages = [[NSMutableArray alloc] init];
    NSString* imageTitle;
    for (int ip = 0; ip <= 46; ip++) {// there are 47 frames for the push button animation
        imageTitle = [NSString stringWithFormat: @"animate-push-button_%05d", ip];
        UIImage *image = [UIImage imageNamed:imageTitle];
        if (!image) {
            NSLog(@"Could not load image named: %@", imageTitle);
        }
        else {
            [pushImages addObject:image];
        }
    }
    [self.pushButtonImageView setAnimationImages:pushImages]; // assign all the frames
    [self.pushButtonImageView setAnimationDuration:2.0];
    [self.pushButtonImageView startAnimating];
    
    self.currentParagon.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    
    MobiNavigationController* controller = (MobiNavigationController*)self.navigationController;
    [controller setHeaderText:@"COMPLETE" withFrameRect:CGRectMake(0, 0, 120, 30)];
    
    //TODO HACK
    //[self performSegueWithIdentifier:@"segueCooking" sender:self];
    
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[FSTCookingViewController class]])
    {
        ((FSTCookingViewController*)segue.destinationViewController).currentParagon = self.currentParagon;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)menuToggleTapped:(id)sender {
    [self.revealViewController rightRevealToggle:self.currentParagon];
}

#pragma mark - <FSTParagonDelegate>

- (void) cookModeChanged:(ParagonCookMode)cookMode
{
    if(self.currentParagon.session.cookMode == FSTCookingStateOff)
    {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
}
@end