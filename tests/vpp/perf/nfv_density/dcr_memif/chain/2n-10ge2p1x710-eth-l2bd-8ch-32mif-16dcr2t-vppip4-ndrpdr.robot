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
| ... | NIC_Intel-X710 | ETH | L2BDMACLRN | BASE | MEMIF | DOCKER | 8R2C
| ... | NF_DENSITY | CHAIN | NF_VPPIP4 | 16DCR2T | DRV_VFIO_PCI
| ... | RXQ_SIZE_0 | TXQ_SIZE_0
| ... | eth-l2bd-8ch-32mif-16dcr2t-vppip4
|
| Suite Setup | Setup suite single link | performance
| Suite Teardown | Tear down suite | performance
| Test Setup | Setup test | performance
| Test Teardown | Tear down test | performance | container
|
| Test Template | Local Template
|
| Documentation | **RFC2544: Pkt throughput L2BD test cases with memif 8 chains
| ... | 16 docker container*
|
| ... | *[Top] Network Topologies:* TG-DUT1-TG 2-node circular topology with
| ... | single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv4 for L2 bridge domain.
| ... | *[Cfg] DUT configuration:* DUT1 is configured with two L2 bridge domains
| ... | and MAC learning enabled. DUT1 tested with ${nic_name}.\
| ... | Container is connected to VPP via Memif interface. Container is running
| ... | same VPP version as running on DUT. Container is limited via cgroup to
| ... | use cores allocated from pool of isolated CPUs. There are no memory
| ... | contraints.
| ... | *[Ver] TG verification:* TG finds and reports throughput NDR (Non Drop\
| ... | Rate) with zero packet loss tolerance and throughput PDR (Partial Drop\
| ... | Rate) with non-zero packet loss tolerance (LT) expressed in percentage\
| ... | of packets transmitted. NDR and PDR are discovered for different\
| ... | Ethernet L2 frame sizes using MLRsearch library.\
| ... | Test packets are generated by TG on links to DUTs. TG traffic profile
| ... | contains two L3 flow-groups (flow-group per direction, 254 flows per
| ... | flow-group) with all packets containing Ethernet header, IPv4 header
| ... | with IP protocol=61 and static payload. MAC addresses are matching MAC
| ... | addresses of the TG node interfaces.

*** Variables ***
| @{plugins_to_enable}= | dpdk_plugin.so | memif_plugin.so
| ${crypto_type}= | ${None}
| ${nic_name}= | Intel-X710
| ${nic_driver}= | vfio-pci
| ${nic_rxq_size}= | 0
| ${nic_txq_size}= | 0
| ${osi_layer}= | L2
| ${overhead}= | ${0}
| ${nf_dtcr}= | ${1}
| ${nf_dtc}= | ${1}
| ${nf_chains}= | ${8}
| ${nf_nodes}= | ${2}
# Traffic profile:
| ${traffic_profile}= | trex-sl-2n3n-ethip4-ip4src254-8c2n
# Container
| ${container_engine}= | Docker
| ${container_chain_topology}= | chain_ip4

*** Keywords ***
| Local Template
| | [Documentation]
| | ... | [Cfg] DUT runs L2BD switching config.
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
| |
| | Given Set Max Rate And Jumbo
| | And Add worker threads to all DUTs | ${phy_cores} | ${rxq}
| | And Pre-initialize layer driver | ${nic_driver}
| | And Apply startup configuration on all VPP DUTs
| | When Initialize layer driver | ${nic_driver}
| | And Initialize layer interface
| | ... | count=${nf_chains}
| | And Start containers for test
| | ... | nf_chains=${nf_chains} | nf_nodes=${nf_nodes} | auto_scale=${False}
| | And Initialize L2 Bridge Domain for multiple chains with memif pairs
| | ... | nf_chains=${nf_chains} | nf_nodes=${nf_nodes} | auto_scale=${False}
| | Then Find NDR and PDR intervals using optimized search

*** Test Cases ***
| tc01-64B-1c-eth-l2bd-8ch-32mif-16dcr2t-vppip4-ndrpdr
| | [Tags] | 64B | 1C
| | frame_size=${64} | phy_cores=${1}

| tc02-64B-2c-eth-l2bd-8ch-32mif-16dcr2t-vppip4-ndrpdr
| | [Tags] | 64B | 2C
| | frame_size=${64} | phy_cores=${2}

| tc04-1518B-1c-eth-l2bd-8ch-32mif-16dcr2t-vppip4-ndrpdr
| | [Tags] | 1518B | 1C
| | frame_size=${1518} | phy_cores=${1}

| tc05-1518B-2c-eth-l2bd-8ch-32mif-16dcr2t-vppip4-ndrpdr
| | [Tags] | 1518B | 2C
| | frame_size=${1518} | phy_cores=${2}

| tc07-9000B-1c-eth-l2bd-8ch-32mif-16dcr2t-vppip4-ndrpdr
| | [Tags] | 9000B | 1C
| | frame_size=${9000} | phy_cores=${1}

| tc08-9000B-2c-eth-l2bd-8ch-32mif-16dcr2t-vppip4-ndrpdr
| | [Tags] | 9000B | 2C
| | frame_size=${9000} | phy_cores=${2}

| tc10-IMIX-1c-eth-l2bd-8ch-32mif-16dcr2t-vppip4-ndrpdr
| | [Tags] | IMIX | 1C
| | frame_size=IMIX_v4_1 | phy_cores=${1}

| tc11-IMIX-2c-eth-l2bd-8ch-32mif-16dcr2t-vppip4-ndrpdr
| | [Tags] | IMIX | 2C
| | frame_size=IMIX_v4_1 | phy_cores=${2}
