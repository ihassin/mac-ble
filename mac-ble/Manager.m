//
//  Manager.m
//  mac-ble
//
//  Created by Itamar Hassin on 12/25/17.
//  Copyright © 2017 Itamar Hassin. All rights reserved.
//
#import "Manager.h"

@interface Manager () <CBCentralManagerDelegate, CBPeripheralDelegate>
@end

@implementation Manager
{
    CBCentralManager *_centralManager;
    NSMutableArray *_peripherals;
    Boolean _running;
}

// Constructor
- (id) init
{
    self = [super init];
    if (self)
    {
        _peripherals = [[NSMutableArray alloc] init];
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        _running = true;
        [_centralManager scanForPeripheralsWithServices:nil options:nil];
    }
    return self;
}

// Start scanning for devices
- (void) scan
{
    // Scan for all available candles
    NSArray *services = @[[CBUUID UUIDWithString:@"FF02"]];
    if(![_centralManager isScanning]) {
        [_centralManager scanForPeripheralsWithServices:services options:nil];
    }
}

// Method called whenever the BLE state changes.
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    CBManagerState state = [_centralManager state];

    NSString *string = @"Unknown state";

    switch(state)
    {
        case CBManagerStatePoweredOff:
            string = @"CoreBluetooth BLE hardware is powered off.";
            break;
            
        case CBManagerStatePoweredOn:
            string = @"CoreBluetooth BLE hardware is powered on and ready.";
            break;
            
        case CBManagerStateUnauthorized:
            string = @"CoreBluetooth BLE state is unauthorized.";
            break;
            
        case CBManagerStateUnknown:
            string = @"CoreBluetooth BLE state is unknown.";
            break;
            
        case CBManagerStateUnsupported:
            string = @"CoreBluetooth BLE hardware is unsupported on this platform.";
            break;

        default:
            break;
    }
    NSLog(@"%@", string);
    }

// Called when a peripheral is discovered
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    CBUUID *service = [advertisementData valueForKey:@"kCBAdvDataServiceUUIDs"][0];
    Boolean isPlaybulb = [service.UUIDString isEqualToString:@"FF02"];
    
    if([_peripherals containsObject:peripheral])
    {
        NSLog(@"Skipping existing device.");
        return;
    }

    if(!isPlaybulb)
    {
        NSLog(@"Skipping non-bulb device.");
        return;
    }

    NSNumber *isConnectable = [advertisementData valueForKey:@"kCBAdvDataIsConnectable"];
    
    if(!isConnectable)
    {
        NSLog(@"Skipping device as it's not accepting connections.");
        return;
    }
    
    NSLog(@"Discovered peripheral %@", peripheral.name);
    NSLog(@"Advertisement Data: %@", advertisementData);
    
    [_peripherals addObject:peripheral];

    NSLog(@"Trying to connect to %@.", peripheral.name);
    [central connectPeripheral:peripheral options:nil];
}

// Called when connected to the BLE peripheral
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Connected to peripheral %@", peripheral.name);
    
    [peripheral setDelegate:self];
    CBUUID *uid = [CBUUID UUIDWithString:@"FF02"];
    [peripheral discoverServices:@[uid]];
}

// Method called whenever we disconnect from a peripheral
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error
{
    NSLog(@"Disconnected from %@", peripheral.name);
    [_peripherals removeObject:peripheral];
    if(_peripherals.count == 0)
    {
        NSLog(@"Ending loop");
        _running = false;
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error
{
    NSLog(@"didFailToConnectPeripheral");
}

#pragma mark - CBPeripheralDelegate

// CBPeripheralDelegate - Invoked when you discover the peripheral's available services.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"Discovered services for peripheral %@", peripheral.name);
    NSLog(@"Services: %@", peripheral.services);

//    CBUUID *uid = [CBUUID UUIDWithString:@"fffc"];
//    [peripheral discoverCharacteristics:@[uid] forService:peripheral.services[0]];

//    [peripheral discoverCharacteristics:nil forService:peripheral.services[0]];

    CBUUID *uid = [CBUUID UUIDWithString:@"fffc"];
    for (id object in peripheral.services) {
        NSLog(@"Service: %@", ((CBService *) object).UUID);
        [peripheral discoverCharacteristics:@[uid] forService:object];
    }
}

// Called when characteristics of a specified service are discovered
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"Discovered characteristics for peripheral %@ service %@", peripheral.name, service.UUID);

    for (CBCharacteristic *characteristic in service.characteristics) {
        [peripheral readValueForCharacteristic:characteristic];
    }

//    _cbC = service.characteristics[0];
//    unsigned char bytes[] = {0x0, 0, 0, 255};
//    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
//
//    [peripheral writeValue:data forCharacteristic:_cbC
//                      type:CBCharacteristicWriteWithoutResponse];
//
//    sleep(1);
//    NSLog(@"Disconnecting");
//    [_centralManager cancelPeripheralConnection:peripheral];
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error;
{
    NSLog(@"Characteristic descriptors: %@", characteristic.descriptors);
}

// Invoked when you retrieve a specified characteristic's value, or when the peripheral device notifies your app that the characteristic's value has changed.
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"Characteristic: %@ %@", characteristic.UUID.UUIDString, characteristic.value);

    unsigned char bytes[] = {0x0, 0, 0, 255};
    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];

    if(![data isEqual:characteristic.value])
    {
        NSLog(@"Setting value");
        [peripheral writeValue:data forCharacteristic:characteristic
                          type:CBCharacteristicWriteWithoutResponse];
        
        sleep(1);
    }
    [_centralManager cancelPeripheralConnection:peripheral];
}

// Invoked when you read RSSI
- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(nonnull NSNumber *)RSSI error:(nullable NSError *)error
{
    NSLog(@"RSSI: %@", RSSI);
}

- (Boolean) running
{
    return(_running);
}

@end
