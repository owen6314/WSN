#ifndef OSCILLOSCOPE_H
#define OSCILLOSCOPE_H

enum 
{
  /* Number of readings per message. If you increase this, you may have to
     increase the message_t size. */
  NREADINGS = 1,
  DEFAULT_INTERVAL = 1000,
  AM_SENSORMSG = 0x93,
};

typedef nx_struct SensorMsg 
{
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
