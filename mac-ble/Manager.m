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

- (void) scan
{
    // Scan for all available candles
    NSArray *services = @[[CBUUID UUIDWithString:@"FF02"]];
    if(![_centralManager isScanning]) {
        [_centralManager scanForPeripheralsWithServices:services options:nil];
    }
}

// method called whenever the device state changes.
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

// CBCentralManagerDelegate - This is called with the CBPeripheral class as its main input parameter. This contains most of the information there is to know about a BLE peripheral.
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if(![_peripherals containsObject:peripheral])
    {
        NSLog(@"Adding device to list");
        [_peripherals addObject:peripheral];
        NSLog(@"Discovered Peripheral {%@}", peripheral.name);
        NSLog(@"Advertisement Data: {%@}", advertisementData);
    }
    NSLog(@"description {%@}", peripheral.description);

    if([advertisementData valueForKey:@"kCBAdvDataIsConnectable"])
    {
        NSLog(@"Trying to connect to %@.", peripheral.name);
        [central connectPeripheral:peripheral options:nil];
    } else
    {
        NSLog(@"%@ is not accepting connections.", peripheral.name);
    }
}

// method called whenever you have successfully connected to the BLE peripheral
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Connected to Peripheral %@", peripheral.name);
    
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
}

// method called whenever you have successfully connected to the BLE peripheral
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error
{
    NSLog(@"Disconnected from %@", peripheral.name);
    [_peripherals removeObject:peripheral];
    _running = false;
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error
{
    NSLog(@"didFailToConnectPeripheral");
}

#pragma mark - CBPeripheralDelegate

// CBPeripheralDelegate - Invoked when you discover the peripheral's available services.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"Discovered Services for %@", peripheral.name);

    CBUUID *uid = [CBUUID UUIDWithString:@"fffc"];

    [peripheral discoverCharacteristics:@[uid] forService:peripheral.services[0]];
}

// Invoked when you discover the characteristics of a specified service.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"Discovered Characteristics For Service %@", service.UUID);
    
    _cbC = service.characteristics[0];

    unsigned char bytes[] = {0x0, 0, 0, 255};
    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];

    [peripheral writeValue:data forCharacteristic:_cbC
                      type:CBCharacteristicWriteWithoutResponse];

    sleep(1);
    NSLog(@"Disconnecting");
    [_centralManager cancelPeripheralConnection:peripheral];
}

// Invoked when you read RSSI
- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(nonnull NSNumber *)RSSI error:(nullable NSError *)error
{
    NSLog(@"RSSI: %@", RSSI);
}

// Invoked when you retrieve a specified characteristic's value, or when the peripheral device notifies your app that the characteristic's value has changed.
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"didUpdateValueForCharacteristic");
}

- (Boolean) running
{
    return(_running);
}

@end
