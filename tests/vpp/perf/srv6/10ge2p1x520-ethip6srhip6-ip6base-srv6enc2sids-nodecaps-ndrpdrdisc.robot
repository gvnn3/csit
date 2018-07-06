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
| ...
| Force Tags | 3_NODE_SINGLE_LINK_TOPO | PERFTEST | HW_ENV | NDRPDRDISC
| ... | NIC_Intel-X520-DA2 | ETH | IP6FWD | FEATURE | SRv6
| ...
| Suite Setup | Set up 3-node performance topology with DUT's NIC model
| ... | L3 | Intel-X520-DA2
| Suite Teardown | Tear down 3-node performance topology
| ...
| Test Setup | Set up performance test
| ...
| Test Teardown | Tear down performance test with SRv6 with encapsulation
| ... | ${min_rate}pps | ${framesize} | ${traffic_profile}
| ...
| Documentation | *Packet throughput Segment routing over IPv6 dataplane with\
| ... | two SIDs (SRH inserted) without decapsulation test cases*
| ...
| ... | *[Top] Network Topologies:* TG-DUT1-DUT2-TG 3-node circular topology\
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv6-SRH-IPv6 on DUT1-DUT2 and\
| ... | DUTn->TG, Eth-IPv6 on TG->DUTn for IPv6 routing over SRv6.
| ... | *[Cfg] DUT configuration:* DUT1 and DUT2 are configured with IPv6\
| ... | routing and static route, SR policy and steering policy for one\
| ... | direction and one SR behaviour (function) - End - for other direction.\
| ... | DUT1 and DUT2 are tested with 2p10GE NIC X520 Niantic by Intel.
| ... | *[Ver] TG verification:* TG finds and reports throughput NDR (Non Drop\
| ... | Rate) with zero packet loss tolerance or throughput PDR (Partial Drop\
| ... | Rate) with non-zero packet loss tolerance (LT) expressed in percentage\
| ... | of packets transmitted. NDR and PDR are discovered for different\
| ... | Ethernet L2 frame sizes using either binary search or linear search\
| ... | algorithms with configured starting rate and final step that determines\
| ... | throughput measurement resolution. Test packets are generated by TG on\
| ... | links to DUTs. TG traffic profile contains two L3 flow-groups\
| ... | (flow-group per direction, 253 flows per flow-group) with\
| ... | all packets containing Ethernet header,IPv6 header with static payload.\
| ... | MAC addresses are matching MAC addresses of the TG node interfaces.
| ... | *[Ref] Applicable standard specifications:* SRv6 Network Programming -\
| ... | draft 3.

*** Variables ***
# X520-DA2 bandwidth limit
| ${s_limit}= | ${10000000000}
# SIDs
| ${dut1_sid1}= | 2002:1::
| ${dut1_sid2_1}= | 2003:2::
| ${dut1_sid2_2}= | 2003:3::
| ${dut1_bsid}= | 2002:1::1
| ${dut2_sid1_1}= | 2002:2::
| ${dut2_sid1_2}= | 2002:3::
| ${dut2_sid2}= | 2003:1::
| ${dut2_bsid}= | 2002:2::1
| ${sid_prefix}= | ${64}
# IP settings
| ${tg_if1_ip6_subnet}= | 2001:1::
| ${tg_if2_ip6_subnet}= | 2001:2::
| ${dst_addr_nr}= | ${1}
| ${dut1_if1_ip6}= | 2001:1::1
| ${dut1_if2_ip6}= | 2001:3::1
| ${dut2_if1_ip6}= | 2001:3::2
| ${dut2_if2_ip6}= | 2001:2::1
| ${prefix}= | ${64}
# outer IPv6 header + SRH with 2 SIDs: 40+40B
| ${srv6_overhead_2sids}= | ${80}
# Traffic profile:
| ${traffic_profile}= | trex-sl-3n-ethip6-ip6src253

*** Keywords ***
| Discover NDR or PDR for IPv6 routing over SRv6
| | ...
| | [Arguments] | ${wt} | ${rxq} | ${framesize} | ${min_rate} | ${search_type}
| | ...
| | Set Test Variable | ${framesize}
| | Set Test Variable | ${min_rate}
| | ${get_framesize}= | Get Frame Size | ${framesize}
| | ${max_rate}= | Calculate pps | ${s_limit}
| | ... | ${get_framesize} + ${srv6_overhead_2sids}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '${wt}' worker threads and '${rxq}' rxqueues in 3-node single-link circular topology
| | And Add PCI devices to all DUTs
| | And Run Keyword If | ${get_framesize} < ${1522} | Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When Initialize IPv6 forwarding over SRv6 with encapsulation with '2' x SID 'without' decapsulation in 3-node circular topology
| | Then Run Keyword If | '${search_type}' == 'NDR'
| | ... | Find NDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}
| | ... | ELSE IF | '${search_type}' == 'PDR'
| | ... | Find PDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}
| | ... | ${perf_pdr_loss_acceptance} | ${perf_pdr_loss_acceptance_type}

*** Test Cases ***
| tc01-78B-1t1c-ethip6srhip6-ip6base-srv6enc2sids-nodecaps-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs IPv6 over SRv6 routing config with\
| | ... | 1 phy core, 1 receive queue per NIC port.
| | ... | [Ver] Find NDR for 78 Byte frames using binary search start at 10GE\
| | ... | linerate, step 50kpps.
| | ...
| | [Tags] | 78B | 1C | NDRDISC
| | ...
| | [Template] | Discover NDR or PDR for IPv6 routing over SRv6
| | wt=1 | rxq=1 | framesize=${78} | min_rate=${50000} | search_type=NDR

| tc02-78B-1t1c-ethip6srhip6-ip6base-srv6enc2sids-nodecaps-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs IPv6 over SRv6 routing config with\
| | ... | 1 phy core, 1 receive queue per NIC port.
| | ... | [Ver] Find PDR for 78 Byte frames using binary search start at 10GE\
| | ... | linerate, step 50kpps, LT=0.5%.
| | ...
| | [Tags] | 78B | 1C | PDRDISC | SKIP_PATCH
| | ...
| | [Template] | Discover NDR or PDR for IPv6 routing over SRv6
| | wt=1 | rxq=1 | framesize=${78} | min_rate=${50000} | search_type=PDR

| tc03-78B-2t2c-ethip6srhip6-ip6base-srv6enc2sids-nodecaps-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs IPv6 over SRv6 routing config with\
| | ... | 2 phy cores, 1 receive queue per NIC port.
| | ... | [Ver] Find NDR for 78 Byte frames using binary search start at 10GE\
| | ... | linerate, step 50kpps.
| | ...
| | [Tags] | 78B | 2C | NDRDISC
| | ...
| | [Template] | Discover NDR or PDR for IPv6 routing over SRv6
| | wt=2 | rxq=1 | framesize=${78} | min_rate=${50000} | search_type=NDR

| tc04-78B-2t2c-ethip6srhip6-ip6base-srv6enc2sids-nodecaps-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs IPv6 over SRv6 routing config with\
| | ... | 2 phy cores, 1 receive queue per NIC port.
| | ... | [Ver] Find PDR for 78 Byte frames using binary search start at 10GE\
| | ... | linerate, step 50kpps, LT=0.5%.
| | ...
| | [Tags] | 78B | 2C | PDRDISC | SKIP_PATCH
| | ...
| | [Template] | Discover NDR or PDR for IPv6 routing over SRv6
| | wt=2 | rxq=1 | framesize=${78} | min_rate=${50000} | search_type=PDR

| tc05-78B-4t4c-ethip6srhip6-ip6base-srv6enc2sids-nodecaps-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs IPv6 over SRv6 routing config with\
| | ... | 4 phy cores, 2 receive queues per NIC port.
| | ... | [Ver] Find NDR for 78 Byte frames using binary search start at 10GE\
| | ... | linerate, step 50kpps.
| | ...
| | [Tags] | 78B | 4C | NDRDISC
| | ...
| | [Template] | Discover NDR or PDR for IPv6 routing over SRv6
| | wt=4 | rxq=2 | framesize=${78} | min_rate=${50000} | search_type=NDR

| tc06-78B-4t4c-ethip6srhip6-ip6base-srv6enc2sids-nodecaps-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs IPv6 over SRv6 routing config with\
| | ... | 4 phy cores, 2 receive queues per NIC port.
| | ... | [Ver] Find PDR for 78 Byte frames using binary search start at 10GE\
| | ... | linerate, step 50kpps, LT=0.5%.
| | ...
| | [Tags] | 78B | 4C | PDRDISC | SKIP_PATCH
| | ...
| | [Template] | Discover NDR or PDR for IPv6 routing over SRv6
| | wt=4 | rxq=2 | framesize=${78} | min_rate=${50000} | search_type=PDR

| tc07-1518B-1t1c-ethip6srhip6-ip6base-srv6enc2sids-nodecaps-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs IPv6 over SRv6 routing config with\
| | ... | 1 phy core, 1 receive queue per NIC port.
| | ... | [Ver] Find NDR for 1518 Byte frames using binary search start at 10GE\
| | ... | linerate, step 50kpps.
| | ...
| | [Tags] | 1518B | 1C | NDRDISC
| | ...
| | [Template] | Discover NDR or PDR for IPv6 routing over SRv6
| | wt=1 | rxq=1 | framesize=${1518} | min_rate=${50000} | search_type=NDR

| tc08-1518B-1t1c-ethip6srhip6-ip6base-srv6enc2sids-nodecaps-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs IPv6 over SRv6 routing config with\
| | ... | 1 phy core, 1 receive queue per NIC port.
| | ... | [Ver] Find PDR for 1518 Byte frames using binary search start at 10GE\
| | ... | linerate, step 50kpps, LT=0.5%.
| | ...
| | [Tags] | 1518B | 1C | PDRDISC | SKIP_PATCH
| | ...
| | [Template] | Discover NDR or PDR for IPv6 routing over SRv6
| | wt=1 | rxq=1 | framesize=${1518} | min_rate=${50000} | search_type=PDR

| tc09-1518B-2t2c-ethip6srhip6-ip6base-srv6enc2sids-nodecaps-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs IPv6 over SRv6 routing config with\
| | ... | 2 phy cores, 1 receive queue per NIC port.
| | ... | [Ver] Find NDR for 1518 Byte frames using binary search start at 10GE\
| | ... | linerate, step 50kpps.
| | ...
| | [Tags] | 1518B | 2C | NDRDISC
| | ...
| | [Template] | Discover NDR or PDR for IPv6 routing over SRv6
| | wt=2 | rxq=1 | framesize=${1518} | min_rate=${50000} | search_type=NDR

| tc10-1518B-2t2c-ethip6srhip6-ip6base-srv6enc2sids-nodecaps-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs IPv6 over SRv6 routing config with\
| | ... | 2 phy cores, 1 receive queue per NIC port.
| | ... | [Ver] Find PDR for 1518 Byte frames using binary search start at 10GE\
| | ... | linerate, step 50kpps, LT=0.5%.
| | ...
| | [Tags] | 1518B | 2C | PDRDISC | SKIP_PATCH
| | ...
| | [Template] | Discover NDR or PDR for IPv6 routing over SRv6
| | wt=2 | rxq=1 | framesize=${1518} | min_rate=${50000} | search_type=PDR

| tc11-1518B-4t4c-ethip6srhip6-ip6base-srv6enc2sids-nodecaps-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs IPv6 over SRv6 routing config with\
| | ... | 4 phy cores, 2 receive queues per NIC port.
| | ... | [Ver] Find NDR for 1518 Byte frames using binary search start at 10GE\
| | ... | linerate, step 50kpps.
| | ...
| | [Tags] | 1518B | 4C | NDRDISC
| | ...
| | [Template] | Discover NDR or PDR for IPv6 routing over SRv6
| | wt=4 | rxq=2 | framesize=${1518} | min_rate=${50000} | search_type=NDR

| tc12-1518B-4t4c-ethip6srhip6-ip6base-srv6enc2sids-nodecaps-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs IPv6 over SRv6 routing config with\
| | ... | 4 phy cores, 2 receive queues per NIC port.
| | ... | [Ver] Find PDR for 1518 Byte frames using binary search start at 10GE\
| | ... | linerate, step 50kpps, LT=0.5%.
| | ...
| | [Tags] | 1518B | 4C | PDRDISC | SKIP_PATCH
| | ...
| | [Template] | Discover NDR or PDR for IPv6 routing over SRv6
| | wt=4 | rxq=2 | framesize=${1518} | min_rate=${50000} | search_type=PDR
