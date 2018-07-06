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
| Library | resources.libraries.python.QemuUtils
| Force Tags | 3_NODE_SINGLE_LINK_TOPO | PERFTEST | HW_ENV | NDRPDRDISC
| ... | NIC_Intel-X520-DA2 | L2BDMACLRN | ENCAP | VXLAN | L2OVRLAY | IP4UNRLAY
| ... | VHOST | VM | VHOST_1024 | VTS
| ...
| Suite Setup | Run Keywords
| ... | Set up 3-node performance topology with DUT's NIC model
| ... | L3 | Intel-X520-DA2
| ... | AND | Set up performance test suite with ACL
| Suite Teardown | Tear down 3-node performance topology
| ...
| Test Setup | Set up performance test
| Test Teardown | Tear down performance test with vhost and VM with dpdk-testpmd and ACL
| ... | ${min_rate}pps | ${framesize} | ${traffic_profile}
| ... | dut1_node=${dut1} | dut1_vm_refs=${dut1_vm_refs}
| ...
| Documentation | *RFC2544: Packet throughput L2BD test cases with VXLANoIPv4
| ... | and vhost*
| ...
| ... | *[Top] Network Topologies:* TG-DUT1-DUT2-TG 3-node circular topology
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv4 for L2 switching of IPv4.
| ... | Eth-IPv4-VXLAN-Eth-IPv4 is applied on link between DUT1 and DUT2.
| ... | *[Cfg] DUT configuration:* DUT1 and DUT2 are configured with L2 bridge-
| ... | domain and MAC learning enabled. Qemu Guest is connected to VPP via
| ... | vhost-user interfaces. Guest is running DPDK testpmd interconnecting
| ... | vhost-user interfaces using 5 cores pinned to cpus 5-9 and 2048M
| ... | memory. Testpmd is using socket-mem=1024M (512x2M hugepages), 5 cores
| ... | (1 main core and 4 cores dedicated for io), forwarding mode is set to
| ... | io, rxd/txd=256, burst=64. DUT1, DUT2 are tested with 2p10GE NIC X520
| ... | Niantic by Intel.
| ... | *[Ver] TG verification:* TG finds and reports throughput NDR (Non Drop
| ... | Rate) with zero packet loss tolerance or throughput PDR (Partial Drop
| ... | Rate) with non-zero packet loss tolerance (LT) expressed in percentage
| ... | of packets transmitted. NDR and PDR are discovered for different
| ... | Ethernet L2 frame sizes using either binary search or linear search
| ... | algorithms with configured starting rate and final step that determines
| ... | throughput measurement resolution. Test packets are generated by TG on
| ... | links to DUTs. TG traffic profile contains two L3 flow-groups
| ... | (flow-group per direction, 253 flows per flow-group) with all packets
| ... | containing Ethernet header, IPv4 header with IP protocol=61 and static
| ... | payload. MAC addresses are matching MAC addresses of the TG node
| ... | interfaces.
| ... | *[Ref] Applicable standard specifications:* RFC2544, RFC7348.

*** Variables ***
| ${perf_qemu_qsz}= | 1024
# X520-DA2 bandwidth limit
| ${s_limit}= | ${10000000000}
| ${vxlan_overhead}= | ${50}
# Socket names
| ${dut1_bd_id1}= | 1
| ${dut1_bd_id2}= | 2
| ${dut2_bd_id1}= | 1
| ${sock1}= | /tmp/sock-1-${dut1_bd_id1}
| ${sock2}= | /tmp/sock-1-${dut1_bd_id2}
# Traffic profile:
| ${traffic_profile} | trex-sl-ethip4-vxlansrc253
| ${min_rate}= | ${10000}


*** Keywords ***
| Configure ACLs on a single interface
| | [Documentation]
| | ... | Configure ACL
| | ...
| | ... | *Arguments:*
| | ... | - dut - DUT node. Type: string
| | ... | - dut_if - DUT node interface name. Type: string
| | ... | - acl_apply_type - To what path apply the ACL - input or output.
| | ... | - acl_action - Action for the rule - deny, permit, permit+reflect.
| | ... | - subnets - Subnets to apply the specific ACL. Type: list
| | ...
| | ... | *Example:*
| | ...
| | ... | \| Configure ACLs on a single interface \| ${nodes['DUT1']}
| | ... | \| ... \| GigabitEthernet0/7/0 \| input \| permit | 0.0.0.0/0
| | ...
| | [Arguments] | ${dut} | ${dut_if} | ${acl_apply_type} | ${acl_action}
| | ... | @{subnets}
| | Set Test variable | ${acl} | ${EMPTY}
| | :FOR | ${subnet} | IN | @{subnets}
| | | ${acl}= | Run Keyword If | '${acl}' == '${EMPTY}'
| | | ... | Set Variable | ipv4 ${acl_action} src ${subnet}
| | | ... | ELSE
| | | ... | Catenate | SEPARATOR=, | ${acl}
| | | ... | ipv4 ${acl_action} src ${subnet}
| | Add Replace Acl Multi Entries | ${dut} | rules=${acl}
| | @{acl_list}= | Create List | ${0}
| | Set Acl List For Interface | ${dut} | ${dut_if} | ${acl_apply_type}
| | ... | ${acl_list}


*** Keywords ***
| Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | [Arguments] | ${num_of_threads} | ${rxq} | ${pkt_framesize} | ${search_type}
| | ... | ${acl_type}=${EMPTY}
| | [Documentation]
| | ... | [Cfg] DUT runs L2BD switching config with 1 phy core,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Find NDR for 64 Byte frames using binary search start at 10GE\
| | ... | linerate, step 10kpps.
| | ...
| | ... | *Arguments:*
| | ... | - num_of_threads - Number of worker threads to be used. Type: integer
| | ... | - rxq - Number of Rx queues to be used. Type: integer
| | ... | - pkt_framesize - L2 Frame Size [B]. Type: integer
| | ... | - search_type - Type of the search - non drop rate (NDR) or partial
| | ... | drop rare (PDR). Type: string
| | ...
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | ${max_pkt_size}= | Set Variable If | '${pkt_framesize}' == 'IMIX_v4_1' |
| | ... | ${1500 + ${vxlan_overhead}} | ${pkt_framesize + ${vxlan_overhead}}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${max_pkt_size}
| | ${binary_max}= | Set Variable | ${max_rate}
| | Given Add '${num_of_threads}' worker threads and '${rxq}' rxqueues in 3-node single-link circular topology
| | Add PCI devices to all DUTs
| | And Run Keyword If | ${max_pkt_size} < ${1522}
| | ... | Add no multi seg to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | &{vxlan1}= | Create Dictionary | vni=24 | vtep=172.17.0.2
| | &{vxlan2}= | Create Dictionary | vni=24 | vtep=172.27.0.2
| | @{dut1_vxlans}= | Create List | ${vxlan1}
| | @{dut2_vxlans}= | Create List | ${vxlan2}
| | ${jumbo_frames}= | Set Variable If
| | ... | ${max_pkt_size} < ${1522} | ${False} | ${True}
| | Set interfaces in path in 3-node circular topology up
| | Configure vhost interfaces for L2BD forwarding | ${dut1}
| | ... | ${sock1} | ${sock2}
| | When Init L2 bridge domains with single DUT with Vhost-User and VXLANoIPv4 in 3-node circular topology
| | ... | 172.16.0.1 | 16 | 172.26.0.1 | 16 | 172.16.0.2 | 172.26.0.2
| | ... | ${dut1_vxlans} | ${dut2_vxlans} | 172.17.0.0 | 16 | 172.27.0.0 | 16
| | @{permit_list}= | Create List | 10.0.0.1/32 | 10.0.0.2/32
| | Run Keyword If | '${acl_type}' != '${EMPTY}'
| | ... | Configure ACLs on a single interface | ${dut1} | ${dut1_if2} | input
| | ... | ${acl_type} | @{permit_list}
| | ${vm1}= | And Configure guest VM with dpdk-testpmd connected via vhost-user
| | ... | ${dut1} | ${sock1} | ${sock2} | DUT1_VM1
| | ... | jumbo_frames=${jumbo_frames}
| | Set Test Variable | &{dut1_vm_refs} | DUT1_VM1=${vm1}
| | Set Test Variable | ${framesize} | ${pkt_framesize}
| | ${pkt_framesize}= | Set Variable If | '${pkt_framesize}' == 'IMIX_v4_1' |
| | ... | ${pkt_framesize} | ${pkt_framesize + ${vxlan_overhead}}
| | Run Keyword If | '${search_type}' == 'NDR'
| | ... | Find NDR using binary search and pps
| | ... | ${pkt_framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}
| | ... | ELSE IF | '${search_type}' == 'PDR'
| | ... | Find PDR using binary search and pps
| | ... | ${pkt_framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}
| | ... | ${perf_pdr_loss_acceptance} | ${perf_pdr_loss_acceptance_type}

*** Test Cases ***
| tc01-64B-1t1c-ethip4vxlan-l2bdbasemaclrn-eth-2vhost-1vm-ndrdisc
| | [Tags] | 64B | 2C | NDRDISC
| | ...
| | [Template] | Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | num_of_threads=2 | rxq=2 | pkt_framesize=${64} | search_type=NDR

| tc02-64B-1t1c-ethip4vxlan-l2bdbasemaclrn-eth-2vhost-1vm-pdrdisc
| | [Tags] | 64B | 2C | PDRDISC
| | ...
| | [Template] | Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | num_of_threads=2 | rxq=2 | pkt_framesize=${64} | search_type=PDR

| tc03-150B-1t1c-ethip4vxlan-l2bdbasemaclrn-eth-2vhost-1vm-ndrdisc
| | [Tags] | 150B | 2C | NDRDISC
| | ...
| | [Template] | Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | num_of_threads=2 | rxq=2 | pkt_framesize=${150} | search_type=NDR

| tc04-150B-1t1c-ethip4vxlan-l2bdbasemaclrn-eth-2vhost-1vm-pdrdisc
| | [Tags] | 150B | 2C | PDRDISC
| | ...
| | [Template] | Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | num_of_threads=2 | rxq=2 | pkt_framesize=${150} | search_type=PDR

| tc05-200B-1t1c-ethip4vxlan-l2bdbasemaclrn-eth-2vhost-1vm-ndrdisc
| | [Tags] | 200B | 2C | NDRDISC
| | ...
| | [Template] | Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | num_of_threads=2 | rxq=2 | pkt_framesize=${200} | search_type=NDR

| tc06-200B-1t1c-ethip4vxlan-l2bdbasemaclrn-eth-2vhost-1vm-pdrdisc
| | [Tags] | 200B | 2C | PDRDISC
| | ...
| | [Template] | Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | num_of_threads=2 | rxq=2 | pkt_framesize=${200} | search_type=PDR

| tc07-IMIX-1t1c-ethip4vxlan-l2bdbasemaclrn-eth-2vhost-1vm-ndrdisc
| | [Tags] | IMIX | 2C | NDRDISC
| | ...
| | [Template] | Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | num_of_threads=2 | rxq=2 | pkt_framesize=IMIX_v4_1 | search_type=NDR

| tc08-IMIX-1t1c-ethip4vxlan-l2bdbasemaclrn-eth-2vhost-1vm-pdrdisc
| | [Tags] | IMIX | 2C | PDRDISC
| | ...
| | [Template] | Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | num_of_threads=2 | rxq=2 | pkt_framesize=IMIX_v4_1 | search_type=PDR

| tc09-64B-1t1c-ethip4vxlan-l2bdbasemaclrn-eth-2vhost-1vm-acl-ndrdisc
| | [Tags] | 64B | 2C | NDRDISC | ACL_PERMIT
| | ...
| | [Template] | Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | num_of_threads=2 | rxq=2 | pkt_framesize=${64} | search_type=NDR
| | ... | acl_type=permit

| tc10-64B-1t1c-ethip4vxlan-l2bdbasemaclrn-eth-2vhost-1vm-acl-pdrdisc
| | [Tags] | 64B | 2C | PDRDISC | ACL_PERMIT
| | ...
| | [Template] | Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | num_of_threads=2 | rxq=2 | pkt_framesize=${64} | search_type=PDR
| | ... | acl_type=permit

| tc11-150B-1t1c-ethip4vxlan-l2bdbasemaclrn-eth-2vhost-1vm-acl-ndrdisc
| | [Tags] | 150B | 2C | NDRDISC | ACL_PERMIT
| | ...
| | [Template] | Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | num_of_threads=2 | rxq=2 | pkt_framesize=${150} | search_type=NDR
| | ... | acl_type=permit

| tc12-150B-1t1c-ethip4vxlan-l2bdbasemaclrn-eth-2vhost-1vm-acl-pdrdisc
| | [Tags] | 150B | 2C | PDRDISC | ACL_PERMIT
| | ...
| | [Template] | Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | num_of_threads=2 | rxq=2 | pkt_framesize=${150} | search_type=PDR
| | ... | acl_type=permit

| tc13-200B-1t1c-ethip4vxlan-l2bdbasemaclrn-eth-2vhost-1vm-acl-ndrdisc
| | [Tags] | 200B | 2C | NDRDISC | ACL_PERMIT
| | ...
| | [Template] | Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | num_of_threads=2 | rxq=2 | pkt_framesize=${200} | search_type=NDR
| | ... | acl_type=permit

| tc14-200B-1t1c-ethip4vxlan-l2bdbasemaclrn-eth-2vhost-1vm-acl-pdrdisc
| | [Tags] | 200B | 2C | PDRDISC | ACL_PERMIT
| | ...
| | [Template] | Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | num_of_threads=2 | rxq=2 | pkt_framesize=${200} | search_type=PDR
| | ... | acl_type=permit

| tc15-IMIX-1t1c-ethip4vxlan-l2bdbasemaclrn-eth-2vhost-1vm-acl-ndrdisc
| | [Tags] | IMIX | 2C | NDRDISC | ACL_PERMIT
| | ...
| | [Template] | Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | num_of_threads=2 | rxq=2 | pkt_framesize=IMIX_v4_1 | search_type=NDR
| | ... | acl_type=permit

| tc16-IMIX-1t1c-ethip4vxlan-l2bdbasemaclrn-eth-2vhost-1vm-acl-pdrdisc
| | [Tags] | IMIX | 2C | PDRDISC | ACL_PERMIT
| | ...
| | [Template] | Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | num_of_threads=2 | rxq=2 | pkt_framesize=IMIX_v4_1 | search_type=PDR
| | ... | acl_type=permit

| tc17-64B-1t1c-ethip4vxlan-l2bdbasemaclrn-eth-2vhost-1vm-aclreflect-ndrdisc
| | [Tags] | 64B | 2C | NDRDISC | ACL_PERMIT_REFLECT
| | ...
| | [Template] | Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | num_of_threads=2 | rxq=2 | pkt_framesize=${64} | search_type=NDR
| | ... | acl_type=permit+reflect

| tc18-64B-1t1c-ethip4vxlan-l2bdbasemaclrn-eth-2vhost-1vm-aclreflect-pdrdisc
| | [Tags] | 64B | 2C | PDRDISC | ACL_PERMIT_REFLECT
| | ...
| | [Template] | Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | num_of_threads=2 | rxq=2 | pkt_framesize=${64} | search_type=PDR
| | ... | acl_type=permit+reflect

| tc19-150B-1t1c-ethip4vxlan-l2bdbasemaclrn-eth-2vhost-1vm-aclreflect-ndrdisc
| | [Tags] | 150B | 2C | NDRDISC | ACL_PERMIT_REFLECT
| | ...
| | [Template] | Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | num_of_threads=2 | rxq=2 | pkt_framesize=${150} | search_type=NDR
| | ... | acl_type=permit+reflect

| tc20-150B-1t1c-ethip4vxlan-l2bdbasemaclrn-eth-2vhost-1vm-aclreflect-pdrdisc
| | [Tags] | 150B | 2C | PDRDISC | ACL_PERMIT_REFLECT
| | ...
| | [Template] | Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | num_of_threads=2 | rxq=2 | pkt_framesize=${150} | search_type=PDR
| | ... | acl_type=permit+reflect

| tc21-200B-1t1c-ethip4vxlan-l2bdbasemaclrn-eth-2vhost-1vm-aclreflect-ndrdisc
| | [Tags] | 200B | 2C | NDRDISC | ACL_PERMIT_REFLECT
| | ...
| | [Template] | Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | num_of_threads=2 | rxq=2 | pkt_framesize=${200} | search_type=NDR
| | ... | acl_type=permit+reflect

| tc22-200B-1t1c-ethip4vxlan-l2bdbasemaclrn-eth-2vhost-1vm-aclreflect-pdrdisc
| | [Tags] | 200B | 2C | PDRDISC | ACL_PERMIT_REFLECT
| | ...
| | [Template] | Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | num_of_threads=2 | rxq=2 | pkt_framesize=${200} | search_type=PDR
| | ... | acl_type=permit+reflect

| tc23-IMIX-1t1c-ethip4vxlan-l2bdbasemaclrn-eth-2vhost-1vm-aclreflect-ndrdisc
| | [Tags] | IMIX | 2C | NDRDISC | ACL_PERMIT_REFLECT
| | ...
| | [Template] | Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | num_of_threads=2 | rxq=2 | pkt_framesize=IMIX_v4_1 | search_type=NDR
| | ... | acl_type=permit+reflect

| tc24-IMIX-1t1c-ethip4vxlan-l2bdbasemaclrn-eth-2vhost-1vm-aclreflect-pdrdisc
| | [Tags] | IMIX | 2C | PDRDISC | ACL_PERMIT_REFLECT
| | ...
| | [Template] | Discover NDR or PDR for IPv4 forwarding with VHOST/VXLAN and ACL
| | num_of_threads=2 | rxq=2 | pkt_framesize=IMIX_v4_1 | search_type=PDR
| | ... | acl_type=permit+reflect
