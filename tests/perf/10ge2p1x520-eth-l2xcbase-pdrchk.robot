# Copyright (c) 2017 Cisco and/or its affiliates.
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
| Resource | resources/libraries/robot/performance.robot
| Library | resources.libraries.python.InterfaceUtil
| Library | resources.libraries.python.NodePath
| ...
| Force Tags | 3_NODE_SINGLE_LINK_TOPO | PERFTEST | HW_ENV | PDRCHK
| ... | NIC_Intel-X520-DA2 | ETH | L2XCFWD | BASE | L2XCBASE
| ...
| Suite Setup | 3-node Performance Suite Setup with DUT's NIC model
| ... | L2 | Intel-X520-DA2
| Suite Teardown | 3-node Performance Suite Teardown
| ...
| Test Setup | Performance test setup
| Test Teardown | Performance pdrchk test teardown
| ...
| Documentation | *Reference PDR throughput L2XC verify test cases*
| ...
| ... | *[Top] Network Topologies:* TG-DUT1-DUT2-TG 3-node circular topology
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv4 for L2 cross connect.
| ... | *[Cfg] DUT configuration:* DUT1 and DUT2 are configured with L2 cross-
| ... | connect. DUT1 and DUT2 tested with 2p10GE NIC X520 Niantic by Intel.
| ... | *[Ver] TG verification:* In short performance tests, TG verifies
| ... | DUTs' throughput at ref-PDR (reference Non Drop Rate) with zero packet
| ... | loss tolerance. Ref-PDR value is periodically updated acording to
| ... | formula: ref-PDR = 0.9x PDR, where PDR is found in RFC2544 long
| ... | performance tests for the same DUT configuration. Test packets are
| ... | generated by TG on links to DUTs. TG traffic profile contains two L3
| ... | flow-groups (flow-group per direction, 254 flows per flow-group) with
| ... | all packets containing Ethernet header, IPv4 header with IP protocol=61
| ... | and static payload. MAC addresses are matching MAC addresses of the
| ... | TG node interfaces.
| ... | *[Ref] Applicable standard specifications:* RFC2544.

*** Variables ***
# Traffic profile:
| ${traffic_profile} | trex-sl-3n-ethip4-ip4src254

*** Keywords ***
| Check PDR for L2 xconnect
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC config with ${wt} thread, ${wt} phy core,\
| | ... | ${rxq} receive queue per NIC port.
| | ... | [Ver] Verify ref-PDR for ${framesize} Byte frames using single trial\
| | ... | throughput test at 2x ${rate}.
| | ...
| | [Arguments] | ${framesize} | ${rate} | ${wt} | ${rxq}
| | ...
| | # Test Variables required for test and test teardown
| | Set Test Variable | ${framesize}
| | Set Test Variable | ${rate}
| | ${get_framesize}= | Get Frame Size | ${framesize}
| | ...
| | Given Add '${wt}' worker threads and rxqueues '${rxq}' in 3-node single-link topo
| | And Add PCI devices to DUTs from 3-node single link topology
| | And Run Keyword If | ${get_framesize} < ${1522}
| | ... | Add No Multi Seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | And L2 xconnect initialized in a 3-node circular topology
| | Then Traffic should pass with partial loss | ${perf_trial_duration}
| | ... | ${rate} | ${framesize} | ${traffic_profile}
| | ... | ${perf_pdr_loss_acceptance} | ${perf_pdr_loss_acceptance_type}

*** Test Cases ***
| tc01-64B-1t1c-eth-l2xcbase-pdrchk
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC config with 1 thread, 1 phy core,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Verify ref-NDR for 64 Byte frames using single trial\
| | ... | throughput test at 2x ${rate}.
| | ...
| | [Tags] | 64B | 1T1C | STHREAD
| | ...
| | [Template] | Check PDR for L2 xconnect
| | framesize=${64} | rate=5.9mpps | wt=1 | rxq=1

| tc02-1518B-1t1c-eth-l2xcbase-pdrchk
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC config with 1 thread, 1 phy core,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Verify ref-NDR for 1518 Byte frames using single trial\
| | ... | throughput test at 2x ${rate}.
| | ...
| | [Tags] | 1518B | 1T1C | STHREAD
| | ...
| | [Template] | Check PDR for L2 xconnect
| | framesize=${1518} | rate=812743pps | wt=1 | rxq=1

| tc03-9000B-1t1c-eth-l2xcbase-pdrchk
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC config with 1 thread, 1 phy core,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Verify ref-NDR for 9000 Byte frames using single trial\
| | ... | throughput test at 2x ${rate}.
| | ...
| | [Tags] | 9000B | 1T1C | STHREAD
| | ...
| | [Template] | Check PDR for L2 xconnect
| | framesize=${9000} | rate=138580pps | wt=1 | rxq=1

| tc04-64B-2t2c-eth-l2xcbase-pdrchk
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC config with 2 threads, 2 phy cores,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Verify ref-NDR for 64 Byte frames using single trial\
| | ... | throughput test at 2x ${rate}.
| | ...
| | [Tags] | 64B | 2T2C | MTHREAD
| | ...
| | [Template] | Check PDR for L2 xconnect
| | framesize=${64} | rate=10.4mpps | wt=2 | rxq=1

| tc05-1518B-2t2c-eth-l2xcbase-pdrchk
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC config with 2 threads, 2 phy cores,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Verify ref-NDR for 1518 Byte frames using single trial\
| | ... | throughput test at 2x ${rate}.
| | ...
| | [Tags] | 1518B | 2T2C | MTHREAD
| | ...
| | [Template] | Check PDR for L2 xconnect
| | framesize=${1518} | rate=812743pps | wt=2 | rxq=1

| tc06-9000B-2t2c-eth-l2xcbase-pdrchk
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC config with 2 threads, 2 phy cores,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Verify ref-NDR for 9000 Byte frames using single trial\
| | ... | throughput test at 2x ${rate}.
| | ...
| | [Tags] | 9000B | 2T2C | MTHREAD
| | ...
| | [Template] | Check PDR for L2 xconnect
| | framesize=${9000} | rate=138580pps | wt=2 | rxq=1

| tc07-64B-4t4c-eth-l2xcbase-pdrchk
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC config with 4 threads, 4 phy cores,\
| | ... | 2 receive queues per NIC port.
| | ... | [Ver] Verify ref-NDR for 64 Byte frames using single trial\
| | ... | throughput test at 2x ${rate}.
| | ...
| | [Tags] | 64B | 4T4C | MTHREAD
| | ...
| | [Template] | Check PDR for L2 xconnect
| | framesize=${64} | rate=10.4mpps | wt=4 | rxq=2

| tc08-1518B-4t4c-eth-l2xcbase-pdrchk
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC config with 4 threads, 4 phy cores,\
| | ... | 2 receive queues per NIC port.
| | ... | [Ver] Verify ref-NDR for 1518 Byte frames using single trial\
| | ... | throughput test at 2x ${rate}.
| | ...
| | [Tags] | 1518B | 4T4C | MTHREAD
| | ...
| | [Template] | Check PDR for L2 xconnect
| | framesize=${1518} | rate=812743pps | wt=4 | rxq=2

| tc09-9000B-4t4c-eth-l2xcbase-pdrchk
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC config with 4 threads, 4 phy cores,\
| | ... | 2 receive queues per NIC port.
| | ... | [Ver] Verify ref-NDR for 9000 Byte frames using single trial\
| | ... | throughput test at 2x ${rate}.
| | ...
| | [Tags] | 9000B | 4T4C | MTHREAD
| | ...
| | [Template] | Check PDR for L2 xconnect
| | framesize=${9000} | rate=138580pps | wt=4 | rxq=2
