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
| Resource | resources/libraries/robot/performance/performance_setup.robot
| ...
| Force Tags | 3_NODE_SINGLE_LINK_TOPO | PERFTEST | HW_ENV | NDRCHK
| ... | NIC_Intel-X520-DA2 | ETH | IP4FWD | BASE | IP4BASE
| ...
| Suite Setup | Set up 3-node performance topology with DUT's NIC model
| ... | L3 | Intel-X520-DA2
| Suite Teardown | Tear down 3-node performance topology
| ...
| Test Setup | Set up performance test
| Test Teardown | Tear down performance ndrchk test
| ...
| Documentation | *Reference NDR throughput IPv4 routing verify test cases*
| ...
| ... | *[Top] Network Topologies:* TG-DUT1-DUT2-TG 3-node circular topology
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv4 for IPv4 routing.
| ... | *[Cfg] DUT configuration:* DUT1 and DUT2 are configured with IPv4
| ... | routing and two static IPv4 /24 route entries. DUT1 and DUT2 tested with
| ... | 2p10GE NIC X520 Niantic by Intel.
| ... | *[Ver] TG verification:* In short performance tests, TG verifies
| ... | DUTs' throughput at ref-NDR (reference Non Drop Rate) with zero packet
| ... | loss tolerance. Ref-NDR value is periodically updated acording to
| ... | formula: ref-NDR = 0.9x NDR, where NDR is found in RFC2544 long
| ... | performance tests for the same DUT configuration. Test packets are
| ... | generated by TG on links to DUTs. TG traffic profile contains two L3
| ... | flow-groups (flow-group per direction, 253 flows per flow-group) with
| ... | all packets containing Ethernet header, IPv4 header with IP protocol=61
| ... | and static payload. MAC addresses are matching MAC addresses of the
| ... | TG node interfaces.
| ... | *[Ref] Applicable standard specifications:* RFC2544.

*** Variables ***
# Traffic profile:
| ${traffic_profile} | trex-sl-3n-ethip4-ip4src253

*** Keywords ***
| Check NDR for ethip4-ip4base
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing config with ${wt} thread(s), ${wt}\
| | ... | phy core(s), ${rxq} receive queue(s) per NIC port.
| | ... | [Ver] Verify ref-NDR for ${framesize} frames using single trial\
| | ... | throughput test at 2x ${rate}.
| | ...
| | [Arguments] | ${framesize} | ${rate} | ${wt} | ${rxq}
| | ...
| | # Test Variables required for test teardown
| | Set Test Variable | ${framesize}
| | Set Test Variable | ${rate}
| | ${get_framesize}= | Get Frame Size | ${framesize}
| | ...
| | Given Add '${wt}' worker threads and '${rxq}' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to DUTs in 3-node single link topology
| | And Run Keyword If | ${get_framesize} < ${1522}
| | ... | Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | And Initialize IPv4 forwarding in 3-node circular topology
| | Then Traffic should pass with no loss | ${perf_trial_duration}
| | ... | ${rate} | ${framesize} | ${traffic_profile}

*** Test Cases ***
| tc01-64B-1t1c-ethip4-ip4base-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing config with 1 thread, 1 phy core, \
| | ... | 1 receive queue per NIC port. [Ver] Verify ref-NDR for 64 Byte
| | ... | frames using single trial throughput test at 2x 4.6mpps.
| | [Tags] | 64B | 1T1C | STHREAD
| | ...
| | [Template] | Check NDR for ethip4-ip4base
| | framesize=${64} | rate=4.6mpps | wt=1 | rxq=1

| tc02-1518B-1t1c-ethip4-ip4base-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing config with 1 thread, 1 phy core, \
| | ... | 1 receive queue per NIC port. [Ver] Verify ref-NDR for 1518 Byte
| | ... | frames using single trial throughput test at 2x 812743pps.
| | [Tags] | 1518B | 1T1C | STHREAD
| | ...
| | [Template] | Check NDR for ethip4-ip4base
| | framesize=${1518} | rate=812743pps | wt=1 | rxq=1

| tc03-9000B-1t1c-ethip4-ip4base-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing config with 1 thread, 1 phy core, \
| | ... | 1 receive queue per NIC port. [Ver] Verify ref-NDR for 9000 Byte
| | ... | frames using single trial throughput test at 2x 138580pps.
| | [Tags] | 9000B | 1T1C | STHREAD
| | ...
| | [Template] | Check NDR for ethip4-ip4base
| | framesize=${9000} | rate=138580pps | wt=1 | rxq=1

| tc04-64B-2t2c-ethip4-ip4base-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing config with 2 threads, 2 phy cores, \
| | ... | 1 receive queue per NIC port. [Ver] Verify ref-NDR for 64 Byte
| | ... | frames using single trial throughput test at 2x 9.4mpps.
| | [Tags] | 64B | 2T2C | MTHREAD
| | ...
| | [Template] | Check NDR for ethip4-ip4base
| | framesize=${64} | rate=9.4mpps | wt=2 | rxq=1

| tc05-1518B-2t2c-ethip4-ip4base-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing config with 2 threads, 2 phy cores, \
| | ... | 1 receive queue per NIC port. [Ver] Verify ref-NDR for 1518 Byte
| | ... | frames using single trial throughput test at 2x 812743pps.
| | [Tags] | 1518B | 2T2C | MTHREAD
| | ...
| | [Template] | Check NDR for ethip4-ip4base
| | framesize=${1518} | rate=812743pps | wt=2 | rxq=1

| tc06-9000B-2t2c-ethip4-ip4base-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing config with 2 threads, 2 phy cores, \
| | ... | 1 receive queue per NIC port. [Ver] Verify ref-NDR for 9000 Byte
| | ... | frames using single trial throughput test at 2x 138580pps.
| | [Tags] | 9000B | 2T2C | MTHREAD
| | ...
| | [Template] | Check NDR for ethip4-ip4base
| | framesize=${9000} | rate=138580pps | wt=2 | rxq=1

| tc07-64B-4t4c-ethip4-ip4base-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing config with 4 threads, 4 phy cores, \
| | ... | 2 receive queues per NIC port. [Ver] Verify ref-NDR for 64 Byte
| | ... | frames using single trial throughput test at 2x 10.4mpps.
| | [Tags] | 64B | 4T4C | MTHREAD
| | ...
| | [Template] | Check NDR for ethip4-ip4base
| | framesize=${64} | rate=10.4mpps | wt=4 | rxq=2

| tc08-1518B-4t4c-ethip4-ip4base-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing config with 4 threads, 4 phy cores, \
| | ... | 2 receive queues per NIC port. [Ver] Verify ref-NDR for 1518 Byte
| | ... | frames using single trial throughput test at 2x 812743pps.
| | [Tags] | 1518B | 4T4C | MTHREAD
| | ...
| | [Template] | Check NDR for ethip4-ip4base
| | framesize=${1518} | rate=812743pps | wt=4 | rxq=2

| tc09-9000B-4t4c-ethip4-ip4base-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing config with 4 threads, 4 phy cores, \
| | ... | 2 receive queues per NIC port. [Ver] Verify ref-NDR for 9000 Byte
| | ... | frames using single trial throughput test at 2x 138580pps.
| | [Tags] | 9000B | 4T4C | MTHREAD
| | ...
| | [Template] | Check NDR for ethip4-ip4base
| | framesize=${9000} | rate=138580pps | wt=4 | rxq=2
