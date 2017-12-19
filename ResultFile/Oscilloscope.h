#ifndef OSCILLOSCOPE_H
#define OSCILLOSCOPE_H

enum 
{
  AM_OSCILLOSCOPE = 0x93,
};
/*
typedef nx_struct oscilloscope 
{
  nx_uint16_t version; //Version of the interval. 
  nx_uint16_t interval; // Samping period. 
  nx_uint16_t id; // Mote id of sending mote
  nx_uint16_t count; // The readings are samples count * NREADINGS onwards 
  nx_uint16_t temperature;
  nx_uint16_t humidity;
  nx_uint16_t light;
  nx_uint32_t current_time;
  nx_uint32_t token;
} oscilloscope_t;*/

typedef nx_struct SensorMsg {
  nx_uint16_t node_id;
  nx_uint16_t sequence_number;
  nx_uint16_t temperature;
  nx_uint16_t humidity;
  nx_uint16_t light_intensity;
} SensorMsg;

#endif
