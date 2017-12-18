#ifndef BASE_H
#define BASE_H

#define BLINK_DURATION 10
#define TIMER_PERIOD_MILLI 100
#define AM_SENSOR_TO_SENSOR 6
#define AM_BASE_TO_SENSORS 10

enum {
    RADIO_QUEUE_LEN = 12,
 };

typedef nx_struct SensorMsg {
	nx_uint16_t node_id;
	nx_uint16_t sequence_number;
	nx_uint16_t temperature;
	nx_uint16_t humidity;
	nx_uint16_t light_intensity;
} SensorMsg;

typedef nx_struct FreqMsg {
	nx_uint16_t freq;
} FreqMsg;

#endif