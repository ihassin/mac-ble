//
//  Manager.m
//  mac-ble
//
//  Created by Itamar Hassin on 12/25/17.
//  Copyright © 2017 Itamar Hassin. All rights reserved.
//
@import CoreBluetooth;

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
        [_centralManager scanForPeripheralsWithServices:nil options:nil];
        _running = true;
    }
    return self;
}

// method called whenever the device state changes.
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    CBManagerState state = [_centralManager state];
    
    // Determine the state of the peripheral
    if (state == CBManagerStatePoweredOff) {
        NSLog(@"CoreBluetooth BLE hardware is powered off");
    } else if (state == CBManagerStatePoweredOn) {
        NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
        // Scan for all available CoreBluetooth LE devices
        NSArray *services = @[[CBUUID UUIDWithString:@"FF02"]];
        [_centralManager scanForPeripheralsWithServices:services options:nil];
    } else if (state == CBManagerStateUnauthorized) {
        NSLog(@"CoreBluetooth BLE state is unauthorized");
    } else if (state == CBManagerStateUnknown) {
        NSLog(@"CoreBluetooth BLE state is unknown");
    } else if (state == CBManagerStateUnsupported) {
        NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
    }
}

// CBCentralManagerDelegate - This is called with the CBPeripheral class as its main input parameter. This contains most of the information there is to know about a BLE peripheral.
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if(![_peripherals containsObject:peripheral])
    {
        [_peripherals addObject:peripheral];
    }
    [central stopScan];
    
    NSLog(@"didDiscoverPeripheral {%@}", peripheral.name);
    NSLog(@"description {%@}", peripheral.description);
    NSLog(@"ad: {%@}", advertisementData);
    NSLog(@"RSSI: {%@}", RSSI);
    
    [central connectPeripheral:peripheral options:nil];
}

// method called whenever you have successfully connected to the BLE peripheral
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    //    if(![self.peripherals containsObject:peripheral])
    //    {
    //        [self.peripherals addObject:peripheral];
    //    }
    NSLog(@"didConnectPeripheral");
    
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
}

// method called whenever you have successfully connected to the BLE peripheral
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error
{
    NSLog(@"disconnectedConnectPeripheral");
    [_peripherals removeObject:peripheral];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error
{
    NSLog(@"didFailToConnectPeripheral");
}

#pragma mark - CBPeripheralDelegate

// Invoked when you read RSSI
- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(nonnull NSNumber *)RSSI error:(nullable NSError *)error
{
    NSLog(@"RSSI: %@", RSSI);
}

// CBPeripheralDelegate - Invoked when you discover the peripheral's available services.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"didDiscoverServices");
    NSLog(@"services: {%@}", peripheral.services);
    [peripheral discoverCharacteristics:nil forService:peripheral.services[0]];
}

// Invoked when you discover the characteristics of a specified service.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"didDiscoverCharacteristicsForService");
    NSLog(@"services: {%@}", service.characteristics);
    
    CBCharacteristic *cbC = service.characteristics[5];
    
    unsigned char bytes[] = {0x0, 0, 0, 255};
    NSData *data = [NSData dataWithBytes:bytes length:4];
    
    [peripheral writeValue:data forCharacteristic:cbC
                      type:CBCharacteristicWriteWithoutResponse];
    
    sleep(1);
    [_centralManager cancelPeripheralConnection:peripheral];
    _running = false;
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
