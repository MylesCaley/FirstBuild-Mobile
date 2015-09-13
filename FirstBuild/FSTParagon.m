//
//  FSTParagon.m
//  FirstBuild
//
//  Created by Myles Caley on 3/12/15.
//  Copyright (c) 2015 FirstBuild. All rights reserved.
//

#import "FSTParagon.h"
#import "FSTSavedRecipeManager.h"
//#import "FSTParagonCookingSession.h" 

@implementation FSTParagon

//notifications
NSString * const FSTActualTemperatureChangedNotification    = @"FSTActualTemperatureChangedNotification";
NSString * const FSTTargetTemperatureChangedNotification    = @"FSTTargetTemperatureChangedNotification";
NSString * const FSTBurnerModeChangedNotification           = @"FSTBurnerModeChangedNotification";
NSString * const FSTElapsedTimeChangedNotification          = @"FSTElapsedTimeChangedNotification";

NSString * const FSTCookTimeSetNotification                 = @"FSTCookTimeSetNotification";
NSString * const FSTCookingModeChangedNotification          = @"FSTCookingModeChangedNotification";
NSString * const FSTElapsedTimeSetNotification              = @"FSTElapsedTimeSetNotification";
NSString * const FSTTargetTemperatureSetNotification        = @"FSTTargetTemperatureSetNotification";

//app info service
NSString * const FSTServiceAppInfoService               = @"E936877A-8DD0-FAA7-B648-F46ACDA1F27B";
NSString * const FSTCharacteristicAppInfo               = @"318DB1F5-67F1-119B-6A41-1EECA0C744CE"; //read

//acm service
NSString * const FSTServiceParagon                      = @"05C78A3E-5BFA-4312-8391-8AE1E7DCBF6F";
NSString * const FSTCharacteristicSpecialFeatures       = @"E7CDDD9D-DCAC-4D70-A0E1-D3B6DFEB5E4C"; //read,notify,write
NSString * const FSTCharacteristicProbeFirmwareInfo     = @"83D33E5C-68EA-4158-8655-1A2AC0313FF6"; //read
NSString * const FSTCharacteristicErrorState            = @"5BCBF6B1-DE80-94B6-0F4B-99FB984707B6"; //read,notify
NSString * const FSTCharacteristicProbeConnectionState  = @"6B402ECC-3DDA-8BB4-9E42-F121D7E1CF69"; //read,notify
NSString * const FSTCharacteristicBatteryLevel          = @"A74C3FB9-6E13-B4B9-CD47-465AAD76FCE7"; //read,notify
NSString * const FSTCharacteristicBurnerStatus          = @"A1B9F907-D440-4278-97FE-0FBB4AEE93FD"; //read,notify
NSString * const FSTCharacteristicTargetTemperature     = @"71B1A100-E3AE-46FF-BB0A-E37D0BA79496"; //read,notify,write
NSString * const FSTCharacteristicElapsedTime           = @"998142D1-658E-33E2-DFC0-32091E2354EC"; //read,notify
NSString * const FSTCharacteristicCookTime              = @"C4510188-9062-4D28-97EF-4FB32FFE1AC5"; //read,write
NSString * const FSTCharacteristicCurrentTemperature    = @"8F080B1C-7C3B-FBB9-584A-F0AFD57028F0"; //read,notify
NSString * const FSTCharacteristicRecipeId              = @"FF";


NSMutableDictionary *requiredCharacteristics; // a dictionary of strings with booleans



//TODO put sizes for the characteristics here and remove magic numbers below


__weak NSTimer* _readCharacteristicsTimer;

#pragma mark - Allocation

- (id)init
{
    self = [super init];
    
    if (self)
    {
        //setup the current cooking method and session, which is the actual
        //state of the cooking as reported by the cooktop
        //TODO: create a new recipe based on the actual recipe
        self.recipeId = nil;
        self.session = [[FSTParagonCookingSession alloc] init];
        self.session.activeRecipe = nil;
        
        //forcibly set the toBe cooking method to nil since we are just creating the paragon
        //object and there is not way it could exist yet
        self.session.toBeRecipe = nil;
        
        self.burners = [NSArray arrayWithObjects:[FSTBurner new], [FSTBurner new],[FSTBurner new],[FSTBurner new],[FSTBurner new], nil];
        
        requiredCharacteristics = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[[NSNumber alloc] initWithBool:0], FSTCharacteristicProbeConnectionState,[[NSNumber alloc] initWithBool:0], FSTCharacteristicBatteryLevel,
            [[NSNumber alloc] initWithBool:0], FSTCharacteristicBurnerStatus,
            [[NSNumber alloc] initWithBool:0], FSTCharacteristicCurrentTemperature,
            [[NSNumber alloc] initWithBool:0], FSTCharacteristicElapsedTime,
            [[NSNumber alloc] initWithBool:0], FSTCharacteristicTargetTemperature,
            [[NSNumber alloc] initWithBool:0], FSTCharacteristicCookTime,
            [[NSNumber alloc] initWithBool:0], FSTCharacteristicRecipeId,
                                   nil]; // booleans for all the required characteristics, tell us whether or not the characteristic loaded
        
        //TODO: Hack! we need an actual recipe
        [self handleRecipeId:nil];

    }

    return self;
}

-(void)dealloc
{
    [_readCharacteristicsTimer invalidate];
}

#pragma mark - External Interface Selectors

-(void)startHeatingWithStage: (FSTParagonCookingStage*)stage
{
    if (!stage)
    {
        DLog(@"no stage set when attempting to heat");
        return;
    }
    
    [self writeTargetTemperature:stage.targetTemperature];
}

-(void)setCookingTimesWithStage: (FSTParagonCookingStage*)stage
{
    if (!stage)
    {
        DLog(@"no stage set when attempting to send cooking times");
        return;
    }

    //must reset elapsed time to 0 before writing the cooktime
    [self writeElapsedTime];
    [self writeCookTimesWithMinimumCooktime:stage.cookTimeMinimum havingMaximumCooktime:stage.cookTimeMaximum];
    
    //now that we set everything, lets git rid of the stage
    stage = nil;
}

#pragma mark - Write Handlers

-(void)writeHandler: (CBCharacteristic*)characteristic
{
    [super writeHandler:characteristic];
    
    if([[[characteristic UUID] UUIDString] isEqualToString: FSTCharacteristicCookTime])
    {
        DLog(@"successfully wrote FSTCharacteristicCookTime");
        [self handleCooktimeWritten];
    }
    else if([[[characteristic UUID] UUIDString] isEqualToString: FSTCharacteristicElapsedTime])
    {
        [self handleElapsedTimeWritten];
        DLog(@"successfully wrote FSTCharacteristicElapsedTime");
    }
    else if([[[characteristic UUID] UUIDString] isEqualToString: FSTCharacteristicTargetTemperature])
    {
        DLog(@"successfully wrote FSTCharacteristicTargetTemperature");
        [self handleTargetTemperatureWritten];
    }
}

-(void)writeTargetTemperature: (NSNumber*)targetTemperature
{
    CBCharacteristic* characteristic = [self.characteristics objectForKey:FSTCharacteristicTargetTemperature];

    Byte bytes[2] ;
    OSWriteBigInt16(bytes, 0, [targetTemperature doubleValue]*100);
    NSData *data = [[NSData alloc]initWithBytes:bytes length:2];
    
    if (characteristic)
    {
        [self.peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }
    else
    {
        DLog(@"characteristic nil for writing target temperature");
    }
}

-(void)handleTargetTemperatureWritten
{
    [[NSNotificationCenter defaultCenter] postNotificationName:FSTTargetTemperatureSetNotification object:self];
}

-(void)writeCookTimesWithMinimumCooktime: (NSNumber*)minimumCooktime havingMaximumCooktime: (NSNumber*)maximumCooktime
{
    CBCharacteristic* characteristic = [self.characteristics objectForKey:FSTCharacteristicCookTime];
    
    if (characteristic && minimumCooktime && maximumCooktime)
    {
        Byte bytes[8] = {0x00};
        OSWriteBigInt16(bytes, 0, [minimumCooktime unsignedIntegerValue]);
        OSWriteBigInt16(bytes, 2, [maximumCooktime unsignedIntegerValue]);
        NSData *data = [[NSData alloc]initWithBytes:bytes length:8];
        [self.peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }
    else
    {
        DLog(@"could not write cook time to BLE device, missing a min or max cooktime");
    }
}

-(void)handleCooktimeWritten
{
    //read back the characteristic since there is no notification
    CBCharacteristic* cookTimeCharacteristic = [self.characteristics objectForKey:FSTCharacteristicCookTime];
    [self.peripheral readValueForCharacteristic:cookTimeCharacteristic];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FSTCookTimeSetNotification object:self];
}

-(void)writeElapsedTime
{
    CBCharacteristic* characteristic = [self.characteristics objectForKey:FSTCharacteristicElapsedTime];
    
    if (characteristic)
    {
        Byte bytes[2] = {0x00,0x00};
        NSData *data = [[NSData alloc]initWithBytes:bytes length:sizeof(bytes)];
        [self.peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }
    else
    {
        DLog(@"could not set elapsed time to 0 on BLE device, characteristic is empty");
    }
}

-(void)handleElapsedTimeWritten
{
    CBCharacteristic* elapsedTimeCharacteristic = [self.characteristics objectForKey:FSTCharacteristicElapsedTime];
    [self.peripheral readValueForCharacteristic:elapsedTimeCharacteristic];
    [[NSNotificationCenter defaultCenter] postNotificationName:FSTElapsedTimeSetNotification object:self];
}

#pragma mark - Read Handlers

-(void)readHandler: (CBCharacteristic*)characteristic
{
    [super readHandler:characteristic];
    
    if ([[[characteristic UUID] UUIDString] isEqualToString: FSTCharacteristicProbeFirmwareInfo])
    {
        //not implemented
    }
    else if([[[characteristic UUID] UUIDString] isEqualToString: FSTCharacteristicSpecialFeatures])
    {
        //not implemented
    }
    else if([[[characteristic UUID] UUIDString] isEqualToString: FSTCharacteristicErrorState])
    {
        //not implemented
    }
    else if([[[characteristic UUID] UUIDString] isEqualToString: FSTCharacteristicProbeConnectionState])
    {
        // set required dictionary to true for this key
        //characteristicStatusFlags.FSTCharacteristicProbeConnectionState = 1;
        [requiredCharacteristics setObject:[NSNumber numberWithBool:1] forKey:FSTCharacteristicProbeConnectionState];
        //not implemented
    }
    else if([[[characteristic UUID] UUIDString] isEqualToString: FSTCharacteristicBatteryLevel])
    {
        //characteristicStatusFlags.FSTCharacteristicBatteryLevel = 1;
        [requiredCharacteristics setObject:[NSNumber numberWithBool:1] forKey:FSTCharacteristicBatteryLevel];
        [self handleBatteryLevel:characteristic];
    }
    else if([[[characteristic UUID] UUIDString] isEqualToString: FSTCharacteristicBurnerStatus])
    {
        //characteristicStatusFlags.FSTCharacteristicBurnerStatus = 1;
        [requiredCharacteristics setObject:[NSNumber numberWithBool:1] forKey:FSTCharacteristicBurnerStatus];
        [self handleBurnerStatus:characteristic];
    }
    else if([[[characteristic UUID] UUIDString] isEqualToString: FSTCharacteristicElapsedTime])
    {
        //characteristicStatusFlags.FSTCharacteristicElapsedTime = 1;
        [requiredCharacteristics setObject:[NSNumber numberWithBool:1] forKey:FSTCharacteristicElapsedTime];
        [self handleElapsedTime:characteristic];
    }
    else if([[[characteristic UUID] UUIDString] isEqualToString: FSTCharacteristicTargetTemperature])
    {
        //characteristicStatusFlags.FSTCharacteristicTargetTemperature = 1;
        [requiredCharacteristics setObject:[NSNumber numberWithBool:1] forKey:FSTCharacteristicTargetTemperature];
        [self handleTargetTemperature:characteristic];
    }
    else if([[[characteristic UUID] UUIDString] isEqualToString: FSTCharacteristicCookTime])
    {
        //characteristicStatusFlags.FSTCharacteristicCookTime = 1;
        [requiredCharacteristics setObject:[NSNumber numberWithBool:1] forKey:FSTCharacteristicCookTime];
        [self handleCookTime:characteristic];
    }
    else if([[[characteristic UUID] UUIDString] isEqualToString:FSTCharacteristicCurrentTemperature])
    {
        //characteristicStatusFlags.FSTCharacteristicCurrentTemperature = 1;
        [requiredCharacteristics setObject:[NSNumber numberWithBool:1] forKey:FSTCharacteristicCurrentTemperature];
        [self handleCurrentTemperature:characteristic];
    }
    else if ([[[characteristic UUID] UUIDString] isEqualToString:FSTCharacteristicRecipeId])
    {
        [requiredCharacteristics setObject:[NSNumber numberWithBool:1] forKey:FSTCharacteristicRecipeId];
        [self handleRecipeId:characteristic];
    }// end all characteristic cases
    
    NSEnumerator* requiredEnum = [requiredCharacteristics keyEnumerator]; // count how many characteristics are ready
    NSInteger requiredCount = 0; // count the number of discovered characteristics
    for (NSString* characteristic in requiredEnum) {
        requiredCount += [(NSNumber*)[requiredCharacteristics objectForKey:characteristic] integerValue];
    }
    
    if (requiredCount == [requiredCharacteristics count] && self.initialCharacteristicValuesRead == NO) // found all required characteristics
    {
        //we haven't informed the application that the device is completely loaded, but we have
        //all the data we need
        self.initialCharacteristicValuesRead = YES;
        
        [self notifyDeviceReady]; // logic contained in notification center
        for (NSString* requiredCharacteristic in requiredCharacteristics)
        {
            CBCharacteristic* c =[self.characteristics objectForKey:requiredCharacteristic];
            if (c.properties & CBCharacteristicPropertyNotify)
            {
                [self.peripheral setNotifyValue:YES forCharacteristic:c ];
            }
        }
    }
    else if(self.initialCharacteristicValuesRead == NO)
    {
        //we don't have all the data yet...
        // calculate fraction
        double progressCount = [[NSNumber numberWithInt:(int)requiredCount] doubleValue];
        double progressTotal = [[NSNumber numberWithInt:(int)[requiredCharacteristics count]] doubleValue];
        self.loadingProgress = [NSNumber numberWithDouble: progressCount/progressTotal];
        
        [self notifyDeviceLoadProgressUpdated];
    }
    
#ifdef DEBUG
    if ([[[characteristic UUID] UUIDString] isEqualToString:FSTCharacteristicCurrentTemperature])
    {
        printf(".");
    }
    else
    {
        [self logParagon];
    }
#endif
    
    
} // end assignToProperty

-(void)handleRecipeId: (CBCharacteristic*)characteristic
{
    //TODO: implement with actual recipe id characteristic when we have that
//    if (characteristic.value.length != 1)
//    {
//        DLog(@"handleRecipeId length of %lu not what was expected, %d", (unsigned long)characteristic.value.length, 1);
//        return;
//    }
    
//    NSData *data = characteristic.value;
//    Byte bytes[characteristic.value.length] ;
//    [data getBytes:bytes length:characteristic.value.length];
//    self.recipeId = [NSNumber numberWithUnsignedInt:bytes[0]];
    
    //TODO: REMOVE ALL OF THIS!
    [requiredCharacteristics setObject:[NSNumber numberWithBool:1] forKey:FSTCharacteristicRecipeId];
    self.session.activeRecipe = [FSTRecipe new];
    self.session.previousStage = self.session.currentStage;
    self.session.currentStage = [self.session.activeRecipe addStage];
    ///////////////////////////
}

-(void)handleBatteryLevel: (CBCharacteristic*)characteristic
{
    if (characteristic.value.length != 1)
    {
        DLog(@"handleBatteryLevel length of %lu not what was expected, %d", (unsigned long)characteristic.value.length, 1);
        return;
    }
    
    NSData *data = characteristic.value;
    Byte bytes[characteristic.value.length] ;
    [data getBytes:bytes length:characteristic.value.length];
    self.batteryLevel = [NSNumber numberWithUnsignedInt:bytes[0]];
    
    //NSLog(@"FSTCharacteristicBatteryLevel: %@", self.batteryLevel );
    [[NSNotificationCenter defaultCenter] postNotificationName:FSTBatteryLevelChangedNotification  object:self];

}

-(void)handleElapsedTime: (CBCharacteristic*)characteristic
{
    if (characteristic.value.length != 2)
    {
        //DLog(@"handleElapsedTime length of %lu not what was expected, %d", (unsigned long)characteristic.value.length, 2);
        return;
    }
    
    if (self.session.currentStage)
    {
        NSData *data = characteristic.value;
        Byte bytes[characteristic.value.length] ;
        [data getBytes:bytes length:characteristic.value.length];
        uint16_t raw = OSReadBigInt16(bytes, 0);
        self.session.currentStageCookTimeElapsed = [[NSNumber alloc] initWithDouble:raw];
        [self determineCookMode];
        [[NSNotificationCenter defaultCenter] postNotificationName:FSTElapsedTimeChangedNotification object:self];
    }
}

-(void)handleBurnerStatus: (CBCharacteristic*)characteristic
{
    // TODO: - add direct cook detection
    if (characteristic.value.length != self.burners.count)
    {
        DLog(@"handleBurnerStatus length of %lu not what was expected, %lu", (unsigned long)characteristic.value.length, (unsigned long)self.burners.count);
        return;
    }
    
    //There are 5 burner statuses and and 5 bytes. Each byte is a status
    //the statuses are:
    //
    //Bit 7: 0 - Off, 1 - On
    //Bit 6: Normal / Sous Vide
    //Bit 5: 0 - Cook, 1 - Preheat
    //Bits 4-0: Burner PwrLevel
//    static const uint8_t BURNER_ON_OR_OFF_MASK = 0x80;
    static const uint8_t SOUS_VIDE_ON_OR_OFF_MASK = 0x40;
    static const uint8_t BURNER_PREHEAT_MASK = 0x20;
//    static const uint8_t BURNER_POWER_LEVEL_MASK = 0x1F;

//    //cook status
//    static const uint8_t COOK_STATUS_BIT = 5;
//    static const uint8_t COOK_STATUS_PREHEAT = 1;
//    
    //cook modes
//    static const uint8_t MODE_BIT = 6;
//    static const uint8_t MODE_NORMAL = 0;
    
    NSData *data = characteristic.value;
    Byte bytes[characteristic.value.length] ;
    [data getBytes:bytes length:characteristic.value.length];
    
    //loop through all burners (GE Cooktop)
    for (uint8_t burner = 0; burner < self.burners.count; burner++)
    {
        FSTBurner * currentBurner = (FSTBurner*)self.burners[burner];
        
        //figure out what mode the burner is
        if ((bytes[burner] & SOUS_VIDE_ON_OR_OFF_MASK) != SOUS_VIDE_ON_OR_OFF_MASK)
        {
            currentBurner.burnerMode = kPARAGON_OFF;
        }
        else
        {
            if((bytes[burner] & BURNER_PREHEAT_MASK) == BURNER_PREHEAT_MASK)
            {
                currentBurner.burnerMode = kPARAGON_PRECISION_REACHING_TEMPERATURE;
            }
            else
            {
                currentBurner.burnerMode = kPARAGON_PRECISION_HEATING;
            }
        }
    }
    
    //now go through each of the burners and see if we can find one that is not off
    //in order to set the overall burner mode (self.burnerMode)
    for (FSTBurner* burner in self.burners) {
        if (burner.burnerMode != kPARAGON_OFF )
        {
            self.burnerMode = burner.burnerMode;
            break;
        }
        else
        {
            self.burnerMode = kPARAGON_OFF;
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FSTBurnerModeChangedNotification object:self];
    [self determineCookMode];
}


-(void)determineCookMode
{
    //TODO: add direct cook
    
    ParagonCookMode currentCookMode = self.cookMode;
    
    if (self.burnerMode == kPARAGON_OFF)
    {
        self.cookMode = FSTParagonCookingStateOff;
    }
    else if (self.burnerMode == kPARAGON_PRECISION_REACHING_TEMPERATURE)
    {
        self.cookMode = FSTParagonCookingStatePrecisionCookingReachingTemperature;
        // TODO: this might cause the problem with precision cooking without time
    }
    else if (self.burnerMode == kPARAGON_PRECISION_HEATING)
    {
        if ([self.session.currentStageCookTimeElapsed doubleValue] > [self.session.currentStage.cookTimeMaximum doubleValue] && [self.session.currentStage.cookTimeMinimum doubleValue] > 0)
        {
            //elapsed time is greater than the maximum time
            self.cookMode = FSTParagonCookingStatePrecisionCookingPastMaxTime;
        }
        else if ([self.session.currentStageCookTimeElapsed doubleValue] >= [self.session.currentStage.cookTimeMinimum doubleValue] && [self.session.currentStage.cookTimeMinimum doubleValue] > 0)
        {
            //elapsed time is greater than the minimum time, but less than or equal to the max time
            //and the cookTime is set
            self.cookMode = FSTParagonCookingStatePrecisionCookingReachingMaxTime;
        }
        else if([self.session.currentStageCookTimeElapsed doubleValue] < [self.session.currentStage.cookTimeMinimum doubleValue] && [self.session.currentStage.cookTimeMinimum doubleValue] > 0)
        {
            //elapsed time is less than the minimum time and the cook time is set
            self.cookMode = FSTParagonCookingStatePrecisionCookingReachingMinTime;
        }
        else if (self.session.toBeRecipe)
        {
            //if we have a desired cooktime (not set yet) and none of the above cases are satisfied
            self.cookMode = FSTParagonCookingStatePrecisionCookingTemperatureReached;
        }
        else if([self.session.currentStage.cookTimeMinimum doubleValue] == 0 && !self.session.toBeRecipe)
        {
            //cook time not set
            self.cookMode = FSTParagonCookingStatePrecisionCookingWithoutTime;
        }
        else
        {
            self.cookMode = FSTParagonCookingStateUnknown;
            DLog(@"UNABLE TO DETERMINE COOK MODE");
        }
    }
    
    //only notify if we have changed cook modes
    if (self.cookMode != currentCookMode)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:FSTCookingModeChangedNotification object:self];
        
        //now if the cooking mode has changed to off lets reset the values by
        //writing them to the paragon
        if (self.cookMode == FSTParagonCookingStateOff)
        {
            [self writeElapsedTime];
            [self writeCookTimesWithMinimumCooktime:[NSNumber numberWithInt:0] havingMaximumCooktime:[NSNumber numberWithInt:0]];
        }
    }

}


-(void)handleTargetTemperature: (CBCharacteristic*)characteristic
{
    if (characteristic.value.length != 2)
    {
        DLog(@"handleTargetTemperature length of %lu not what was expected, %d", (unsigned long)characteristic.value.length, 2);
        return;
    }
    
    if (self.session.currentStage)
    {
        NSData *data = characteristic.value;
        Byte bytes[characteristic.value.length] ;
        [data getBytes:bytes length:characteristic.value.length];
        uint16_t raw = OSReadBigInt16(bytes, 0);
        self.session.currentStage.targetTemperature = [[NSNumber alloc] initWithDouble:raw/100];
        [[NSNotificationCenter defaultCenter] postNotificationName:FSTTargetTemperatureChangedNotification object:self];
    }
}

-(void)handleCookTime: (CBCharacteristic*)characteristic
{
    if (characteristic.value.length != 8)
    {
        DLog(@"handleCookTime length of %lu not what was expected, %d", (unsigned long)characteristic.value.length, 8);
        return;
    }
    
    if (self.session.currentStage)
    {
        NSData *data = characteristic.value;
        Byte bytes[characteristic.value.length] ;
        [data getBytes:bytes length:8];
        
        uint16_t minimumTime = OSReadBigInt16(bytes, 0);
        uint16_t maximumTime = OSReadBigInt16(bytes, 2);
        self.session.currentStage.cookTimeMinimum = [[NSNumber alloc] initWithDouble:minimumTime];
        self.session.currentStage.cookTimeMaximum = [[NSNumber alloc] initWithDouble:maximumTime];
        [self determineCookMode];
        [[NSNotificationCenter defaultCenter] postNotificationName:FSTCookTimeSetNotification object:self];
    }
}

-(void)handleCurrentTemperature: (CBCharacteristic*)characteristic
{
    if (characteristic.value.length != 2)
    {
        DLog(@"handleCurrentTemperature length of %lu not what was expected, %d", (unsigned long)characteristic.value.length, 2);
        return;
    }
    
    if (self.session.currentStage)
    {
        NSData *data = characteristic.value;
        Byte bytes[characteristic.value.length] ;
        [data getBytes:bytes length:characteristic.value.length];
        uint16_t raw = OSReadBigInt16(bytes, 0);
        self.session.currentProbeTemperature = [[NSNumber alloc] initWithDouble:raw/100];
        [[NSNotificationCenter defaultCenter] postNotificationName:FSTActualTemperatureChangedNotification object:self];
    }
}

#pragma mark - Characteristic Discovery Handler

-(void)handleDiscoverCharacteristics: (NSArray*)characteristics
{
    [super handleDiscoverCharacteristics:characteristics];
    
    self.initialCharacteristicValuesRead = NO;
    [requiredCharacteristics setObject:[NSNumber numberWithBool:0] forKey:FSTCharacteristicProbeConnectionState];
    [requiredCharacteristics setObject:[NSNumber numberWithBool:0] forKey:FSTCharacteristicBatteryLevel];
    [requiredCharacteristics setObject:[NSNumber numberWithBool:0] forKey:FSTCharacteristicBurnerStatus];
    [requiredCharacteristics setObject:[NSNumber numberWithBool:0] forKey:FSTCharacteristicCurrentTemperature];
    [requiredCharacteristics setObject:[NSNumber numberWithBool:0] forKey:FSTCharacteristicElapsedTime];
    [requiredCharacteristics setObject:[NSNumber numberWithBool:0] forKey:FSTCharacteristicTargetTemperature];
    [requiredCharacteristics setObject:[NSNumber numberWithBool:0] forKey:FSTCharacteristicCookTime];
    NSLog(@"=======================================================================");
    //NSLog(@"SERVICE %@", [service.UUID UUIDString]);
    
    for (CBCharacteristic *characteristic in characteristics)
    {
        [self.characteristics setObject:characteristic forKey:[characteristic.UUID UUIDString]];
        NSLog(@"    CHARACTERISTIC %@", [characteristic.UUID UUIDString]);
        
        if (characteristic.properties & CBCharacteristicPropertyWrite)
        {
            NSLog(@"        CAN WRITE");
        }
        
        if (characteristic.properties & CBCharacteristicPropertyNotify)
        {
            if  (
                 [[[characteristic UUID] UUIDString] isEqualToString: FSTCharacteristicBatteryLevel] ||
                 [[[characteristic UUID] UUIDString] isEqualToString: FSTCharacteristicBurnerStatus] ||
                 [[[characteristic UUID] UUIDString] isEqualToString: FSTCharacteristicCurrentTemperature] ||
                 [[[characteristic UUID] UUIDString] isEqualToString: FSTCharacteristicElapsedTime] ||
                 [[[characteristic UUID] UUIDString] isEqualToString: FSTCharacteristicProbeConnectionState] ||
                 [[[characteristic UUID] UUIDString] isEqualToString: FSTCharacteristicTargetTemperature]
                 )
            {
                [self.peripheral readValueForCharacteristic:characteristic];
            }
            NSLog(@"        CAN NOTIFY");
        }
        
        if (characteristic.properties & CBCharacteristicPropertyRead)
        {
            if([[[characteristic UUID] UUIDString] isEqualToString: FSTCharacteristicCookTime])
            {
                [self.peripheral readValueForCharacteristic:characteristic];
            }
            NSLog(@"        CAN READ");
        }
        
        if (characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse)
        {
            NSLog(@"        CAN WRITE WITHOUT RESPONSE");
        }
    }
}

#ifdef DEBUG
-(void)logParagon
{
    FSTParagonCookingStage* currentStage = self.session.currentStage;
    FSTParagonCookingStage* toBeStage = self.session.toBeRecipe.paragonCookingStages[0];
    NSLog(@"------PARAGON-------");
    NSLog(@"bmode %d, cmode %d, curtmp %@, stage %@, elapt %@", self.burnerMode, self.cookMode, self.session.currentProbeTemperature, self.session.currentStage, self.session.currentStageCookTimeElapsed);
    NSLog(@"\tACTIVE RECIPE : tartmp %@, mint %@, maxt %@", currentStage.targetTemperature, currentStage.cookTimeMinimum, currentStage.cookTimeMaximum);
    if (toBeStage)
    {
        NSLog(@"\t  TOBE RECIPE: tartmp %@, mint %@, maxt %@", toBeStage.targetTemperature, toBeStage.cookTimeMinimum, toBeStage.cookTimeMaximum);
    }
    else
    {
        NSLog(@"\t TOBE RECIPE : not set");
    }
    
}
#endif

@end