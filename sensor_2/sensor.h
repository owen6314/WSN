#ifndef SENSOR_H
#define SENSOR_H

enum {
	TIMER_PERIOD_MILLI = 500,
    RADIO_QUEUE_LEN = 12,
    AM_SENSOR2_TO_SENSOR1 = 6
 };

typedef nx_struct SensorMsg 
{
	nx_uint16_t node_id;
	nx_uint16_t sequence_number;
	nx_uint16_t temperature;
	nx_uint16_t humidity;
	nx_uint16_t light_intensity;
	nx_uint32_t current_time;
} SensorMsg;

typedef nx_struct FreqMsg {
	nx_uint16_t period;
} FreqMsg;

#endif