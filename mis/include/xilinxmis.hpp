/*
 * Copyright 2019-2021 Xilinx, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
*/

#ifndef _XILINX_MIS_HEADER_
#define _XILINX_MIS_HEADER_
#include <omp.h>
#include <algorithm>
#include <chrono>
#include <cstdint>
#include <fstream>
#include <future>
#include <iostream>
#include <string>
#include <vector>
#include <cstring>
#include "xilinx_apps_common.hpp"

/**
 * Define this macro to make functions in mis_loader.cpp inline instead of extern.  You would use this macro
 * when including mis_loader.cpp in a header file, as opposed to linking with libXilinxMis_loader.a.
 */
#ifdef XILINX_MIS_INLINE_IMPL
#define XILINX_MIS_IMPL_DECL inline
#else
#define XILINX_MIS_IMPL_DECL extern
#endif

namespace xilinx_apps {
namespace mis {
struct Options;
class MisImpl;
}
}

extern "C" {
XILINX_MIS_IMPL_DECL
xilinx_apps::mis::MisImpl* xilinx_mis_createImpl(const xilinx_apps::mis::Options& options);

XILINX_MIS_IMPL_DECL
void xilinx_mis_destroyImpl(xilinx_apps::mis::MisImpl* pImpl);
}

namespace xilinx_apps {
namespace mis {

// GraphCSR format class
class GraphCSR {
   public:
    int n;
    std::vector<int> rowPtr;
    std::vector<int> colIdx;
    int rowPtrSize;
    int colIdxSize;

    GraphCSR(const std::vector<int>& rowPtr, const std::vector<int>& colIdx) : rowPtr(rowPtr), colIdx(colIdx) {
        rowPtrSize = rowPtr.size();
        colIdxSize = colIdx.size();
        n = rowPtr.size() - 1;
    }

    GraphCSR(std::vector<int>&& rowPtr, std::vector<int>&& colIdx)
        : rowPtr(std::move(rowPtr)), colIdx(std::move(colIdx)) {
        rowPtrSize = this->rowPtr.size();
        colIdxSize = this->colIdx.size();
        n = this->rowPtr.size() - 1;
    }
};

/*
* This exception class is derived from `std::exception` and provides the standard @ref what() member function.
* An object of this class is constructed with an error message string, which is stored internally and
* retrieved with the @ref what() member function.
*/
class Exception : public std::exception {
    std::string message;

   public:
    /**
     * Constructs an Exception object.
     *
     * @param msg an error message string, which is copied and stored internal to the object
     */
    Exception(const std::string& msg) : message(msg) {}

    /**
     * Returns the error message string passed to the constructor.
     *
     * @return the error message string
     */
    virtual const char* what() const noexcept override { return message.c_str(); }
};

/**
 * @brief Struct containing MIS configuration options
 */
struct Options {
    XString xclbinPath;
    XString deviceNames;
};
/*
template <typename T>
using host_buffer_t = std::vector<T, aligned_allocator<T> >;
*/
class MIS {
   public:
    MIS(const Options& options) : pImpl_(xilinx_mis_createImpl(options)) {}

    ~MIS() { xilinx_mis_destroyImpl(pImpl_); }

    // The intialize process will download FPGA binary to FPGA card
    void startMis();
    // set the graph and internal pre-process the graph
    void setGraph(GraphCSR* graph);
    std::vector<int> executeMIS();
    size_t count() const;

   private:
    MisImpl* pImpl_ = nullptr;
};

} // namespace mis
} // namespace xilinx_apps
#endif
