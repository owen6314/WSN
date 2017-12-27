#ifndef SENSOR_H
#define SENSOR_H


enum {
	DEFAULT_VERSION = 1,
	DEFAULT_INTERVAL = 50,
    RADIO_QUEUE_LEN = 128,
    AM_SENSOR2_TO_SENSOR1 = 6,
    TOKEN = 0x6314,
 };

typedef nx_struct SensorMsg 
{
	nx_uint16_t token;
	nx_uint16_t version;
	nx_uint16_t interval;
	nx_uint16_t node_id;
	nx_uint16_t sequence_number;
	nx_uint16_t temperature;
	nx_uint16_t humidity;
	nx_uint16_t light_intensity;
	nx_uint32_t current_time;
} SensorMsg;

#endif