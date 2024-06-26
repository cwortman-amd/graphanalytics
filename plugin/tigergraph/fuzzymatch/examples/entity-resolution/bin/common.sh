#!/bin/bash
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
#

if [ "$USER" == "tigergraph" ]; then
    $SCRIPTPATH/install-udf-cluster.sh $verbose_flag $force_clean_flag
else
gsql_command="java -jar $HOME/gsql_client/gsql_client.jar"
fi

function gsql () {
     $gsql_command "$@"
}

function usage() {
    echo "Usage: $0 -u TG-username -p TG-password [optional options]"
    echo "Optional options:"
	echo "  -c compileMode       : 0: skip database creation and gsql compilation"
	echo "                         1: recreate database and compile all (default)"
	echo "                         2: only compile query gsql"
	echo "  -r runMode           : 0: Skip both CPU and Alveo run (i.e. only run partition)"
	echo "                         1: Run only on CPU"
	echo "                         2: Run only on Alveo (default)"
	echo "                         3: Run on both CPU and Alveo"
    echo "  -g graphName         : graph name (default=social_<username>"
    echo "  -i sshKey            : SSH key for user tigergraph"
    echo "  -l                   : Print detailed match results to JSON"
    echo "  -s refNames          : A csv file with reference names. default=../data/ref-names.csv"
    echo "  -t newNames          : A csv file with new names. default=../data/new-names.csv"
    echo "  -v                   : Print verbose messages"
    echo "  -h                   : Print this help message"
}

tg_home=$(readlink -f ~tigergraph)
tg_data_root=$(cat $tg_home/.tg.cfg | jq .System.DataRoot | tr -d \")

# default values for optional options
username=$USER
password=Xilinx123
ref_names="$script_dir/../data/ref-names.csv"
new_names="$script_dir/../data/new-names.csv"
num_nodes=$(cat $tg_data_root/gsql/udf/xilinx-plugin-config.json | jq .numNodes | tr -d \")
verbose=0
xgraph="entity_resolution_$username"
compile_mode=1
run_mode=2
print_result="False"
verbose_flag=

# set default ssh_key for tigergraph
if [ -f ~/.ssh/tigergraph_rsa ]; then
    ssh_key_flag="-i ~/.ssh/tigergraph_rsa"
fi

while getopts "c:g:i:lm:p:r:s:t:u:vh" opt
do
case $opt in
    c) compile_mode=$OPTARG;;
    g) xgraph=$OPTARG;;
    i) ssh_key=$OPTARG; ssh_key_flag="-i $ssh_key";;
    l) print_result="True";;
    m) num_nodes=$OPTARG;;
    r) run_mode=$OPTARG;;
    p) password=$OPTARG;;
    s) ref_names=$OPTARG;; 
    t) new_names=$OPTARG;;
    u) username=$OPTARG;;
    v) verbose=1; verbose_flag=-v;;
    h) usage; exit 0;;
    ?) echo "ERROR: Unknown option: -$OPTARG"; usage; exit 1;;
esac
done

if [ -z "$username" ] || [ -z "$password" ]; then
    echo "ERROR: username and password are required."
    usage
    exit 2
fi

if [ $(gsql -u $username -p $password "show user" | grep -c $username) -lt 1 ]; then
    echo "ERROR: TigerGraph user $username does not exist."
    echo "Please create the user by logging in as user tigergraph and doing:"
    echo "    gsql \"create user\""
    echo "supplying $username for User Name."
    echo "Additionally, if you plan on creating graphs and installing queries, please also do:"
    echo "    gsql \"grant role globaldesigner to $username\""
    exit 3
fi

if [ $verbose -eq 1 ]; then
    echo "INFO: username=$username"
    echo "      password=$password"
    echo "      refNames=$ref_names"
    echo "      newNames=$new_names"
    echo "      xgraph=$xgraph"
    echo "      numNodes=$num_nodes"
    echo "      compileMode=$compile_mode"
    echo "      runMode=$run_mode"    
    echo "      sshKey=$ssh_key"
    echo "      printResult=$print_result"
fi
