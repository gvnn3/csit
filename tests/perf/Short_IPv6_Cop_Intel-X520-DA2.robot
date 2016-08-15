# Copyright (c) 2016 Cisco and/or its affiliates.
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
| Library | resources.libraries.python.Cop
| Force Tags | 3_NODE_SINGLE_LINK_TOPO | PERFTEST | HW_ENV | PERFTEST_SHORT
| ...        | NIC_Intel-X520-DA2
| Suite Setup | 3-node Performance Suite Setup with DUT's NIC model
| ... | L3 | Intel-X520-DA2
| Suite Teardown | 3-node Performance Suite Teardown
| Test Setup | Setup all DUTs before test
| Test Teardown | Run Keywords | Remove startup configuration of VPP from all DUTs
| ...           | AND          | Show vpp trace dump on all DUTs
| Documentation | *Reference NDR throughput IPv6 whitelist verify test cases*
| ...
| ... | *[Top] Network Topologies:* TG-DUT1-DUT2-TG 3-node circular topology
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv6 for IPv6 routing.
| ... | *[Cfg] DUT configuration:* DUT1 and DUT2 are configured with IPv6
| ... | routing, two static IPv6 /64 routes and IPv6 COP security whitelist
| ... | ingress /24 filter entries applied on links TG - DUT1 and DUT2 - TG.
| ... | DUT1 and DUT2 tested with 2p10GE NIC X520 Niantic by Intel.
| ... | *[Ver] TG verification:* In short performance tests, TG verifies
| ... | DUTs' throughput at ref-NDR (reference Non Drop Rate) with zero packet
| ... | loss tolerance. Ref-NDR value is periodically updated acording to
| ... | formula: ref-NDR = 0.9x NDR, where NDR is found in RFC2544 long
| ... | performance tests for the same DUT configuration. Test packets are
| ... | generated by TG on links to DUTs. TG traffic profile contains two L3
| ... | flow-groups (flow-group per direction, 253 flows per flow-group) with
| ... | all packets containing Ethernet header, IPv6 header and static
| ... | payload. MAC addresses are matching MAC addresses of the TG node
| ... | interfaces.
| ... | *[Ref] Applicable standard specifications:* RFC2544.

*** Test Cases ***
| TC01: Verify 78B ref-NDR at 2x 2.8Mpps - DUT IPv6 whitelist - 1thread 1core 1rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv6 routing and whitelist filters config with \
| | ... | 1 thread, 1 phy core, 1 receive queue per NIC port. [Ver] Verify
| | ... | ref-NDR for 78 Byte frames using single trial throughput test.
| | [Tags] | 1_THREAD_NOHTT_RXQUEUES_1 | SINGLE_THREAD | NDR
| | ${framesize}= | Set Variable | 78
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 2.8mpps
| | Given Add '1' worker threads and rxqueues '1' without HTT to all DUTs
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv6 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 2001:1:: | 64 | 1 | local
| | And   Add fib table | ${dut2} | 2001:2:: | 64 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip6 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip6 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then  Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                    | ${framesize} | 3-node-IPv6

| TC02: Verify 1518B ref-NDR at 2x 812.74kpps - DUT IPv6 whitelist - 1thread 1core 1rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv6 routing and whitelist filters config with \
| | ... | 1 thread, 1 phy core, 1 receive queue per NIC port. [Ver] Verify
| | ... | ref-NDR for 1518 Byte frames using single trial throughput test.
| | [Tags] | 1_THREAD_NOHTT_RXQUEUES_1 | SINGLE_THREAD | NDR
| | ${framesize}= | Set Variable | 1518
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 812743pps
| | Given Add '1' worker threads and rxqueues '1' without HTT to all DUTs
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv6 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 2001:1:: | 64 | 1 | local
| | And   Add fib table | ${dut2} | 2001:2:: | 64 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip6 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip6 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then  Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                    | ${framesize} | 3-node-IPv6

| TC03: Verify 9000B ref-NDR at 2x 138.580kpps - DUT IPv6 whitelist - 1thread 1core 1rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv6 routing and whitelist filters config with \
| | ... | 1 thread, 1 phy core, 1 receive queue per NIC port. [Ver] Verify
| | ... | ref-NDR for 9000 Byte frames using single trial throughput test.
| | [Tags] | 1_THREAD_NOHTT_RXQUEUES_1 | SINGLE_THREAD | NDR
| | ${framesize}= | Set Variable | 9000
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 138580pps
| | Given Add '1' worker threads and rxqueues '1' without HTT to all DUTs
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv6 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 2001:1:: | 64 | 1 | local
| | And   Add fib table | ${dut2} | 2001:2:: | 64 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip6 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip6 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then  Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                    | ${framesize} | 3-node-IPv6

| TC04: Verify 78B ref-NDR at 2x 4.9Mpps - DUT IPv6 whitelist - 2thread 2core 1rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv6 routing and whitelist filters config with \
| | ... | 2 threads, 2 phy cores, 1 receive queue per NIC port. [Ver] Verify
| | ... | ref-NDR for 78 Byte frames using single trial throughput test.
| | [Tags] | 2_THREAD_NOHTT_RXQUEUES_1 | MULTI_THREAD | NDR
| | ${framesize}= | Set Variable | 78
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 4.9mpps
| | Given Add '2' worker threads and rxqueues '1' without HTT to all DUTs
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv6 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 2001:1:: | 64 | 1 | local
| | And   Add fib table | ${dut2} | 2001:2:: | 64 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip6 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip6 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then  Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                    | ${framesize} | 3-node-IPv6

| TC05: Verify 1518B ref-NDR at 2x 812.74kpps - DUT IPv6 whitelist - 2thread 2core 1rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv6 routing and whitelist filters config with \
| | ... | 2 threads, 2 phy cores, 1 receive queue per NIC port. [Ver] Verify
| | ... | ref-NDR for 1518 Byte frames using single trial throughput test.
| | [Tags] | 2_THREAD_NOHTT_RXQUEUES_1 | MULTI_THREAD | NDR
| | ${framesize}= | Set Variable | 1518
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 812743pps
| | Given Add '2' worker threads and rxqueues '1' without HTT to all DUTs
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv6 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 2001:1:: | 64 | 1 | local
| | And   Add fib table | ${dut2} | 2001:2:: | 64 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip6 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip6 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then  Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                    | ${framesize} | 3-node-IPv6

| TC06: Verify 9000B ref-NDR at 2x 138.58kpps - DUT IPv6 whitelist - 2thread 2core 1rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv6 routing and whitelist filters config with \
| | ... | 2 threads, 2 phy cores, 1 receive queue per NIC port. [Ver] Verify
| | ... | ref-NDR for 9000 Byte frames using single trial throughput test.
| | [Tags] | 2_THREAD_NOHTT_RXQUEUES_1 | MULTI_THREAD | NDR
| | ${framesize}= | Set Variable | 9000
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 138580pps
| | Given Add '2' worker threads and rxqueues '1' without HTT to all DUTs
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv6 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 2001:1:: | 64 | 1 | local
| | And   Add fib table | ${dut2} | 2001:2:: | 64 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip6 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip6 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then  Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                    | ${framesize} | 3-node-IPv6

| TC07: Verify 78B ref-NDR at 2x 10.1Mpps - DUT IPv6 whitelist - 4thread 4core 2rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv6 routing and whitelist filters config with \
| | ... | 4 thread, 4 phy core, 2 receive queue per NIC port. [Ver] Verify
| | ... | ref-NDR for 78 Byte frames using single trial throughput test.
| | [Tags] | 4_THREAD_NOHTT_RXQUEUES_2 | MULTI_THREAD | NDR
| | ${framesize}= | Set Variable | 78
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 10.1mpps
| | Given Add '4' worker threads and rxqueues '2' without HTT to all DUTs
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv6 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 2001:1:: | 64 | 1 | local
| | And   Add fib table | ${dut2} | 2001:2:: | 64 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip6 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip6 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then  Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                    | ${framesize} | 3-node-IPv6

| TC08: Verify 1518B ref-NDR at 2x 812.74kpps - DUT IPv6 whitelist - 4thread 4core 2rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv6 routing and whitelist filters config with \
| | ... | 4 thread, 4 phy core, 2 receive queue per NIC port. [Ver] Verify
| | ... | ref-NDR for 1518 Byte frames using single trial throughput test.
| | [Tags] | 4_THREAD_NOHTT_RXQUEUES_2 | MULTI_THREAD | NDR
| | ${framesize}= | Set Variable | 1518
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 812743pps
| | Given Add '4' worker threads and rxqueues '2' without HTT to all DUTs
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv6 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 2001:1:: | 64 | 1 | local
| | And   Add fib table | ${dut2} | 2001:2:: | 64 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip6 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip6 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then  Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                    | ${framesize} | 3-node-IPv6

| TC09: Verify 9000B ref-NDR at 2x 138.58kpps - DUT IPv6 whitelist - 4thread 4core 2rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv6 routing and whitelist filters config with \
| | ... | 4 thread, 4 phy core, 2 receive queue per NIC port. [Ver] Verify
| | ... | ref-NDR for 9000 Byte frames using single trial throughput test.
| | [Tags] | 4_THREAD_NOHTT_RXQUEUES_2 | MULTI_THREAD | NDR
| | ${framesize}= | Set Variable | 9000
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 138580pps
| | Given Add '4' worker threads and rxqueues '2' without HTT to all DUTs
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv6 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 2001:1:: | 64 | 1 | local
| | And   Add fib table | ${dut2} | 2001:2:: | 64 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip6 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip6 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then  Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                    | ${framesize} | 3-node-IPv6
