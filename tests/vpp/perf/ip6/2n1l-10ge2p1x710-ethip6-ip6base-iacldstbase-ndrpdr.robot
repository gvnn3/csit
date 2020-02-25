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
| ... | NIC_Intel-X710 | ETH | IP6FWD | FEATURE | IACLDST | DRV_VFIO_PCI
| ... | ethip6-ip6base-iacldstbase
|
| Suite Setup | Setup suite single link | performance
| Suite Teardown | Tear down suite | performance
| Test Setup | Setup test | performance | performance
| Test Teardown | Tear down test | performance | classify
|
| Test Template | Local Template
|
| Documentation | *RFC2544: Pkt throughput IPv6 iAcl whitelist test cases*
|
| ... | *[Top] Network Topologies:* TG-DUT1-TG 2-node circular topology
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv6 for IPv6 routing.
| ... | *[Cfg] DUT configuration:* DUT1 is configured with IPv6
| ... | routing, two static IPv6 /64 routes and IPv6 iAcl security whitelist
| ... | ingress /64 filter entries applied on links TG - DUT1.
| ... | DUT1 is tested with ${nic_name}.\
| ... | *[Ver] TG verification:* TG finds and reports throughput NDR (Non Drop\
| ... | Rate) with zero packet loss tolerance and throughput PDR (Partial Drop\
| ... | Rate) with non-zero packet loss tolerance (LT) expressed in percentage\
| ... | of packets transmitted. NDR and PDR are discovered for different\
| ... | Ethernet L2 frame sizes using MLRsearch library.\
| ... | Test packets are generated by TG on
| ... | links to DUTs. TG traffic profile contains two L3 flow-groups
| ... | (flow-group per direction, 253 flows per flow-group) with all packets
| ... | containing Ethernet header, IPv6 header and generated payload. MAC
| ... | addresses are matching MAC addresses of the TG node interfaces.
| ... | *[Ref] Applicable standard specifications:* RFC2544.

*** Variables ***
| @{plugins_to_enable}= | dpdk_plugin.so
| ${crypto_type}= | ${None}
| ${nic_name}= | Intel-X710
| ${nic_driver}= | vfio-pci
| ${osi_layer}= | L3
| ${overhead}= | ${0}
# Traffic profile:
| ${traffic_profile}= | trex-sl-2n-ethip6-ip6src253

*** Keywords ***
| Local Template
| | [Documentation]
| | ... | [Cfg] DUT runs IPv6 routing and whitelist filters config with
| | ... | ${phy_cores} phy core(s).
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
| |
| | Given Set Max Rate And Jumbo
| | And Add worker threads to all DUTs | ${phy_cores} | ${rxq}
| | And Pre-initialize layer driver | ${nic_driver}
| | And Apply startup configuration on all VPP DUTs
| | When Initialize layer driver | ${nic_driver}
| | And Initialize layer interface
| | And Initialize IPv6 forwarding in circular topology
| | ${table_idx} | ${skip_n} | ${match_n}= | And Vpp Creates Classify Table L3
| | ... | ${dut1} | ip6 | dst | ffff:ffff:ffff:ffff:ffff:ffff:ffff:0
| | And Vpp Configures Classify Session L3
| | ... | ${dut1} | permit | ${table_idx} | ${skip_n} | ${match_n} | ip6 | dst
| | ... | 2001:2::0
| | And Vpp Enable Input Acl Interface
| | ... | ${dut1} | ${dut1_if1} | ip6 | ${table_idx}
| | And Vpp Configures Classify Session L3
| | ... | ${dut1} | permit | ${table_idx} | ${skip_n} | ${match_n} | ip6 | dst
| | ... | 2001:1::0
| | And Vpp Enable Input Acl Interface
| | ... | ${dut1} | ${dut1_if2} | ip6 | ${table_idx}
| | Then Find NDR and PDR intervals using optimized search

*** Test Cases ***
| tc01-78B-1c-ethip6-ip6base-iacldstbase-ndrpdr
| | [Tags] | 78B | 1C
| | frame_size=${78} | phy_cores=${1}

| tc02-78B-2c-ethip6-ip6base-iacldstbase-ndrpdr
| | [Tags] | 78B | 2C
| | frame_size=${78} | phy_cores=${2}

| tc03-78B-4c-ethip6-ip6base-iacldstbase-ndrpdr
| | [Tags] | 78B | 4C
| | frame_size=${78} | phy_cores=${4}

| tc04-1518B-1c-ethip6-ip6base-iacldstbase-ndrpdr
| | [Tags] | 1518B | 1C
| | frame_size=${1518} | phy_cores=${1}

| tc05-1518B-2c-ethip6-ip6base-iacldstbase-ndrpdr
| | [Tags] | 1518B | 2C
| | frame_size=${1518} | phy_cores=${2}

| tc06-1518B-4c-ethip6-ip6base-iacldstbase-ndrpdr
| | [Tags] | 1518B | 4C
| | frame_size=${1518} | phy_cores=${4}

| tc07-9000B-1c-ethip6-ip6base-iacldstbase-ndrpdr
| | [Tags] | 9000B | 1C
| | frame_size=${9000} | phy_cores=${1}

| tc08-9000B-2c-ethip6-ip6base-iacldstbase-ndrpdr
| | [Tags] | 9000B | 2C
| | frame_size=${9000} | phy_cores=${2}

| tc09-9000B-4c-ethip6-ip6base-iacldstbase-ndrpdr
| | [Tags] | 9000B | 4C
| | frame_size=${9000} | phy_cores=${4}

| tc10-IMIX-1c-ethip6-ip6base-iacldstbase-ndrpdr
| | [Tags] | IMIX | 1C
| | frame_size=IMIX_v4_1 | phy_cores=${1}

| tc11-IMIX-2c-ethip6-ip6base-iacldstbase-ndrpdr
| | [Tags] | IMIX | 2C
| | frame_size=IMIX_v4_1 | phy_cores=${2}

| tc12-IMIX-4c-ethip6-ip6base-iacldstbase-ndrpdr
| | [Tags] | IMIX | 4C
| | frame_size=IMIX_v4_1 | phy_cores=${4}
