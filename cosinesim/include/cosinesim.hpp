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
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef XILINX_APPS_COSINESIM_HPP
#define XILINX_APPS_COSINESIM_HPP

#include <cstdint>
#include <vector>
#include <string>
#include <memory>


namespace xilinx_apps {
namespace cosinesim {



using RowIndex = std::int64_t;
using ColIndex = std::int32_t;

struct Result {
    RowIndex index_ = -1L;
    double similarity_ = 0.0;

    Result(RowIndex index, double similarity) {
        index_ = index;
        similarity_ = similarity;
    }
};

class CosineSimBase;
template <typename Value>
class CosineSim;

class ImplBase {
public:
	virtual ~ImplBase(){};
	virtual void *getPopulationVectorBuffer(RowIndex &rowIndex) = 0;
	virtual void finishCurrentPopulationVector() = 0;
	virtual void finishLoadPopulationVectors() =0;
	virtual std::vector<Result> matchTargetVector(unsigned numResults,void *elements) = 0;
};

extern "C" {
    ImplBase *createImpl(CosineSimBase* ptr, unsigned valueSize);
    void destroyImpl(ImplBase *pImpl);
}

class CosineSimBase {

public:
    struct Options {
    	ColIndex vecLength;
    	int64_t numVertices;
    	int64_t devicesNeeded;
    };


    enum ErrorCode{
    	NoError =0,
		ErrorGraphPartition,
		ErrorUnsupportedValueType,
		ErrorConfigFileNotExist,
		ErrorXclbinNotExist,
		ErrorXclbin2NotExist,
		ErrorFailFPGASetup
    };
    Options getOptions() {return options_;};

    CosineSimBase( const Options &options) : options_(options){};

private:
    Options options_;
    ColIndex vecLength_ = 0;
    RowIndex numRows_ = 0;

};

template <typename Value>
class CosineSim : public CosineSimBase{
public:
    
    CosineSim( const Options &options) :CosineSimBase(options), pImpl_(createImpl(this, sizeof(Value))) {

    };
    ColIndex getVectorLength() const { return vecLength_; }
    
    //oid openFpga(...);
    void startLoadPopulation();  //

    Value *getPopulationVectorBuffer(RowIndex &rowIndex) {
        // figure out where in weightDense to start writing
        // memset vector padding (8 bytes for example) to 0
        // return pointer into weightDense
         return reinterpret_cast<Value *>(pImpl_->getPopulationVectorBuffer(rowIndex));
    }
    void finishCurrentPopulationVector(){pImpl_->finishCurrentPopulationVector();}
    void finishLoadPopulationVectors(){pImpl_->finishLoadPopulationVectors();}

    
    std::vector<Result> matchTargetVector(unsigned numResults, const Value *elements) {
    	return pImpl_->matchTargetVector(numResults, reinterpret_cast<void *> (elements) );
    }
    //void closeFpga();
    
private:
    //Options options_;
    //ColIndex vecLength_ = 0;
    //RowIndex numRows_ = 0;
    //std::unique_ptr<ImplBase> pImpl_;
    ImplBase *pImpl_ = nullptr;

};

} // namespace cosinesim
} // namespace xilinx_apps


#endif /* XILINX_APPS_COSINESIM_HPP */
