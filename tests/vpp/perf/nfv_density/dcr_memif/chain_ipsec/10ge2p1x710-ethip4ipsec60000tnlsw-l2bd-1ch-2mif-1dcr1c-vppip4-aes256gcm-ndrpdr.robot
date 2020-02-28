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
| Force Tags | 3_NODE_SINGLE_LINK_TOPO | PERFTEST | HW_ENV | NDRPDR | TNL_60000
| ... | IPSEC | IPSECSW | IPSECINT | NIC_Intel-X710 | SCALE | 1DCR
| ... | DOCKER | 2R1C | NF_DENSITY | CHAIN | NF_VPPIP4 | 1DCR1T
| ... | AES_256_GCM | AES | DRV_VFIO_PCI
| ... | RXQ_SIZE_0 | TXQ_SIZE_0
| ... | ethip4ipsec60000tnlsw-l2bd-1ch-2mif-1dcr1c-vppip4-aes256gcm
|
| Suite Setup | Setup suite single link | performance
| Suite Teardown | Tear down suite | performance
| Test Setup | Setup test | performance
| Test Teardown | Tear down test | performance | container
|
| Test Template | Local Template
|
| Documentation | **RFC2544: Pkt throughput L2BD test cases with memif 1 chain
| ... | 1 docker container*
|
| ... | *[Top] Network Topologies:* TG-DUT1-DUT2-TG 3-node circular topology
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv4 for L2 bridge domain.
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
| ... | *[Ref] Applicable standard specifications:* RFC4303 and RFC2544.

*** Variables ***
| @{plugins_to_enable}= | dpdk_plugin.so | memif_plugin.so
| ... | crypto_native_plugin.so | crypto_ipsecmb_plugin.so
| ... | crypto_openssl_plugin.so
| ${crypto_type}= | ${None}
| ${nic_name}= | Intel-X710
| ${nic_driver}= | vfio-pci
| ${nic_rxq_size}= | 0
| ${nic_txq_size}= | 0
| ${osi_layer}= | L2
| ${overhead}= | ${54}
| ${tg_if1_ip4}= | 192.168.10.254
| ${dut1_if1_ip4}= | 192.168.10.1
| ${dut1_if2_ip4}= | 100.0.0.254
| ${dut2_if1_ip4}= | 200.0.0.1
| ${dut2_if2_ip4}= | 192.168.20.1
| ${tg_if2_ip4}= | 192.168.20.254
| ${raddr_ip4}= | 20.0.0.0
| ${laddr_ip4}= | 10.0.0.0
| ${addr_range}= | ${24}
| ${n_instances}= | ${1}
| ${n_tunnels}= | ${60000}
| ${nf_dtcr}= | ${1}
| ${nf_dtc}= | ${1}
# Traffic profile:
| ${traffic_profile}= | trex-sl-3n-ethip4-ip4dst${n_tunnels}-${n_instances}cnf
# Container
| ${container_engine}= | Docker
| ${container_chain_topology}= | chain_ipsec

*** Keywords ***
| Local Template
| | [Documentation]
| | ... | [Cfg] DUT1 runs IPSec tunneling AES_256_GCM config to ${n_instances}.
| | ... | containers.
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
| | # These are enums (not strings) so they cannot be in Variables table.
| | ${encr_alg}= | Crypto Alg AES GCM 256
| | ${auth_alg}= | Set Variable | ${None}
| | ${ipsec_proto} = | IPsec Proto ESP
| |
| | Given Set Max Rate And Jumbo
| | And Add worker threads to all DUTs | ${phy_cores} | ${rxq}
| | And Pre-initialize layer driver | ${nic_driver}
| | And Apply startup configuration on all VPP DUTs
| | When Initialize layer driver | ${nic_driver}
| | And Initialize IPSec in 3-node circular topology
| | And Stop VPP service on all DUTs | ${nodes}
| | And VPP IPsec Create Tunnel Interfaces in Containers
| | ... | ${nodes} | ${dut1_if2_ip4} | ${dut2_if1_ip4} | ${dut1_if2}
| | ... | ${dut2_if1} | ${n_tunnels} | ${encr_alg} | ${auth_alg}
| | ... | ${laddr_ip4} | ${raddr_ip4} | ${addr_range} | ${n_instances}
| | And Start containers for test
| | ... | nf_chains=${1} | nf_nodes=${n_instances} | auto_scale=${False}
| | ... | pinning=${False}
| | And Start vswitch in container | phy_cores=${phy_cores} | rx_queues=${rxq}
| | Then Find NDR and PDR intervals using optimized search

*** Test Cases ***
| tc01-64B-1c-ethip4ipsec60000tnlsw-l2bd-1ch-2mif-1dcr1c-vppip4-aes256gcm-ndrpdr
| | [Tags] | 64B | 1C
| | frame_size=${64} | phy_cores=${1}

| tc02-64B-2c-ethip4ipsec60000tnlsw-l2bd-1ch-2mif-1dcr1c-vppip4-aes256gcm-ndrpdr
| | [Tags] | 64B | 2C
| | frame_size=${64} | phy_cores=${2}

| tc03-64B-4c-ethip4ipsec60000tnlsw-l2bd-1ch-2mif-1dcr1c-vppip4-aes256gcm-ndrpdr
| | [Tags] | 64B | 4C
| | frame_size=${64} | phy_cores=${4}

| tc04-1518B-1c-ethip4ipsec60000tnlsw-l2bd-1ch-2mif-1dcr1c-vppip4-aes256gcm-ndrpdr
| | [Tags] | 1518B | 1C
| | frame_size=${1518} | phy_cores=${1}

| tc05-1518B-2c-ethip4ipsec60000tnlsw-l2bd-1ch-2mif-1dcr1c-vppip4-aes256gcm-ndrpdr
| | [Tags] | 1518B | 2C
| | frame_size=${1518} | phy_cores=${2}

| tc06-1518B-4c-ethip4ipsec60000tnlsw-l2bd-1ch-2mif-1dcr1c-vppip4-aes256gcm-ndrpdr
| | [Tags] | 1518B | 4C
| | frame_size=${1518} | phy_cores=${4}

| tc10-IMIX-1c-ethip4ipsec60000tnlsw-l2bd-1ch-2mif-1dcr1c-vppip4-aes256gcm-ndrpdr
| | [Tags] | IMIX | 1C
| | frame_size=IMIX_v4_1 | phy_cores=${1}

| tc11-IMIX-2c-ethip4ipsec60000tnlsw-l2bd-1ch-2mif-1dcr1c-vppip4-aes256gcm-ndrpdr
| | [Tags] | IMIX | 2C
| | frame_size=IMIX_v4_1 | phy_cores=${2}

| tc12-IMIX-4c-ethip4ipsec60000tnlsw-l2bd-1ch-2mif-1dcr1c-vppip4-aes256gcm-ndrpdr
| | [Tags] | IMIX | 4C
| | frame_size=IMIX_v4_1 | phy_cores=${4}
