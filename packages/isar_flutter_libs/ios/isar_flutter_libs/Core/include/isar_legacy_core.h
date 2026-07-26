#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

char *isar_get_error(uint32_t error);
void isar_legacy_force_link_all_symbols(void);

#ifdef __cplusplus
}
#endif
