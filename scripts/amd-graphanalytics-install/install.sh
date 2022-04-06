#!/bin/bash
#
# Copyright 2021 Xilinx, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
# Copyright 2020-2021 Xilinx, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

SCRIPT=$(readlink -f $0)
SCRIPTPATH=`dirname $SCRIPT`

supported_products="cosinesim louvainmod mis fuzzymatch"

function usage() {
    echo "Usage: $0 -p product-name [options]"
    echo "Required options:"
    echo "  -p product-name  : Product to install. Supported products:"
    for prod in $supported_products
    do
        echo "      $prod"
    done
    
    echo ""
    echo "Optional options:"
    echo "  -s               : Skip installation of dependencies (XRT, XRM, etc)"
    echo "  -h               : Print this help message"
}

product="none"
install_dep=1
while getopts ":p:sh" opt
do
case $opt in
    p) product=$OPTARG;;
    s) install_dep=0;;
    h) usage; exit 0;;
    ?) echo "ERROR: Unknown option: -$OPTARG"; usage; exit 1;;
esac
done

OSDIST=`lsb_release -i |awk -F: '{print tolower($2)}' | tr -d ' \t'`
OSREL=`lsb_release -r |awk -F: '{print tolower($2)}' |tr -d ' \t' | awk -F. '{print $1*100+$2}'`
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [[ $OSDIST == "ubuntu" ]]; then
    if (( $OSREL == 1804 )); then
        pkg_dir="$SCRIPTPATH/ubuntu-18.04"
    elif (( $OSREL == 2004 )); then
        pkg_dir="$SCRIPTPATH/ubuntu-20.04"        
    else
        echo "ERROR: Ubuntu release version must be 18.04 or 20.04."
        exit 2
    fi
elif [[ $OSDIST == "centos" ]]; then
    if (( $OSREL == 708 )); then
        pkg_dir="$SCRIPTPATH/centos-7.8"
    elif (( $OSREL == 709 )); then
        pkg_dir="$SCRIPTPATH/ubuntu-20.04"        
    else
        echo "ERROR: Ubuntu release version must be 18.04 or 20.04."
        exit 2
    fi

    
else 
    echo "ERROR: only Ubuntu and Centos are supported."
    exit 3
fi

if [[ $product == "none" ]] ; then
    echo "ERROR: Must select a product to install via -p option."
    usage
    exit 4
fi

is_supported=0
for prod in $supported_products
do
    if [[ $product == $prod ]] ; then
        is_supported=1
        echo "INFO: Installing Xilinx $product product and its dependencies on $OSDIST $OSREL..."
        break
    fi
done

if [[ $is_supported -eq 0 ]] ; then
    echo "ERROR: Unsupported product $product"
    usage
    exit 5
fi

###############################################################################
# Ubuntu
###############################################################################
if [[ $OSDIST == "ubuntu" ]]; then
    # install dependencies(XRT/XRM/Deployment shell. etc)
    if [[ $install_dep -eq 1 ]] ; then
        printf "\n-------------------------------------------------------------\n"
        printf "INFO: Install XRT. Enter sudo password if asked."
        printf "\n-------------------------------------------------------------\n"
        sudo apt install --reinstall $pkg_dir/xrt/xrt*.deb

        printf "\n-------------------------------------------------------------\n"
        printf "INFO: Install XRM. Enter sudo password if asked."
        printf "\n-------------------------------------------------------------\n"
        sudo apt install --reinstall $pkg_dir/xrm/xrm*.deb

        printf "\n-------------------------------------------------------------\n"
        printf "INFO: Install deployment shell. Enter sudo password if asked."
        printf "\n-------------------------------------------------------------\n"
        sudo apt install $pkg_dir/../deployment-shell/u50/xilinx*.deb
        sudo apt install $pkg_dir/../deployment-shell/u55c/xilinx*.deb

        # install required packages
        sudo apt install jq opencl-headers libzmq3-dev default-jre -y
    fi

    if [[ $product == "cosinesim" ]]; then
        # install required package
        sudo apt install jq opencl-headers -y
        printf "\n-------------------------------------------------------------\n"
        printf "INFO: Install Xilinx CosineSim. Enter sudo password if asked."
        printf "\n-------------------------------------------------------------\n"
        sudo apt install --reinstall $pkg_dir/cosinesim/xilinx-cosinesim*.deb

        printf "\n-------------------------------------------------------------\n"
        printf "INFO: Install Xilinx Recommend Engine. Enter sudo password if asked."
        printf "\n-------------------------------------------------------------\n"
        sudo apt install --reinstall $pkg_dir/cosinesim/xilinx-recomengine*.deb
    elif [[ $product == "louvainmod" ]]; then
        printf "\n-------------------------------------------------------------\n"
        printf "INFO: Install Xilinx LouvainMod. Enter sudo password if asked."
        printf "\n-------------------------------------------------------------\n"
        sudo apt install --reinstall $pkg_dir/louvainmod/xilinx-louvainmod*.deb

        printf "\n-------------------------------------------------------------\n"
        printf "INFO: Install Xilinx ComDetect. Enter sudo password if asked."
        printf "\n-------------------------------------------------------------\n"        
        sudo apt install --reinstall $pkg_dir/louvainmod/xilinx-comdetect*.deb
    elif [[ $product == "mis" ]]; then
        printf "\n-------------------------------------------------------------\n"
        printf "INFO: Install Xilinx MIS. Enter sudo password if asked."
        printf "\n-------------------------------------------------------------\n"
        sudo apt install --reinstall $pkg_dir/mis/xilinx-mis*.deb
    elif [[ $product == "fuzzymatch" ]]; then
        printf "\n-------------------------------------------------------------\n"
        printf "INFO: Install Xilinx FuzzyMatch. Enter sudo password if asked."
        printf "\n-------------------------------------------------------------\n"
        sudo apt install --reinstall $pkg_dir/fuzzymatch/xilinx-fuzzymatch*.deb
    fi
fi

###############################################################################
# CentOS
###############################################################################
if [[ $OSDIST == "centos" ]]; then
    # install XRT/XRM/Deployment shell
    printf "\nINFO: Install XRT. \n"
    sudo yum install $pkg_dir/xrt/xrt*.rpm

    printf "\nINFO: Install XRM. Enter sudo password if asked.\n"
    sudo yum install $pkg_dir/xrm/xrm*.rpm

    printf "\nINFO: Install deployment shell\n"
    sudo yum install $pkg_dir/deployment-shell/xilinx*.rpm

    if [[ $product == "cosinesim" ]]; then
        # install required package
        sudo yum install jq opencl-headers -y

        printf "\nINFO: Install Xilinx CosineSim package\n"
        sudo yum install $pkg_dir/cosinesim/xilinx-cosinesim*.rpm

        printf "\nINFO: Install Xilinx Recommend Engine package\n"
        sudo yum install $pkg_dir/recomengine/xilinx-recomengine*.rpm
    fi
fi

# copy requirements.txt to /opt/xilinx/apps/graphanalytics/
sudo cp $SCRIPTPATH/requirements.txt /opt/xilinx/apps/graphanalytics/

printf "\nINFO: All packages have been installed.\n"
if [[ $install_dep -eq 1 ]] ; then
    printf "\nPlease run the command below to flash your Alveo card if needed. \n" 
    printf "Xilinx Alveo U50 card\n"
    printf "${YELLOW}sudo /opt/xilinx/xrt/bin/xbmgmt flash --update --shell xilinx_u50_gen3x16_xdma_201920_3${NC}\n"
    printf "\nXilinx Alveo U55C card\n"
    printf "${YELLOW}sudo /opt/xilinx/xrt/bin/xbmgmt flash --update --shell xilinx_u55c_gen3x16_xdma_base_2${NC}\n"
fi    