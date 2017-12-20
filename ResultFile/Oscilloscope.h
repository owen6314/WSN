#ifndef OSCILLOSCOPE_H
#define OSCILLOSCOPE_H

enum 
{
  AM_OSCILLOSCOPE = 0x93,
};

typedef nx_struct SensorMsg {
  nx_uint16_t node_id;
  nx_uint16_t sequence_number;
  nx_uint16_t temperature;
  nx_uint16_t humidity;
  nx_uint16_t light_intensity;
} SensorMsg;

#endif
