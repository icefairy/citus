/*-------------------------------------------------------------------------
 *
 * shared_library_init.h
 *	  Functionality related to the initialization of the Citus extension.
 *
 * Copyright (c) Citus Data, Inc.
 *
 *-------------------------------------------------------------------------
 */

#ifndef SHARED_LIBRARY_INIT_H
#define SHARED_LIBRARY_INIT_H

#include "columnar/columnar.h"

#define GUC_STANDARD 0
#define MAX_SHARD_COUNT 64000
#define MAX_SHARD_REPLICATION_FACTOR 100

extern ColumnarSupportsIndexAM_type ExternColumnarSupportsIndexAM;
extern CompressionTypeStr_type ExternCompressionTypeStr;
extern IsColumnarTableAmTable_type ExternIsColumnarTableAmTable;
extern ReadColumnarOptions_type ExternReadColumnarOptions;

extern void StartupCitusBackend(void);

#endif /* SHARED_LIBRARY_INIT_H */
