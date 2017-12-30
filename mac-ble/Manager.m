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
    
    NSLog(@"Discovered peripheral %@ %@", peripheral.name, peripheral.identifier.UUIDString);
    
    [_peripherals addObject:peripheral];
    
    NSLog(@"Trying to connect to %@.", peripheral.name);
    [central connectPeripheral:peripheral options:nil];

}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Connected to peripheral %@ with id %@", peripheral.name, peripheral.identifier.UUIDString);
    
    [peripheral setDelegate:self];
    CBUUID *uid = [CBUUID UUIDWithString:@"ff02"];
    [peripheral discoverServices:@[uid]];
}

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

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    CBUUID *uid = [CBUUID UUIDWithString:@"fffb"];
    for (CBService * object in peripheral.services) {
        [peripheral discoverCharacteristics:@[uid] forService:object];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    for (CBCharacteristic *characteristic in service.characteristics) {
        [peripheral readValueForCharacteristic:characteristic];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error;
{
    NSLog(@"Characteristic descriptors: %@", characteristic.descriptors);
}

// Invoked when characteristic are read or have changed
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"Characteristic: %@ %@", characteristic.UUID.UUIDString, characteristic.value);

//    For 0xfffc                Sat    R     G     B
//    unsigned char bytes[] = { 0x00, 0xff, 0x00, 0x00 };

    // For 0xffb              Sat    R     G     B    Mode   MBZ  Speed  MBZ
    unsigned char bytes[] = { 0x00, 0x00, 0x00, 0x00, 0x03, 0x00, 0x15, 0x00 };
    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];

    if(![data isEqual:characteristic.value])
    {
        NSLog(@"Setting value");
        [peripheral writeValue:data forCharacteristic:characteristic
                          type:CBCharacteristicWriteWithoutResponse];
        
        [NSThread sleepForTimeInterval:0.2028f];
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
