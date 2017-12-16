#ifndef SENSOR_H
#define SENSOR_H

#define BLINK_DURATION 10
#define TIMER_PERIOD_MILLI 50
#define AM_SENSOR_TO_SENSOR 6
#define AM_SENSOR_TO_BASE 7

typedef nx_struct SensorMsg {
	nx_uint16_t node_id;
	nx_uint16_t sequence_number;
	nx_uint16_t temperature;
	nx_uint16_t humidity;
	nx_uint16_t light_intensity;
} SensorMsg;

#endif