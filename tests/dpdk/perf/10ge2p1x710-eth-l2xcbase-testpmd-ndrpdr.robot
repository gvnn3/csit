# Copyright (c) 2018 Cisco and/or its affiliates.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

*** Settings ***
| Resource | resources/libraries/robot/performance/performance_setup.robot
| Resource | resources/libraries/robot/dpdk/default.robot
| Library | resources.libraries.python.topology.Topology
| Library | resources.libraries.python.NodePath
| Library | resources.libraries.python.InterfaceUtil
| Library | resources.libraries.python.DPDK.DPDKTools
| ...
| Force Tags | 3_NODE_SINGLE_LINK_TOPO | HW_ENV | PERFTEST | NDRPDR | 1NUMA
| ... | NIC_Intel-X710 | DPDK | ETH | L2XCFWD | BASE
| ...
| Suite Setup | Set up DPDK 3-node performance topology with DUT's NIC model
| ... | L2 | Intel-X710
| Suite Teardown | Tear down DPDK 3-node performance topology
| ...
| Test Template | Local Template
| ...
| Documentation | *Raw results L2 routing test cases*
| ... | *[Top] Network Topologies:* TG-DUT1-DUT2-TG 3-node circular topology\
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv4 for L2 frame forwarding.
| ... | *[Cfg] DUT configuration:* DUT1 and DUT2 run the DPDK testpmd\
| ... | application and use the io forwarding mode. DUT1 and DUT2 tested with\
| ... | 2p10GE NIC X710 by Intel.
| ... | *[Ver] TG verification:* TG finds and reports throughput NDR (Non Drop\
| ... | Rate) with zero packet loss tolerance or throughput PDR (Partial Drop\
| ... | Rate) with non-zero packet loss tolerance (LT) expressed in percentage\
| ... | of packets transmitted. NDR and PDR are discovered for different\
| ... | Ethernet L2 frame sizes using MLRsearch library\
| ... | Test packets are generated by TG on\
| ... | links to DUTs. TG traffic profile contains two L3 flow-groups\
| ... | (flow-group per direction, 254 flows per flow-group) with\
| ... | all packets containing Ethernet header,IPv4 header with static payload.\
| ... | MAC addresses are matching MAC addresses of the TG node interfaces.

*** Variables ***
# X710 bandwidth limit
| ${s_limit}= | ${10000000000}
# Traffic profile:
| ${traffic_profile}= | trex-sl-3n-ethip4-ip4src254

*** Keywords ***
| Local Template
| | [Documentation]
| | ... | [Cfg] DUT runs L2 frame forwarding config.\
| | ... | Each DUT uses ${phy_cores} physical core(s) for worker threads.
| | ... | [Ver] Measure NDR and PDR values using MLRsearch algorithm.
| | ...
| | [Arguments] | ${framesize} | ${phy_cores} | ${rxq}=${None}
| | ...
| | Set Test Variable | ${framesize}
| | Set Test Variable | ${min_rate} | ${10000}
| | ...
| | ${max_rate} | ${jumbo} = | Get Max Rate And Jumbo
| | ... | ${s_limit} | ${framesize}
| | Given Start L2FWD on all DUTs | ${phy_cores} | ${rxq} | ${jumbo}
| | Then Find NDR and PDR intervals using optimized search
| | ... | ${framesize} | ${traffic_profile} | ${min_rate} | ${max_rate}

*** Test Cases ***
| tc01-64B-1c-eth-l2xcbase-testpmd-ndrpdr
| | [Tags] | 64B | 1C
| | framesize=${64} | phy_cores=${1}

| tc02-64B-2c-eth-l2xcbase-testpmd-ndrpdr
| | [Tags] | 64B | 2C
| | framesize=${64} | phy_cores=${2}

| tc03-64B-4c-eth-l2xcbase-testpmd-ndrpdr
| | [Tags] | 64B | 4C
| | framesize=${64} | phy_cores=${4}

| tc04-1518B-1c-eth-l2xcbase-testpmd-ndrpdr
| | [Tags] | 1518B | 1C
| | framesize=${1518} | phy_cores=${1}

| tc05-1518B-2c-eth-l2xcbase-testpmd-ndrpdr
| | [Tags] | 1518B | 2C
| | framesize=${1518} | phy_cores=${2}

| tc06-1518B-4c-eth-l2xcbase-testpmd-ndrpdr
| | [Tags] | 1518B | 4C
| | framesize=${1518} | phy_cores=${4}

| tc07-9000B-1c-eth-l2xcbase-testpmd-ndrpdr
| | [Tags] | 9000B | 1C
| | framesize=${9000} | phy_cores=${1}

| tc08-9000B-2c-eth-l2xcbase-testpmd-ndrpdr
| | [Tags] | 9000B | 2C
| | framesize=${9000} | phy_cores=${2}

| tc09-9000B-4c-eth-l2xcbase-testpmd-ndrpdr
| | [Tags] | 9000B | 4C
| | framesize=${9000} | phy_cores=${4}

| tc10-IMIX-1c-eth-l2xcbase-testpmd-ndrpdr
| | [Tags] | IMIX | 1C
| | framesize=IMIX_v4_1 | phy_cores=${1}

| tc11-IMIX-2c-eth-l2xcbase-testpmd-ndrpdr
| | [Tags] | IMIX | 2C
| | framesize=IMIX_v4_1 | phy_cores=${2}

| tc12-IMIX-4c-eth-l2xcbase-testpmd-ndrpdr
| | [Tags] | IMIX | 4C
| | framesize=IMIX_v4_1 | phy_cores=${4}
