#ifndef BASE_H
#define BASE_H

enum {
    RADIO_QUEUE_LEN = 30,
    UART_QUEUE_LEN = 30,
    // TODO:change these settings
    AM_SENSORMSG = 0x93, 
	AM_SENSOR_TO_SENSOR = 6,
	AM_BASE_TO_SENSORS = 10,
	AM_BASE_TO_PC = 11
 };

typedef nx_struct SensorMsg 
{
	nx_uint16_t version;  //包的版本
	nx_uint16_t interval; // 采样间隔
	nx_uint16_t node_id;  
	nx_uint16_t sequence_number;
	nx_uint16_t temperature;
	nx_uint16_t humidity;
	nx_uint16_t light_intensity;
	nx_uint32_t current_time;
} SensorMsg;



#endif