#include <Wire.h>
#include "MAX30105.h"
#include "spo2_algorithm.h"
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

MAX30105 particleSensor;

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;

uint32_t irBuffer[100];
uint32_t redBuffer[100];
int32_t bufferLength;
int32_t spo2;
int8_t validSPO2;
int32_t heartRate;
int8_t validHeartRate;

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
    };
    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      BLEDevice::startAdvertising();
    }
};

void setup() {
  Serial.begin(115200);
  BLEDevice::init("ESP32_Pulse");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_NOTIFY
                    );
  pCharacteristic->addDescriptor(new BLE2902());
  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);
  BLEDevice::startAdvertising();
  Serial.println("BLE Started!");

  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("MAX30105 not found.");
    while (1);
  }
  
  particleSensor.setup(60, 4, 2, 100, 411, 4096); 
}

void loop() {
  bufferLength = 100; 
  for (byte i = 0 ; i < bufferLength ; i++) {
    while (particleSensor.available() == false) 
      particleSensor.check(); 
    redBuffer[i] = particleSensor.getRed();
    irBuffer[i] = particleSensor.getIR();
    particleSensor.nextSample(); 
  }

  maxim_heart_rate_and_oxygen_saturation(irBuffer, bufferLength, redBuffer, &spo2, &validSPO2, &heartRate, &validHeartRate);

  while (1) {
    // Dump first 25, shift last 75
    for (byte i = 25; i < 100; i++) {
      redBuffer[i - 25] = redBuffer[i];
      irBuffer[i - 25] = irBuffer[i];
    }
    // Take 25 new samples
    for (byte i = 75; i < 100; i++) {
      while (particleSensor.available() == false) 
        particleSensor.check(); 

      redBuffer[i] = particleSensor.getRed();
      irBuffer[i] = particleSensor.getIR();
      particleSensor.nextSample(); 
    }
    maxim_heart_rate_and_oxygen_saturation(irBuffer, bufferLength, redBuffer, &spo2, &validSPO2, &heartRate, &validHeartRate);

    if (deviceConnected) {
      if (validHeartRate && validSPO2 && heartRate > 40 && heartRate < 200) {
        
        int Sys = 110 + (heartRate - 60) * 0.5; 
        int Dia = 70 + (heartRate - 60) * 0.3;
        
        String data = String(heartRate) + "," + String(spo2) + "," + String(Sys) + "," + String(Dia);
        pCharacteristic->setValue(data.c_str());
        pCharacteristic->notify();
      } 
      else {
         pCharacteristic->setValue("0,0,0,0");
         pCharacteristic->notify();
      }
    }
  }
}
