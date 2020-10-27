# Copyright (c) 2020 Cisco and/or its affiliates.
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
| Resource | resources/libraries/robot/shared/default.robot
|
| Force Tags | 2_NODE_SINGLE_LINK_TOPO | PERFTEST | HW_ENV | NDRPDR
| ... | NIC_Intel-X710 | ETH | IP4FWD | NAT44 | UDP | UDP_PPS | DRV_VFIO_PCI
| ... | SCALE | HOSTS_16384 | RXQ_SIZE_0 | TXQ_SIZE_0
| ... | ethip4udp-nat44ed-h16384-p63-s1032192-pps
|
| Suite Setup | Setup suite topology interfaces | performance
| Suite Teardown | Tear down suite | performance
| Test Setup | Setup test | performance
| Test Teardown | Tear down test | performance | nat-ed
|
| Test Template | Local Template
|
| # TODO CSIT-1765: Unify suite Documentation.
| Documentation | *PPS on lightweight UDP transactions with NAT44ED*
|
| ... | *[Top] Network Topologies:* TG-DUT1-TG 2-node circular topology\
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv4-UDP for IPv4 routing.
| ... | *[Cfg] DUT configuration:* DUT1 is configured with IPv4\
| ... | routing and two static IPv4 /24 route entries. DUT1 tested with\
| ... | ${nic_name}.
| ... | *[Ver] TG verification:* TG finds and reports throughput NDR (Non Drop\
| ... | Rate) with zero packet loss tolerance and throughput PDR (Partial Drop\
| ... | Rate) with non-zero packet loss tolerance (LT) expressed in percentage\
| ... | of packets transmitted. NDR and PDR are discovered for different\
| ... | Ethernet L2 frame sizes using MLRsearch library.\
| ... | Test packets are generated by TG on links to DUTs. TG traffic profile\
| ... | contains client and server ASTF programs, generating packets containing\
| ... | Ethernet header, IPv4 header, UDP header and static payload.\
| ... | MAC addresses are matching MAC addresses of the TG node interfaces.
| ... | *[Ref] Applicable standard specifications:* RFC2544.

*** Variables ***
| @{plugins_to_enable}= | dpdk_plugin.so | nat_plugin.so
| ${crypto_type}= | ${None}
| ${nic_name}= | Intel-X710
| ${nic_driver}= | vfio-pci
| ${nic_rxq_size}= | 0
| ${nic_txq_size}= | 0
| ${nic_pfs}= | 2
| ${nic_vfs}= | 0
| ${osi_layer}= | L7
| ${overhead}= | ${0}
# IP settings
| ${tg_if1_ip4}= | 10.0.0.2
| ${tg_if1_mask}= | ${20}
| ${tg_if2_ip4}= | 12.0.0.2
| ${tg_if2_mask}= | ${20}
| ${dut1_if1_ip4}= | 10.0.0.1
| ${dut1_if1_mask}= | ${24}
| ${dut1_if2_ip4}= | 12.0.0.1
| ${dut1_if2_mask}= | ${24}
| ${dest_net}= | 20.0.0.0
| ${dest_mask}= | ${18}
# NAT settings
| ${nat_mode}= | endpoint-dependent
| ${in_net}= | 192.168.0.0
| ${in_mask}= | ${18}
| ${out_net}= | 68.142.68.0
| ${out_net_end}= | 68.142.68.15
| ${out_mask}= | ${28}
# Scale settings
| ${n_hosts}= | ${16384}
| ${n_ports}= | ${63}
| ${n_sessions}= | ${${n_hosts} * ${n_ports}}
| ${transaction_scale}= | ${n_sessions}
| ${packets_per_transaction_and_direction}= | ${33}
# Traffic profile
| ${traffic_profile}= | trex-astf-ethip4udp-${n_hosts}h-pps
| ${transaction_type}= | udp_pps
| ${disable_latency}= | ${True}

*** Keywords ***
| Local Template
| | [Documentation]
| | ... | [Cfg] DUT runs NAT44 ${nat_mode} configuration.\
| | ... | Each DUT uses ${phy_cores} physical core(s) for worker threads.
| | ... | [Ver] Measure NDR and PDR values using MLRsearch algorithm.\
| |
| | ... | *Arguments:*
| | ... | - frame_size - Framesize in Bytes in integer or string (IMIX_v4_1).
| | ... | Type: integer, string
| | ... | - phy_cores - Number of physical cores. Type: integer
| | ... | - rxq - Number of RX queues, default value: ${None}. Type: integer
| |
| | [Arguments] | ${frame_size} | ${phy_cores} | ${rxq}=${None}
| |
| | Set Test Variable | \${frame_size}
| | ${pre_stats}= | Create List
| | ... | vpp-clear-stats | vpp-enable-packettrace | vpp-enable-elog
| | ... | vpp-clear-runtime
| | Set Test Variable | ${pre_stats}
| | ${post_stats}= | Create List
| | ... | vpp-show-stats | vpp-show-packettrace | vpp-show-elog
| | ... | vpp-show-runtime
| | Set Test Variable | ${post_stats}
| |
| | Given Set Max Rate And Jumbo
| | And Add worker threads to all DUTs | ${phy_cores} | ${rxq}
| | And Pre-initialize layer driver | ${nic_driver}
| | And Apply startup configuration on all VPP DUTs
| | When Initialize layer driver | ${nic_driver}
| | And Initialize layer interface
| | And Initialize IPv4 forwarding for NAT44 in circular topology
| | And Initialize NAT44 endpoint-dependent mode in circular topology
| | Then Find NDR and PDR intervals using optimized search

*** Test Cases ***
| 64B-1c-ethip4udp-nat44ed-h16384-p63-s1032192-pps-ndrpdr
| | [Tags] | 64B | 1C
| | frame_size=${64} | phy_cores=${1}

| 64B-2c-ethip4udp-nat44ed-h16384-p63-s1032192-pps-ndrpdr
| | [Tags] | 64B | 2C
| | frame_size=${64} | phy_cores=${2}

| 64B-4c-ethip4udp-nat44ed-h16384-p63-s1032192-pps-ndrpdr
| | [Tags] | 64B | 4C
| | frame_size=${64} | phy_cores=${4}
