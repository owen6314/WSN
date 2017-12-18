#ifndef SENSOR_H
#define SENSOR_H

#define BLINK_DURATION 10
#define TIMER_PERIOD_MILLI 500
#define AM_SENSOR2_TO_SENSOR1 97
#define AM_SENSOR1_TO_BASE 19

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
	nx_uint16_t period;
} FreqMsg;

#endif