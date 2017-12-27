// $Id: BlinkToRadio.h,v 1.4 2006/12/12 18:22:52 vlahan Exp $

#ifndef BLINKTORADIO_H
#define BLINKTORADIO_H

enum {
    ARRAY_SIZE = 2000,
    GROUP_ID = 5,
    AM_BLINKTORADIO = 0,
    PERIOD = 20,
    MY_SUB1 = 14,
    MY_SUB2 = 15,
    SERVER_ID = 1000
};

typedef nx_struct ack {
    nx_uint8_t group_id;
}m_ack;

typedef nx_struct source {
    nx_uint16_t sequence_number;
    nx_uint32_t random_integer;
}m_source;

typedef nx_struct answer {
    nx_uint8_t group_id;
    nx_uint32_t max;
    nx_uint32_t min;
    nx_uint32_t sum;
    nx_uint32_t average;
    nx_uint32_t median;
}m_answer;

typedef nx_struct request {
    nx_uint16_t index;
}m_request;

#endif
