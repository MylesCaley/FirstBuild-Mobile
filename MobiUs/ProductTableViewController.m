//
//  ProductTableViewController.m
//  MobiUs
//
//  Created by Myles Caley on 10/7/14.
//  Copyright (c) 2014 FirstBuild. All rights reserved.
//

#import "ProductTableViewController.h"
#import "ProductTableViewCell.h"
#import <SWRevealViewController.h>
#import <RBStoryboardLink.h>
#import "FirebaseShared.h"
#import "FSTChillHub.h"
#import "FSTParagon.h"
#import "ChillHubViewController.h"
#import "MobiNavigationController.h"
#import "FSTCookingMethodViewController.h"
#import "FSTBleCentralManager.h"
#import "FSTCookingViewController.h"
#import "ProductGradientView.h" // to control up or down gradient

#import "FSTCookingProgressLayer.h" //TODO: TEMP

@interface ProductTableViewController ()

@property (weak, nonatomic) IBOutlet ProductGradientView *topGradient;
@property (weak, nonatomic) IBOutlet ProductGradientView *bottomGradient;

@end

@implementation ProductTableViewController

#pragma mark - Private

static NSString * const reuseIdentifier = @"ProductCell";
static NSString * const reuseIdentifierParagon = @"ProductCellParagon";
NSObject* _connectedToBleObserver;
NSObject* _deviceConnectedObserver;
NSObject* _newDeviceBoundObserver;
NSObject* _deviceRenamedObserver;
NSObject* _deviceDisconnectedObserver;
NSObject* _deviceBatteryChangedObserver;

NSIndexPath *_indexPathForDeletion;

#pragma mark - <UIViewDelegate>
//TODO firebase objects
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.products = [[NSMutableArray alloc] init];
    [self.delegate itemCountChanged:0];
    
    //get all the saved BLE peripherals
    [self configureBleDevices];
    
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.topGradient.up = true;
    self.bottomGradient.up = false;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:_connectedToBleObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:_deviceConnectedObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:_newDeviceBoundObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:_deviceRenamedObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:_deviceDisconnectedObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:_deviceBatteryChangedObserver];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Device Configuration

//TODO need to store device type so we can have other types of devices
-(void)configureBleDevices
{
    NSDictionary* devices = [[FSTBleCentralManager sharedInstance] getSavedPeripherals];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    __weak typeof(self) weakSelf = self;
    
    //grab all our saved products and put them in a product array
    for (id key in devices)
    {
        FSTParagon* paragon = [FSTParagon new];
        paragon.online = NO;
        paragon.savedUuid = [[NSUUID alloc]initWithUUIDString:key];
        paragon.friendlyName = [devices objectForKeyedSubscript:key];
        [self.products addObject:paragon];
        [self.delegate itemCountChanged:self.products.count];
    }
    
    //attempt to connect to the BLE devices
    if ([[FSTBleCentralManager sharedInstance] isPoweredOn])
    {
        [self connectBleDevices];
    }
    
    //also listen for power on signal before connecting to devices
    _connectedToBleObserver = [center addObserverForName:FSTBleCentralManagerPoweredOn
                                                  object:nil
                                                   queue:nil
                                              usingBlock:^(NSNotification *notification)
    {
       [weakSelf connectBleDevices];
    }];
    
    
    //when a device is connected check and see if we have it in our products list
    //we may get messages here about devices that are connected that are not saved yet (commissioning)
    //in that case we listen to FSTBleCentralManagerNewDeviceBound
    _deviceConnectedObserver = [center addObserverForName:FSTBleCentralManagerDeviceConnected
                                                   object:nil
                                                    queue:nil
                                               usingBlock:^(NSNotification *notification)
    {
        CBPeripheral* peripheral = (CBPeripheral*)(notification.object);
        
        //search through attached products and mark online anything we already have stored
        for (FSTProduct* product in weakSelf.products)
        {
            if ([product isKindOfClass:[FSTBleProduct class]])
            {
                FSTBleProduct* bleProduct = (FSTBleProduct*)product;
                
                //need to compare the strings and not the actual object since they are not the same
                if ([[bleProduct.savedUuid UUIDString] isEqualToString:[peripheral.identifier UUIDString]])
                {
                    bleProduct.peripheral = peripheral;
                    bleProduct.peripheral.delegate = bleProduct;
                    DLog(@"discovering services for peripheral %@", bleProduct.peripheral.identifier);
                    
                    //TODO:: HACK. Service discovery is slow, we need to find the actual service we are looking for
                    //here which is going to be by product type. Hardcoded for the paragon service.
                    //NSUUID* uuid = [[NSUUID alloc]initWithUUIDString:@"05C78A3E-5BFA-4312-8391-8AE1E7DCBF6F"];
                    //NSArray* services = [[NSArray alloc] initWithObjects:uuid, nil];
                    
                    [bleProduct.peripheral discoverServices:nil];
                    bleProduct.online = YES;
                    [weakSelf.tableView reloadData];
                }
            }
        }
    }];
    
    //notify us of any new BLE devices that were added
    _newDeviceBoundObserver = [center addObserverForName:FSTBleCentralManagerNewDeviceBound
                                                  object:nil
                                                   queue:nil
                                              usingBlock:^(NSNotification *notification)
    {
        CBPeripheral* peripheral = (CBPeripheral*)(notification.object);
        NSDictionary* latestDevices = [[FSTBleCentralManager sharedInstance] getSavedPeripherals];

        FSTParagon* product = [FSTParagon new]; //TODO type; paragon hardcoded
        product.online = YES;
        product.peripheral = peripheral;
        product.peripheral.delegate = product;
        [product.peripheral discoverServices:nil];
        product.friendlyName = [latestDevices objectForKeyedSubscript:[peripheral.identifier UUIDString]];
        [self.products addObject:(FSTParagon*)product];
        [self.delegate itemCountChanged:self.products.count];
        [weakSelf.tableView reloadData];
    }];
    
    //notify us of any BLE devices that were renamed
    _deviceRenamedObserver = [center addObserverForName:FSTBleCentralManagerDeviceNameChanged
                                                  object:nil
                                                   queue:nil
                                              usingBlock:^(NSNotification *notification)
    {
        CBPeripheral* peripheral = (CBPeripheral*)(notification.object);
        NSDictionary* latestDevices = [[FSTBleCentralManager sharedInstance] getSavedPeripherals];
        for (FSTProduct* product in weakSelf.products)
        {
            //get all ble products in the local products array
            if ([product isKindOfClass:[FSTBleProduct class]])
            {
                FSTBleProduct* bleProduct = (FSTBleProduct*)product;
                
                //search for ble peripheral that was renamed
                if (bleProduct.peripheral.identifier == peripheral.identifier)
                {
                    //grab it from the saved list
                    bleProduct.friendlyName = [latestDevices objectForKeyedSubscript:[peripheral.identifier UUIDString]];
                    [weakSelf.tableView reloadData];
                    break;
                }
            }
        }
    }];
    
    //disconnected
    _deviceDisconnectedObserver = [center addObserverForName:FSTBleCentralManagerDeviceDisconnected
                                                       object:nil
                                                        queue:nil
                                                   usingBlock:^(NSNotification *notification)
    {
        CBPeripheral* peripheral = (CBPeripheral*)notification.object;
        
        for (FSTProduct* product in self.products)
        {
            if ([product isKindOfClass:[FSTBleProduct class]])
            {
                FSTBleProduct* bleDevice = (FSTBleProduct*)product;
                
                if (bleDevice.peripheral == peripheral)
                {
                    //since it is still in our list lets reconnect
                    bleDevice.online = NO;
                    [[FSTBleCentralManager sharedInstance] connectToSavedPeripheralWithUUID:bleDevice.peripheral.identifier];
                    [weakSelf.tableView reloadData];
                }
            }
        }
    }];
    
    _deviceBatteryChangedObserver = [center addObserverForName:FSTBatteryLevelChangedNotification
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:^(NSNotification *notification)
    {
        
        FSTProduct* noteProduct = (FSTProduct*)notification.object;
        
        for (FSTProduct* product in self.products) // shouldn't all products have a battery level
        {
            if ([product isKindOfClass:[FSTParagon class]])
            {
                FSTParagon* paragon = (FSTParagon*)product;
                if (paragon == noteProduct) 
                {
                    [weakSelf.tableView reloadData];
                    
                }
            }
        }
    }];
}

- (void)connectBleDevices
{
    for (FSTProduct* product in self.products)
    {
        if ([product isKindOfClass:[FSTBleProduct class]])
        {
            FSTBleProduct* bleDevice = (FSTBleProduct*)product;
            
            bleDevice.peripheral = [[FSTBleCentralManager sharedInstance] connectToSavedPeripheralWithUUID:bleDevice.savedUuid];
        }
    }
}

- (void) prepareForSegue: (UIStoryboardSegue *) segue sender: (id) sender
{
    RBStoryboardLink *destination = segue.destinationViewController;
    
    if ([sender isKindOfClass:[FSTParagon class]])
    {
        if ([destination.scene isKindOfClass:[FSTCookingMethodViewController class]])
        {
            FSTCookingMethodViewController *vc = (FSTCookingMethodViewController*)destination.scene;
            vc.product = sender;
        }
    }
    else if ([sender isKindOfClass:[FSTChillHub class]])
    {
        ChillHubViewController *vc = (ChillHubViewController*)destination.scene;
        vc.product = sender;
    }
}

#pragma mark <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.products.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FSTProduct * product = self.products[indexPath.row];
    ProductTableViewCell *productCell;
    
    if ([product isKindOfClass:[FSTChillHub class]])
    {
        productCell = [tableView dequeueReusableCellWithIdentifier:@"ProductCell" forIndexPath:indexPath];
    }
    else if ([product isKindOfClass:[FSTParagon class]])
    {
        
        FSTParagon* paragon = (FSTParagon*)product; // cast it to check the cooking status
        productCell = [tableView dequeueReusableCellWithIdentifier:@"ProductCellParagon" forIndexPath:indexPath];
        productCell.friendlyName.text = product.friendlyName;
        
        productCell.batteryLabel.text = [NSString stringWithFormat:@"%ld%%", (long)[paragon.batteryLevel integerValue]];
        
        productCell.batteryView.batteryLevel = [paragon.batteryLevel doubleValue]/100;
        [productCell.batteryView setNeedsDisplay]; // redraw
        //Taken out since those properties were not connected
        
        // check paragon cook modes to update status label
        if (paragon.currentCookMode == kPARAGON_PREHEATING)
        {
            [productCell.statusLabel setText:@"Preheating"];
        }
        else if(paragon.currentCookMode == kPARAGON_HEATING)
        {
            [productCell.statusLabel setText:@"Cooking"];
        }
        else if(paragon.currentCookMode == kPARAGON_HEATING_WITH_TIME)
        {
            [productCell.statusLabel setText:@"Cooking"]; // might need more states
        }
        else
        {
            [productCell.statusLabel setText:@""];
        }

        //TODO we need observers on the cookmode for each paragon in order to set the status
//        NSString* statusLabel;
//        
//        switch (((FSTParagon*)product).currentCookMode)
//        {
//            case kPARAGON_HEATING:
//                statusLabel = @"Cooking";
//                break;
//                
//            case kPARAGON_HEATING_WITH_TIME:
//                statusLabel = @"Cooking";
//                break;
//                
//            case kPARAGON_OFF:
//                statusLabel = @"Idle";
//                break;
//                
//            case kPARAGON_SOUS_VIDE_ENABLED:
//                statusLabel = @"Idle";
//                break;
//                
//            case kPARAGON_PREHEATING:
//                statusLabel = @"Preheat";
//                break;
//                
//            default:
//                statusLabel = @"Idle";
//                break;
//        }
//        productCell.statusLabel.text = statusLabel;
        
    }
    
    if (product.online)
    {
        //productCell.userInteractionEnabled = YES;
        productCell.disabledView.hidden = YES;
        productCell.arrowButton.hidden = NO;
    }
    else
    {
        //productCell.userInteractionEnabled = NO;
        productCell.disabledView.hidden = NO;
        productCell.arrowButton.hidden = YES;
    }
    
    
    return productCell;
}

#pragma mark <UITableViewDelegate>

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FSTProduct * product = self.products[indexPath.row];
    NSLog(@"selected %@", product.identifier);
    
    if (product.online)
    {
        if ([product isKindOfClass:[FSTChillHub class]])
        {
            [self performSegueWithIdentifier:@"segueChillHub" sender:product];
        }
        if ([product isKindOfClass:[FSTParagon class]])
        {
            FSTParagon* paragon = (FSTParagon*)product;
            
            if (paragon.currentCookMode == kPARAGON_PREHEATING)
            {
                FSTCookingViewController *vc = [[UIStoryboard storyboardWithName:@"FSTParagon" bundle:nil]instantiateViewControllerWithIdentifier:@"FSTCookingViewController"];
                vc.currentParagon = paragon;
                vc.progressState = kPreheating;
                [self.navigationController pushViewController:vc animated:YES];
            }
            else if(paragon.currentCookMode == kPARAGON_HEATING)
            {
                FSTCookingViewController *vc = [[UIStoryboard storyboardWithName:@"FSTParagon" bundle:nil]instantiateViewControllerWithIdentifier:@"FSTCookingViewController"];
                vc.progressState = kCooking;
                [self.navigationController pushViewController:vc animated:YES];
            }
            else if(paragon.currentCookMode == kPARAGON_HEATING_WITH_TIME)
            {
                FSTCookingViewController *vc = [[UIStoryboard storyboardWithName:@"FSTParagon" bundle:nil]instantiateViewControllerWithIdentifier:@"FSTCookingViewController"];
                vc.progressState = kCooking;
                [self.navigationController pushViewController:vc animated:YES];
            }
            else
            {
                [self performSegueWithIdentifier:@"segueParagon" sender:product];
            }
        }
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 120.0; // edit hight of table view cell
}

-(BOOL)tableView: (UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return true; // can delete all
}

-(NSArray*)tableView: (UITableView*)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *editAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Edit" handler:^(UITableViewRowAction* action, NSIndexPath *indexPath){
        
           NSLog(@"Editing\n");
    }];
    editAction.backgroundColor = [UIColor grayColor];
    
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"Delete" handler:^(UITableViewRowAction* action, NSIndexPath *indexPath){
        //[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        NSLog(@"delete");
        FSTParagon * deletedItem = self.products[indexPath.item];
        [self.products removeObjectAtIndex:indexPath.item];
        [[FSTBleCentralManager sharedInstance] deleteSavedPeripheralWithUUIDString: [deletedItem.peripheral.identifier UUIDString]];
        [[FSTBleCentralManager sharedInstance] disconnectPeripheral:deletedItem.peripheral];
        [self.tableView reloadData];
        
        if (self.products.count==0)
        {
            [self.delegate itemCountChanged:0];
        }
    }];
    return @[editAction, deleteAction];
}

-(void)tableView: (UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 // intentionally empty
}

#pragma mark - BONEYARD

//-(void)configureFirebaseDevices
//{
//    //TODO: support multiple device types
//    Firebase *chillhubsRef = [[[FirebaseShared sharedInstance] userBaseReference] childByAppendingPath:@"devices/chillhubs"];
//    [chillhubsRef removeAllObservers];
//    
//    //device added
//    [chillhubsRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
//        FSTChillHub* chillhub = [FSTChillHub new];
//        chillhub.firebaseRef = snapshot.ref ;
//        chillhub.identifier = snapshot.key;
//        id rawVal = snapshot.value;
//        if (rawVal != [NSNull null])
//        {
//            NSDictionary* val = rawVal;
//            if ( [(NSString*)[val objectForKey:@"status"] isEqualToString:@"connected"] )
//            {
//                chillhub.online = YES;
//            }
//            else
//            {
//                chillhub.online = NO;
//            }
//            [self.productCollection reloadData];
//        }
//        
//        [self.products addObject:chillhub];
//        [self.productCollection reloadData];
//        [self.delegate itemCountChanged:self.products.count];
//    }];
//    
//    //device removed
//    [chillhubsRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
//        for (long i=self.products.count-1; i>-1; i--)
//        {
//            FSTChillHub *chillhub = [self.products objectAtIndex:i];
//            if ([chillhub.identifier isEqualToString:snapshot.key])
//            {
//                [self.products removeObject:chillhub];
//                [self.productCollection reloadData];
//                break;
//            }
//        }
//        [self.delegate itemCountChanged:self.products.count];
//    }];
//    
//    //device online,offline status
//    [chillhubsRef observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
//        for (long i=self.products.count-1; i>-1; i--)
//        {
//            FSTChillHub *chillhub = [self.products objectAtIndex:i];
//            if ([chillhub.identifier isEqualToString:snapshot.key])
//            {
//                id rawVal = snapshot.value;
//                if (rawVal != [NSNull null])
//                {
//                    NSDictionary* val = rawVal;
//                    if ( [(NSString*)[val objectForKey:@"status"] isEqualToString:@"connected"] )
//                    {
//                        chillhub.online = YES;
//                    }
//                    else
//                    {
//                        chillhub.online = NO;
//                    }
//                    [self.productCollection reloadData];
//                }
//                break;
//            }
//        }
//    }];
//}
//


//- (void)checkForCloudProducts
//{
//    //TODO: not sure if this is the correct pattern. we want to show the "no products"
//    //found if there really aren't any products. since there is no timeout concept on the firebase
//    //API then am not sure what the correct method is for detecting a network error.
//
//    Firebase * ref = [[[FirebaseShared sharedInstance] userBaseReference] childByAppendingPath:@"devices"];
//    [ref removeAllObservers];
//
//    __weak typeof(self) weakSelf = self;
//
//    [self.loadingIndicator startAnimating];
//
//    //detect if we have any products/if the products are removed it is
//    //detected in the embeded collection view controller and we registered as a delegate
//    [ref observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
//        [weakSelf.loadingIndicator stopAnimating];
//        [weakSelf hideProducts:NO];
//        [weakSelf hideNoProducts:YES];
//        weakSelf.hasFirebaseProducts = YES;
//    } withCancelBlock:^(NSError *error) {
//        //TODO: if its really a permission error then we need to handle this differently
//        DLog(@"%@",error.localizedDescription);
//        [weakSelf.loadingIndicator stopAnimating];
//    }];
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//
//        if (!self.hasFirebaseProducts)
//        {
//            [self.loadingIndicator stopAnimating];
//            [self noItemsInCollection];
//        }
//    });
//}

@end