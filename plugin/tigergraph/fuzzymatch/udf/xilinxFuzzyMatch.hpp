/*
 * Copyright 2020-2021 Xilinx, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WANCUNCUANTIES ONCU CONDITIONS OF ANY KIND, either express or
 * implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef XILINX_FUZZY_MATCH_HPP
#define XILINX_FUZZY_MATCH_HPP

// mergeHeaders 1 name xilinxFuzzyMatch
// mergeHeaders 1 section include start xilinxFuzzyMatch DO NOT REMOVE!
#include "xilinxFuzzyMatchImpl.hpp"
#include <cstdint>
#include <vector>
#include <chrono>
// mergeHeaders 1 section include end xilinxFuzzyMatch DO NOT REMOVE!

namespace UDIMPL {

// mergeHeaders 1 section body start xilinxFuzzyMatch DO NOT REMOVE!

inline int udf_xilinx_fuzzymatch_set_node_id(uint nodeId)
{
    std::lock_guard<std::mutex> lockGuard(xilFuzzyMatch::getMutex());
    std::cout << "DEBUG: " << __FUNCTION__ << " nodeId=" << nodeId << std::endl;
    xilFuzzyMatch::Context *pContext = xilFuzzyMatch::Context::getInstance();

    pContext->setNodeId(unsigned(nodeId));
    return nodeId;
}

// Return value:
//    Positive number: Match execution time in ms
//   -1: Failed to initialize Alveo device
//   -2: Target list is empty
inline int udf_fuzzymatch_alveo(ListAccum<string> sourceList, 
                                ListAccum<string> targetList, 
                                int similarity_level) 
{

    std::vector<std::string> sourceVector, targetVector;
    xilFuzzyMatch::Context *pContext = xilFuzzyMatch::Context::getInstance();
    xilinx_apps::fuzzymatch::FuzzyMatch *pFuzzyMatch = pContext->getFuzzyMatchObj();

    int execTime;

    if (pFuzzyMatch->startFuzzyMatch() < 0) {
        std::cout << "ERROR: Failed to initialize Alveo device" << std::endl;
        return -1;
    }

    // load sourceVector
    uint32_t sourceListLen = sourceList.size();
    for (unsigned i = 0 ; i < sourceListLen; ++i)
        sourceVector.push_back(sourceList.get(i));

    std::cout << "sourceVector size=" << sourceVector.size() << std::endl;
    pFuzzyMatch->fuzzyMatchLoadVec(sourceVector);

    // populate target vector
    uint32_t targetListLen = targetList.size();
    if (targetListLen == 0) {
        std::cout << "WARNING: the target list is empty." << std::endl;
        return -2;
    }

    for (unsigned i = 0 ; i < targetListLen; ++i) {
        targetVector.push_back(targetList.get(i));
    }

    std::cout << "INFO: udf_fuzzymatch_alveo" 
              << "\n    similarity_level=" << similarity_level 
              << "\n    sourceListLen=" << sourceListLen
              << "\n    targetListLen=" << targetListLen << std::endl;

    std::vector<std::vector<std::pair<int,int>>> match_result(targetListLen);

    // only measure match time
    auto ts = std::chrono::high_resolution_clock::now();
    match_result = pFuzzyMatch->executefuzzyMatch(targetVector, similarity_level);
    auto te = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> l_durationSec = te - ts;
    execTime = l_durationSec.count() * 1e3;

    return execTime;
}

// mergeHeaders 1 section body end xilinxFuzzyMatch DO NOT REMOVE!

}

#endif /* XILINX_FUZZY_MATCH_HPP */
