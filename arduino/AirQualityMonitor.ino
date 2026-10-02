// Air Quality System + Bluetooth LE JSON + LCD Real-Time Values
// VERSION: BLE_ONLY_AQI_CARBON_PM25_TVOC_FINAL
// Board: Arduino Uno R4 WiFi
//
// This version uses Bluetooth Low Energy (BLE), NOT WiFi.
//
// The Arduino becomes a BLE peripheral named:
// AirQualityMonitor
//
// The phone / Qt app connects over BLE, reads/subscribes to the JSON characteristic,
// then the app can forward the JSON to your Qt server.
//
// BLE JSON format:
//
// {
//   "AQI": 12,
//   "Carbon_LEVEL": 421,
//   "PM25": 0.0,
//   "TVOC_level": 0
// }
//
// Switch wiring:
// Middle leg   -> D4
// One side leg -> GND
// Other side   -> leave unconnected
//
// Because this code uses INPUT_PULLUP:
// Switch ON  = D4 connected to GND = LOW
// Switch OFF = D4 not connected to GND = HIGH
//
// Wiring:
// MQ sensor      -> A0
// CJMCU-1100     -> A1
// Dust sensor    -> A2
// Dust LED pin   -> D2
// 3-leg switch   -> D4 and GND
// SGP30 VIN/VCC  -> 3.3V or 5V depending on your breakout board
// SGP30 GND      -> GND
// SGP30 SDA      -> A4 / SDA
// SGP30 SCL      -> A5 / SCL
// LCD VCC        -> 5V
// LCD GND        -> GND
// LCD SDA        -> A4 / SDA
// LCD SCL        -> A5 / SCL
//
// Required libraries:
// 1. ArduinoBLE
// 2. ArduinoJson
// 3. Adafruit SGP30 Sensor
// 4. Adafruit BusIO
// 5. Grove LCD RGB Backlight / rgb_lcd

#include <Wire.h>
#include <ArduinoBLE.h>
#include <ArduinoJson.h>
#include <Adafruit_SGP30.h>
#include <rgb_lcd.h>

// -------------------- BLE Settings --------------------
BLEService airQualityService("19B10000-E8F2-537E-4F6C-D104768A1214");

BLEStringCharacteristic airQualityJsonCharacteristic(
  "19B10001-E8F2-537E-4F6C-D104768A1214",
  BLERead | BLENotify,
  220
);

// Send BLE JSON every 5 seconds while the switch is ON.
const unsigned long BLE_SEND_INTERVAL = 5000UL;

// Change LCD page every 2 seconds.
const unsigned long LCD_PAGE_INTERVAL = 2000UL;

// Print a heartbeat when switch is OFF.
const unsigned long SERIAL_HEARTBEAT_INTERVAL = 3000UL;

// -------------------- Accuracy / Calibration Settings --------------------
const int ADC_BITS = 12;
const float ADC_MAX_VALUE = 4095.0;
const float ADC_REF_VOLTAGE = 5.0;

const int ANALOG_SAMPLE_COUNT = 10;
const int DUST_SAMPLE_COUNT = 10;

// GP2Y1010-style dust sensor.
// Typical no-dust output: around 0.9 V.
// Sensitivity: 0.5 V per 0.1 mg/m3 = 5.0 V per 1.0 mg/m3.
const float DEFAULT_DUST_ZERO_VOLTAGE = 0.90;
const float DUST_SENSITIVITY_V_PER_MG_M3 = 5.0;

// Keep this true if the device starts in clean air.
// Set false if you are testing near smoke/dust during startup.
const bool AUTO_CALIBRATE_DUST_ZERO = true;

float dustZeroVoltage = DEFAULT_DUST_ZERO_VOLTAGE;

// -------------------- Device Info --------------------
String deviceId = "";

// -------------------- Sensor / LCD Objects --------------------
Adafruit_SGP30 sgp;
rgb_lcd lcd;

// -------------------- Sensor Pins --------------------
const int MQ_ANALOG_PIN = A0;
const int CJMCU_ANALOG_PIN = A1;
const int DUST_ANALOG_PIN = A2;
const int DUST_LED_PIN = 2;
const int SWITCH_PIN = 4;

// -------------------- Sensor Values --------------------
float mqRaw = 0.0;
float cjRaw = 0.0;
float dustRaw = 0.0;

float mqVoltage = 0.0;
float cjVoltage = 0.0;
float dustVoltage = 0.0;
float dustDensity = 0.0; // mg/m3 estimate from dust sensor

uint16_t sgpTVOC = 0;   // ppb
uint16_t sgpECO2 = 400; // ppm, equivalent CO2 from SGP30
bool sgpReady = false;

// -------------------- Timing --------------------
bool lastSystemState = false;
unsigned long lastBLESentTime = 0;
unsigned long lastLCDPageChangeTime = 0;
unsigned long lastSerialHeartbeatTime = 0;

int lcdPage = 0;
const int TOTAL_LCD_PAGES = 4;

void setup() {
  Serial.begin(9600);
  delay(2000);

  pinMode(DUST_LED_PIN, OUTPUT);
  pinMode(SWITCH_PIN, INPUT_PULLUP);

  digitalWrite(DUST_LED_PIN, HIGH);

  analogReadResolution(ADC_BITS);

  Wire.begin();

  setupLCD();
  showStartupScreen();

  Serial.println("Air Quality System Ready");
  Serial.println("VERSION: BLE_ONLY_AQI_CARBON_PM25_TVOC_FINAL");
  Serial.println("Flip switch to turn system ON");
  Serial.println();

  setupSGP30();

  if (AUTO_CALIBRATE_DUST_ZERO) {
    calibrateDustZero();
  }

  lcd.clear();
  lcd.setRGB(255, 255, 0);
  lcd.setCursor(0, 0);
  lcd.print("Starting BLE");
  lcd.setCursor(0, 1);
  lcd.print("Please wait...");

  setupBluetooth();

  showSystemOffScreen();
}

void loop() {
  BLE.poll();

  bool systemOn = isSwitchOn();

  if (systemOn != lastSystemState) {
    if (systemOn) {
      handleSystemTurnedOn();
    } else {
      handleSystemTurnedOff();
    }

    lastSystemState = systemOn;
  }

  if (systemOn) {
    readSensors();
    printToSerial();
    updateLCDRealTimeValues();

    if (millis() - lastBLESentTime >= BLE_SEND_INTERVAL) {
      sendToBluetooth();
      lastBLESentTime = millis();
    }
  } else {
    digitalWrite(DUST_LED_PIN, HIGH);
    printOffHeartbeat();
  }

  delay(1000);
}

bool isSwitchOn() {
  return digitalRead(SWITCH_PIN) == LOW;
}

void printOffHeartbeat() {
  if (millis() - lastSerialHeartbeatTime >= SERIAL_HEARTBEAT_INTERVAL) {
    Serial.println("Sketch running. System is OFF. Flip switch ON to read sensors.");
    Serial.print("BLE device name: ");
    Serial.println("AirQualityMonitor");
    Serial.print("BLE device ID: ");
    Serial.println(deviceId);
    Serial.println();

    lastSerialHeartbeatTime = millis();
  }
}

void handleSystemTurnedOn() {
  Serial.println("System ON");
  Serial.println();

  lastBLESentTime = 0;
  lcdPage = 0;
  lastLCDPageChangeTime = 0;

  lcd.clear();
  lcd.setRGB(255, 255, 0);
  lcd.setCursor(0, 0);
  lcd.print("System ON");
  lcd.setCursor(0, 1);
  lcd.print("Reading...");
}

void handleSystemTurnedOff() {
  Serial.println("System OFF");
  Serial.println();

  digitalWrite(DUST_LED_PIN, HIGH);
  showSystemOffScreen();
}

void setupLCD() {
  lcd.begin(16, 2);
  lcd.setRGB(0, 0, 255);

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Air Quality");
  lcd.setCursor(0, 1);
  lcd.print("Starting...");
}

void showStartupScreen() {
  lcd.clear();
  lcd.setRGB(0, 0, 255);
  lcd.setCursor(0, 0);
  lcd.print("Air Quality");
  lcd.setCursor(0, 1);
  lcd.print("Starting...");
  delay(1000);
}

void showSystemOffScreen() {
  lcd.clear();
  lcd.setRGB(0, 0, 255);
  lcd.setCursor(0, 0);
  lcd.print("System OFF");
  lcd.setCursor(0, 1);
  lcd.print("Flip switch ON");
}

void setupBluetooth() {
  if (!BLE.begin()) {
    Serial.println("ERROR: Failed to start BLE!");

    lcd.clear();
    lcd.setRGB(255, 0, 0);
    lcd.setCursor(0, 0);
    lcd.print("BLE Failed");
    lcd.setCursor(0, 1);
    lcd.print("Check board");

    while (true);
  }

  BLE.setLocalName("AirQualityMonitor");
  BLE.setDeviceName("AirQualityMonitor");

  BLE.setAdvertisedService(airQualityService);

  airQualityService.addCharacteristic(airQualityJsonCharacteristic);
  BLE.addService(airQualityService);

  deviceId = BLE.address();

  if (deviceId.length() == 0) {
    deviceId = "unknown_ble_device";
  }

  airQualityJsonCharacteristic.writeValue(makeJsonPayload());

  BLE.advertise();

  Serial.println("BLE started!");
  Serial.print("BLE Device Name: ");
  Serial.println("AirQualityMonitor");

  Serial.print("BLE Device ID / Address: ");
  Serial.println(deviceId);

  Serial.println("BLE Service UUID:");
  Serial.println("19B10000-E8F2-537E-4F6C-D104768A1214");

  Serial.println("BLE JSON Characteristic UUID:");
  Serial.println("19B10001-E8F2-537E-4F6C-D104768A1214");
  Serial.println();

  lcd.clear();
  lcd.setRGB(0, 255, 0);
  lcd.setCursor(0, 0);
  lcd.print("BLE Ready");
  lcd.setCursor(0, 1);
  lcd.print("Pair in app");
  delay(2000);
}

void setupSGP30() {
  Serial.println("Starting SGP30 sensor...");

  if (!sgp.begin()) {
    Serial.println("ERROR: SGP30 not found. Check SDA/SCL wiring.");
    sgpReady = false;

    lcd.clear();
    lcd.setRGB(255, 165, 0);
    lcd.setCursor(0, 0);
    lcd.print("SGP30 Error");
    lcd.setCursor(0, 1);
    lcd.print("Check wiring");
    delay(2000);

    return;
  }

  sgpReady = true;

  Serial.println("SGP30 found!");
  Serial.print("SGP30 serial number: ");
  Serial.print(sgp.serialnumber[0], HEX);
  Serial.print(sgp.serialnumber[1], HEX);
  Serial.println(sgp.serialnumber[2], HEX);
  Serial.println();
}

float readAnalogAverage(int pin, int samples) {
  float total = 0.0;

  for (int i = 0; i < samples; i++) {
    total += analogRead(pin);
    delay(2);
  }

  return total / samples;
}

void readSensors() {
  mqRaw = readAnalogAverage(MQ_ANALOG_PIN, ANALOG_SAMPLE_COUNT);
  cjRaw = readAnalogAverage(CJMCU_ANALOG_PIN, ANALOG_SAMPLE_COUNT);

  mqVoltage = mqRaw * (ADC_REF_VOLTAGE / ADC_MAX_VALUE);
  cjVoltage = cjRaw * (ADC_REF_VOLTAGE / ADC_MAX_VALUE);

  readDustSensor();
  readSGP30();
}

void readSGP30() {
  if (!sgpReady) {
    sgpTVOC = 0;
    sgpECO2 = 400;
    return;
  }

  if (!sgp.IAQmeasure()) {
    Serial.println("ERROR: SGP30 reading failed.");
    return;
  }

  sgpTVOC = sgp.TVOC;
  sgpECO2 = sgp.eCO2;
}

float readDustRawOnce() {
  digitalWrite(DUST_LED_PIN, LOW);
  delayMicroseconds(280);

  float raw = analogRead(DUST_ANALOG_PIN);

  delayMicroseconds(40);
  digitalWrite(DUST_LED_PIN, HIGH);

  delayMicroseconds(9680);

  return raw;
}

void calibrateDustZero() {
  lcd.clear();
  lcd.setRGB(255, 255, 0);
  lcd.setCursor(0, 0);
  lcd.print("Calibrating");
  lcd.setCursor(0, 1);
  lcd.print("Dust zero...");

  Serial.println("Calibrating dust zero voltage. Keep sensor in clean air...");

  float totalRaw = 0.0;
  const int calibrationSamples = 30;

  for (int i = 0; i < calibrationSamples; i++) {
    totalRaw += readDustRawOnce();
  }

  float avgRaw = totalRaw / calibrationSamples;
  float measuredZeroVoltage = avgRaw * (ADC_REF_VOLTAGE / ADC_MAX_VALUE);

  if (measuredZeroVoltage >= 0.3 && measuredZeroVoltage <= 1.5) {
    dustZeroVoltage = measuredZeroVoltage;
  } else {
    dustZeroVoltage = DEFAULT_DUST_ZERO_VOLTAGE;
  }

  Serial.print("Dust zero voltage set to: ");
  Serial.print(dustZeroVoltage, 3);
  Serial.println(" V");

  lcd.clear();
  lcd.setRGB(0, 255, 0);
  lcd.setCursor(0, 0);
  lcd.print("Dust Zero:");
  lcd.setCursor(0, 1);
  lcd.print(dustZeroVoltage, 3);
  lcd.print(" V");
  delay(1500);
}

void readDustSensor() {
  float totalRaw = 0.0;

  for (int i = 0; i < DUST_SAMPLE_COUNT; i++) {
    totalRaw += readDustRawOnce();
  }

  dustRaw = totalRaw / DUST_SAMPLE_COUNT;
  dustVoltage = dustRaw * (ADC_REF_VOLTAGE / ADC_MAX_VALUE);

  dustDensity = (dustVoltage - dustZeroVoltage) / DUST_SENSITIVITY_V_PER_MG_M3;

  if (dustDensity < 0.0) {
    dustDensity = 0.0;
  }
}

float clampFloat(float value, float minValue, float maxValue) {
  if (value < minValue) {
    return minValue;
  }

  if (value > maxValue) {
    return maxValue;
  }

  return value;
}

int calculateAQIFromBreakpoint(float concentration, float cLow, float cHigh, int iLow, int iHigh) {
  float aqi = ((float)(iHigh - iLow) / (cHigh - cLow)) * (concentration - cLow) + iLow;
  return round(aqi);
}

int getDustAQI() {
  float pm25 = dustDensity * 1000.0;

  if (pm25 < 0.0) {
    pm25 = 0.0;
  }

  if (pm25 <= 9.0) {
    return calculateAQIFromBreakpoint(pm25, 0.0, 9.0, 0, 50);
  } else if (pm25 <= 35.4) {
    return calculateAQIFromBreakpoint(pm25, 9.1, 35.4, 51, 100);
  } else if (pm25 <= 55.4) {
    return calculateAQIFromBreakpoint(pm25, 35.5, 55.4, 101, 150);
  } else if (pm25 <= 125.4) {
    return calculateAQIFromBreakpoint(pm25, 55.5, 125.4, 151, 200);
  } else if (pm25 <= 225.4) {
    return calculateAQIFromBreakpoint(pm25, 125.5, 225.4, 201, 300);
  } else if (pm25 <= 325.4) {
    return calculateAQIFromBreakpoint(pm25, 225.5, 325.4, 301, 500);
  } else {
    return 500;
  }
}

String getDustAQIStatus() {
  int aqi = getDustAQI();

  if (aqi <= 50) {
    return "GOOD";
  } else if (aqi <= 100) {
    return "MODERATE";
  } else if (aqi <= 150) {
    return "SENSITIVE";
  } else if (aqi <= 200) {
    return "UNHEALTHY";
  } else if (aqi <= 300) {
    return "VERY BAD";
  } else {
    return "HAZARDOUS";
  }
}

String makeJsonPayload() {
  StaticJsonDocument<180> doc;

  // ONLY these four values are sent in the BLE JSON.
  doc["AQI"] = getDustAQI();
  doc["Carbon_LEVEL"] = sgpECO2;
  doc["PM25"] = dustDensity * 1000.0;
  doc["TVOC_level"] = sgpTVOC;

  String jsonData;
  serializeJson(doc, jsonData);

  return jsonData;
}

void updateLCDRealTimeValues() {
  int aqi = getDustAQI();

  if (aqi <= 50) {
    lcd.setRGB(0, 255, 0);
  } else if (aqi <= 100) {
    lcd.setRGB(255, 255, 0);
  } else {
    lcd.setRGB(255, 0, 0);
  }

  if (millis() - lastLCDPageChangeTime >= LCD_PAGE_INTERVAL) {
    lcdPage = (lcdPage + 1) % TOTAL_LCD_PAGES;
    lastLCDPageChangeTime = millis();
  }

  lcd.clear();

  if (lcdPage == 0) {
    lcd.setCursor(0, 0);
    lcd.print("AQI:");
    lcd.print(getDustAQI());

    lcd.setCursor(0, 1);
    lcd.print(getDustAQIStatus());
  } 
  else if (lcdPage == 1) {
    lcd.setCursor(0, 0);
    lcd.print("Carbon:");
    lcd.print(sgpECO2);
    lcd.print("ppm");

    lcd.setCursor(0, 1);
    lcd.print("TVOC:");
    lcd.print(sgpTVOC);
    lcd.print("ppb");
  } 
  else if (lcdPage == 2) {
    lcd.setCursor(0, 0);
    lcd.print("PM25:");
    lcd.print(dustDensity * 1000.0, 1);

    lcd.setCursor(0, 1);
    lcd.print("ug/m3");
  }
  else if (lcdPage == 3) {
    lcd.setCursor(0, 0);
    lcd.print("BLE Ready");

    lcd.setCursor(0, 1);
    lcd.print("JSON every 5s");
  }
}

void printToSerial() {
  Serial.println("----- Air Quality Readings -----");

  Serial.print("BLE device ID: ");
  Serial.println(deviceId);

  Serial.print("AQI: ");
  Serial.println(getDustAQI());

  Serial.print("Carbon_LEVEL: ");
  Serial.println(sgpECO2);

  Serial.print("PM25: ");
  Serial.println(dustDensity * 1000.0, 2);

  Serial.print("TVOC_level: ");
  Serial.println(sgpTVOC);

  Serial.print("Dust Raw: ");
  Serial.println(dustRaw, 2);

  Serial.print("Dust Voltage: ");
  Serial.print(dustVoltage, 3);
  Serial.println(" V");

  Serial.print("Dust Zero Voltage: ");
  Serial.print(dustZeroVoltage, 3);
  Serial.println(" V");

  Serial.print("JSON: ");
  Serial.println(makeJsonPayload());

  Serial.println();
}

void sendToBluetooth() {
  String jsonData = makeJsonPayload();

  airQualityJsonCharacteristic.writeValue(jsonData);

  Serial.println("Sending BLE JSON:");
  Serial.println(jsonData);

  BLEDevice central = BLE.central();

  if (central) {
    Serial.print("Connected central: ");
    Serial.println(central.address());
  } else {
    Serial.println("No central connected yet. JSON is still available to read.");
  }

  Serial.println();
}
