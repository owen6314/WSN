#ifndef OSCILLOSCOPE_H
#define OSCILLOSCOPE_H

enum 
{
  AM_SENSORMSG = 0x93,
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
