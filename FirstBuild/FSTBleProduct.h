//
//  FSTBleProduct.h
//  FirstBuild
//
//  Created by Myles Caley on 6/25/15.
//  Copyright (c) 2015 FirstBuild. All rights reserved.
//

#import "FSTProduct.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface FSTBleProduct : FSTProduct <CBPeripheralDelegate>

extern NSString * const FSTDeviceReadyNotification;
extern NSString * const FSTDeviceLoadProgressUpdated;
extern NSString * const FSTBatteryLevelChangedNotification;

@property (strong,nonatomic) CBPeripheral* peripheral;
@property (strong,nonatomic) NSUUID* savedUuid;
@property (strong,nonatomic) NSMutableDictionary* characteristics;
@property (atomic) BOOL initialCharacteristicValuesRead;
@property (nonatomic, strong) NSNumber* batteryLevel;
@property (nonatomic, strong) NSNumber* loadingProgress;

- (void) notifyDeviceReady;
- (void) notifyDeviceLoadProgressUpdated;
- (void) writeHandler: (CBCharacteristic*)characteristic;
- (void) readHandler: (CBCharacteristic*)characteristic;
- (void) handleDiscoverCharacteristics: (NSArray*)characteristics;


@end