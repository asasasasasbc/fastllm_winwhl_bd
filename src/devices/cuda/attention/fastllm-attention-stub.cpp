#include "devices/cuda/fastllm-cuda.cuh"

#include "fastllm.h"

#include <stdexcept>

namespace fastllm {
    void *FastllmCudaGetFlashInferFloatWorkspace(size_t *outSize) {
        if (outSize != nullptr) {
            *outSize = 0;
        }
        return nullptr;
    }

    void *FastllmBorrowDequantScratch(size_t needBytes, size_t *outBytes, bool *outOwn) {
        size_t actualBytes = needBytes > 0 ? needBytes : 1;
        if (outBytes != nullptr) {
            *outBytes = actualBytes;
        }
        if (outOwn != nullptr) {
            *outOwn = true;
        }
        return FastllmCudaMalloc(actualBytes);
    }

    void FastllmReleaseDequantScratch(void *ptr, bool own) {
        if (own && ptr != nullptr) {
            FastllmCudaFree(ptr);
        }
    }

    bool FastllmCudaHalfPagedAttention(fastllm::Data &q, fastllm::Data &k, fastllm::Data &v,
                                       fastllm::Data &output, int group, float scale, bool inited) {
        throw std::runtime_error("CUDA paged attention is unavailable in this build because FlashInfer is disabled.");
    }

    bool FastllmCudaHalfPagedAttentionBatch(fastllm::Data &q, fastllm::Data &kCaches, fastllm::Data &vCaches,
                                            fastllm::Data &qSizes, fastllm::Data &pageSizes,
                                            fastllm::Data &pageIndexs, fastllm::Data &lastPageLens,
                                            fastllm::Data &output, int group, float scale,
                                            int attentionType, bool inited, bool sync) {
        throw std::runtime_error("CUDA paged attention batch is unavailable in this build because FlashInfer is disabled.");
    }
}