//
//  ProductAddViewController.m
//  FirstBuild-Mobile
//
//  Created by Myles Caley on 12/11/14.
//  Copyright (c) 2014 FirstBuild. All rights reserved.
//

#import "ProductAddViewController.h"
#import <SWRevealViewController.h>
#import "FSTHumanaPillBottle.h"
#import "FSTParagon.h"
#import "FSTHoodie.h"
#import "FSTBleCommissioningViewController.h"
#import "FSTBleCentralManager.h"

@interface ProductAddViewController ()

@end

@implementation ProductAddViewController


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //TODO: need to fix this correctly for conditional build
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    switch (indexPath.row) {
        case 0:
            CellIdentifier = @"paragon";
            break;
            
        case 1:
            CellIdentifier = @"chillhub";
            
            break;
            
        case 2:
            CellIdentifier = @"humanapillbottle";
            break;
            
        case 3:
            CellIdentifier = @"hoodie";
            break;
            
        default:
            break;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier forIndexPath: indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
    
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];//UIColorFromRGB(0x00B5CC);
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 46;
}

-(void)viewDidLayoutSubviews
{
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.alpha = 1;
    self.navigationController.navigationBar.translucent = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
  
}

- (IBAction)revealToggle:(id)sender
{
    [self.revealViewController revealToggle:sender];
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"segueAddHumanaPillBottle"])
    {
        FSTBleCommissioningViewController* vc = (FSTBleCommissioningViewController*)segue.destinationViewController;
        vc.bleProductClass = sender;
    }
    else if ([segue.identifier isEqualToString:@"segueAddParagon"])
    {
        FSTBleCommissioningViewController* vc = (FSTBleCommissioningViewController*)segue.destinationViewController;
        vc.bleProductClass = sender;
    }
    else if ([segue.identifier isEqualToString:@"segueAddHoodie"])
    {
        FSTBleCommissioningViewController* vc = (FSTBleCommissioningViewController*)segue.destinationViewController;
        vc.bleProductClass = sender;
    }
}

- (IBAction)pillBottleTouchHandler:(id)sender
{
    [self performSegueWithIdentifier:@"segueAddHumanaPillBottle" sender:[FSTHumanaPillBottle class]];
}
- (IBAction)hoodieTouchHandler:(id)sender {
    [self performSegueWithIdentifier:@"segueAddHoodie" sender:[FSTHoodie class]];
}

- (IBAction)paragonTouchHandler:(id)sender
{
    if (!([[FSTBleCentralManager sharedInstance] isPoweredOn]))
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Oops!"
                                                                                 message:@"Bluetooth must be enabled to add a Paragon."
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionOk = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
        [alertController addAction:actionOk];
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else
    {
        [self performSegueWithIdentifier:@"segueAddParagon" sender:[FSTParagon class]];
    }

}
@end
