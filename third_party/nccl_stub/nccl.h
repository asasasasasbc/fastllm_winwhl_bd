// Minimal NCCL stub for Windows (NCCL is not available on Windows)
// Multi-GPU NCCL operations will be disabled at runtime.
#pragma once

typedef int ncclResult_t;
#define ncclSuccess 0

typedef struct ncclComm* ncclComm_t;

typedef enum { ncclHalf = 6, ncclFloat = 7 } ncclDataType_t;
typedef enum { ncclSum = 0 } ncclRedOp_t;

struct ncclComm { int dummy; };

static inline ncclResult_t ncclCommInitAll(ncclComm_t* comms, int ndev, const int* devlist) { return 1; }
static inline ncclResult_t ncclCommDestroy(ncclComm_t comm) { return 1; }
static inline ncclResult_t ncclAllReduce(const void* sendbuff, void* recvbuff, size_t count,
    ncclDataType_t datatype, ncclRedOp_t op, ncclComm_t comm, void* stream) { return 1; }
static inline ncclResult_t ncclBroadcast(const void* sendbuff, void* recvbuff, size_t count,
    ncclDataType_t datatype, int root, ncclComm_t comm, void* stream) { return 1; }
static inline const char* ncclGetErrorString(ncclResult_t result) { return "NCCL not available on Windows"; }
