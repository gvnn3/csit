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
| Library | resources.libraries.python.InterfaceUtil
| Library | resources.libraries.python.IPUtil
| Library | resources.libraries.python.HoststackUtil
| Library | resources.libraries.python.NsimUtil
| Variables | resources/libraries/python/Constants.py
| Resource | resources/libraries/robot/ip/ip4.robot
| Resource | resources/libraries/robot/nsim/nsim.robot
|
| Documentation | L2 keywords to set up VPP to test hoststack.

*** Variables ***
| ${quic_crypto_engine}= | nocrypto
| ${quic_fifo_size}= | 4M
| &{vpp_hoststack_attr}=
| ... | rxq=${None}
| ... | phy_cores=${1}
| ... | vpp_api_socket=${SOCKSVR_PATH}
| ... | api_seg_global_size=2G
| ... | api_seg_api_size=1G
| ... | sess_evt_q_seg_size=4G
| ... | sess_evt_q_length=4000000
| ... | sess_prealloc_sess=4000000
| ... | sess_v4_tbl_buckets=2000000
| ... | sess_v4_tbl_mem=2G
| ... | sess_v4_hopen_buckets=5000000
| ... | sess_v4_hopen_mem=3G
| ... | sess_lendpt_buckets=5000000
| ... | sess_lendpt_mem=3G
| &{vpp_echo_server_attr}=
| ... | role=server
| ... | cfg_vpp_feature=${None}
| ... | namespace=default
| ... | vpp_api_socket=${vpp_hoststack_attr}[vpp_api_socket]
| ... | json_output=json
| ... | uri_protocol=quic
| ... | uri_ip4_addr=${EMPTY}
| ... | uri_port=1234
| ... | nclients=1
| ... | quic_streams=1
| ... | time=sconnect:lastbyte
| ... | fifo_size=4M
| ... | rx_bytes=0
| ... | tx_bytes=0
| ... | rx_results_diff=${False}
| ... | tx_results_diff=${False}
| &{vpp_echo_client_attr}=
| ... | role=client
| ... | cfg_vpp_feature=${None}
| ... | namespace=default
| ... | vpp_api_socket=${vpp_hoststack_attr}[vpp_api_socket]
| ... | json_output=json
| ... | uri_protocol=quic
| ... | uri_ip4_addr=${EMPTY}
| ... | uri_port=1234
| ... | nclients=1
| ... | quic_streams=1
| ... | time=sconnect:lastbyte
| ... | fifo_size=4M
| ... | rx_bytes=0
| ... | tx_bytes=0
| ... | rx_results_diff=${False}
| ... | tx_results_diff=${False}
| &{iperf3_server_attr}=
| ... | role=server
| ... | cfg_vpp_feature=${Empty}
| ... | namespace=default
| ... | vcl_config=vcl_iperf3.conf
| ... | ld_preload=${True}
| ... | transparent_tls=${False}
| ... | json=${False}
| ... | ip_version=${4}
| &{iperf3_client_attr}=
| ... | role=client
| ... | cfg_vpp_feature=${Empty}
| ... | namespace=default
| ... | vcl_config=vcl_iperf3.conf
| ... | ld_preload=${True}
| ... | transparent_tls=${False}
| ... | json=${False}
| ... | ip_version=${4}
| ... | ip_address=${EMPTY}
| ... | parallel=${1}
| ... | bytes=1G

*** Keywords ***
| Set VPP Hoststack Attributes
| | [Documentation]
| | ... | Set the VPP HostStack attributes in the vpp_hoststack_attr dictionary.
| |
| | ... | *Arguments:*
| | ... | - ${rxq} - Type: int
| | ... | - ${phy_cores} - Number of cores for workers Type: int
| | ... | - ${vpp_api_socket} - Path to VPP api socket file Type: string
| | ... | - ${api_seg_global_size} - Global API segment size Type: string
| | ... | - ${api_seg_api_size} - API segment API fifo size Type: string
| | ... | - ${sess_evt_q_seg_size} - Session event queue segment size
| | ... | Type: string
| | ... | - ${sess_evt_q_length} - Session event queue length Type: string
| | ... | - ${sess_prealloc_sess} - Number of sessions to preallocate
| | ... | Type: string
| | ... | - ${sess_v4_tbl_buckets} - Number of IPv4 session table buckets
| | ... | Type: string
| | ... | - ${sess_v4_tbl_mem} - IPv4 session table memory size
| | ... | Type: string
| | ... | - ${sess_v4_hopen_buckets} - Number of IPv4 session
| | ... | half open table buckets Type: string
| | ... | - ${sess_v4_hopen_mem} - IPv4 session half open
| | ... | table memory size Type: string
| | ... | - ${sess_lendpt_buckets} - Number of session local endpoint
| | ... | table buckets Type: string
| | ... | - ${sess_lendpt_mem} - Session local endpoint
| | ... | table memory size Type: string
| |
| | ... | *Example:*
| |
| | ... | \| Set VPP Hoststack Attributes \| phy_cores=${phy_cores} \|
| |
| | [Arguments]
| | ... | ${rxq}=${vpp_hoststack_attr}[rxq]
| | ... | ${phy_cores}=${vpp_hoststack_attr}[phy_cores]
| | ... | ${vpp_api_socket}=${vpp_hoststack_attr}[vpp_api_socket]
| | ... | ${api_seg_global_size}=${vpp_hoststack_attr}[api_seg_global_size]
| | ... | ${api_seg_api_size}=${vpp_hoststack_attr}[api_seg_api_size]
| | ... | ${sess_evt_q_seg_size}=${vpp_hoststack_attr}[sess_evt_q_seg_size]
| | ... | ${sess_evt_q_length}=${vpp_hoststack_attr}[sess_evt_q_length]
| | ... | ${sess_prealloc_sess}=${vpp_hoststack_attr}[sess_prealloc_sess]
| | ... | ${sess_v4_tbl_buckets}=${vpp_hoststack_attr}[sess_v4_tbl_buckets]
| | ... | ${sess_v4_tbl_mem}=${vpp_hoststack_attr}[sess_v4_tbl_mem]
| | ... | ${sess_v4_hopen_buckets}=${vpp_hoststack_attr}[sess_v4_hopen_buckets]
| | ... | ${sess_v4_hopen_mem}=${vpp_hoststack_attr}[sess_v4_hopen_mem]
| | ... | ${sess_lendpt_buckets}=${vpp_hoststack_attr}[sess_lendpt_buckets]
| | ... | ${sess_lendpt_mem}=${vpp_hoststack_attr}[sess_lendpt_mem]
| |
| | Set To Dictionary | ${vpp_hoststack_attr} | rxq | ${rxq}
| | Set To Dictionary | ${vpp_hoststack_attr} | phy_cores | ${phy_cores}
| | Set To Dictionary | ${vpp_hoststack_attr}
| | ... | vpp_api_socket | ${vpp_api_socket}
| | Set To Dictionary | ${vpp_hoststack_attr}
| | ... | api_seg_global_size | ${api_seg_global_size}
| | Set To Dictionary | ${vpp_hoststack_attr}
| | ... | api_seg_api_size | ${api_seg_api_size}
| | Set To Dictionary | ${vpp_hoststack_attr}
| | ... | sess_evt_q_seg_size | ${sess_evt_q_seg_size}
| | Set To Dictionary | ${vpp_hoststack_attr}
| | ... | sess_evt_q_length | ${sess_evt_q_length}
| | Set To Dictionary | ${vpp_hoststack_attr}
| | ... | sess_prealloc_sess | ${sess_prealloc_sess}
| | Set To Dictionary | ${vpp_hoststack_attr}
| | ... | sess_v4_tbl_buckets | ${sess_v4_tbl_buckets}
| | Set To Dictionary | ${vpp_hoststack_attr}
| | ... | sess_v4_tbl_mem | ${sess_v4_tbl_mem}
| | Set To Dictionary | ${vpp_hoststack_attr}
| | ... | sess_v4_hopen_buckets | ${sess_v4_hopen_buckets}
| | Set To Dictionary | ${vpp_hoststack_attr}
| | ... | sess_v4_hopen_mem | ${sess_v4_hopen_mem}
| | Set To Dictionary | ${vpp_hoststack_attr}
| | ... | sess_lendpt_buckets | ${sess_lendpt_buckets}
| | Set To Dictionary | ${vpp_hoststack_attr}
| | ... | sess_lendpt_mem | ${sess_lendpt_mem}

| Set VPP Echo Server Attributes
| | [Documentation]
| | ... | Set the HostStack vpp_echo test program attributes
| | ... | in the vpp_echo_server_attr dictionary.
| |
| | ... | *Arguments:*
| | ... | - ${cfg_vpp_feature} - VPP Feature requiring config Type: string
| | ... | - ${namespace} - Namespace Type: string
| | ... | - ${nclients} - Number of clients Type: string
| | ... | - ${quic_streams} - Number of quic streams Type: string
| | ... | - ${fifo_size} - Session Fifo Size Type: integer
| | ... | - ${time} - Timing events (start:end) Type: string
| | ... | - ${rx_bytes} - Number of Bytes to receive Type: string
| | ... | - ${tx_bytes} - Number of Bytes to send Type: string
| | ... | - ${rx_results_diff} - Rx Results are different to pass Type: boolean
| | ... | - ${tx_results_diff} - Tx Results are different to pass Type: boolean
| |
| | ... | *Example:*
| |
| | ... | \| Set VPP Echo Server Attributes \| nclients=${nclients} \|
| | ... | \| tx_bytes=${tx_bytes} \|
| |
| | [Arguments]
| | ... | ${cfg_vpp_feature}=${vpp_echo_server_attr}[cfg_vpp_feature]
| | ... | ${namespace}=${vpp_echo_server_attr}[namespace]
| | ... | ${nclients}=${vpp_echo_server_attr}[nclients]
| | ... | ${quic_streams}=${vpp_echo_server_attr}[quic_streams]
| | ... | ${time}=${vpp_echo_server_attr}[time]
| | ... | ${fifo_size}=${vpp_echo_server_attr}[fifo_size]
| | ... | ${rx_bytes}=${vpp_echo_server_attr}[rx_bytes]
| | ... | ${tx_bytes}=${vpp_echo_server_attr}[tx_bytes]
| | ... | ${rx_results_diff}=${vpp_echo_server_attr}[rx_results_diff]
| | ... | ${tx_results_diff}=${vpp_echo_server_attr}[tx_results_diff]
| |
| | Set To Dictionary | ${vpp_echo_server_attr} | cfg_vpp_feature
| | ... | ${cfg_vpp_feature}
| | Set To Dictionary | ${vpp_echo_server_attr} | namespace | ${namespace}
| | Set To Dictionary | ${vpp_echo_server_attr} | nclients | ${nclients}
| | Set To Dictionary | ${vpp_echo_server_attr} | quic_streams | ${quic_streams}
| | Set To Dictionary | ${vpp_echo_server_attr} | time | ${time}
| | Set To Dictionary | ${vpp_echo_server_attr} | fifo_size | ${fifo_size}
| | Set To Dictionary | ${vpp_echo_server_attr} | rx_bytes | ${rx_bytes}
| | Set To Dictionary | ${vpp_echo_server_attr} | tx_bytes | ${tx_bytes}
| | Set To Dictionary
| | ... | ${vpp_echo_server_attr} | rx_results_diff | ${rx_results_diff}
| | Set To Dictionary
| | ... | ${vpp_echo_server_attr} | tx_results_diff | ${tx_results_diff}

| Set VPP Echo Client Attributes
| | [Documentation]
| | ... | Set the HostStack vpp_echo test program attributes
| | ... | in the vpp_echo_client_attr dictionary.
| |
| | ... | *Arguments:*
| | ... | - ${cfg_vpp_feature} - VPP Feature requiring config Type: string
| | ... | - ${namespace} - Namespace Type: string
| | ... | - ${nclients} - Number of clients Type: string
| | ... | - ${fifo_size} - Session Fifo Size Type: integer
| | ... | - ${time} - Timing events (start:end) Type: string
| | ... | - ${rx_bytes} - Number of Bytes to receive Type: string
| | ... | - ${tx_bytes} - Number of Bytes to send Type: string
| | ... | - ${rx_results_diff} - Rx Results are different to pass Type: boolean
| | ... | - ${tx_results_diff} - Tx Results are different to pass Type: boolean
| |
| | ... | *Example:*
| |
| | ... | \| Set VPP Echo Client Attributes \| nclients=${nclients} \|
| | ... | \| tx_bytes=${tx_bytes} \|
| |
| | [Arguments]
| | ... | ${cfg_vpp_feature}=${vpp_echo_client_attr}[cfg_vpp_feature]
| | ... | ${namespace}=${vpp_echo_client_attr}[namespace]
| | ... | ${nclients}=${vpp_echo_client_attr}[nclients]
| | ... | ${quic_streams}=${vpp_echo_server_attr}[quic_streams]
| | ... | ${time}=${vpp_echo_client_attr}[time]
| | ... | ${fifo_size}=${vpp_echo_client_attr}[fifo_size]
| | ... | ${rx_bytes}=${vpp_echo_client_attr}[rx_bytes]
| | ... | ${tx_bytes}=${vpp_echo_client_attr}[tx_bytes]
| | ... | ${rx_results_diff}=${vpp_echo_client_attr}[rx_results_diff]
| | ... | ${tx_results_diff}=${vpp_echo_client_attr}[tx_results_diff]
| |
| | Set To Dictionary | ${vpp_echo_client_attr} | cfg_vpp_feature
| | ... | ${cfg_vpp_feature}
| | Set To Dictionary | ${vpp_echo_client_attr} | namespace | ${namespace}
| | Set To Dictionary | ${vpp_echo_client_attr} | nclients | ${nclients}
| | Set To Dictionary | ${vpp_echo_client_attr} | quic_streams | ${quic_streams}
| | Set To Dictionary | ${vpp_echo_client_attr} | time | ${time}
| | Set To Dictionary | ${vpp_echo_client_attr} | fifo_size | ${fifo_size}
| | Set To Dictionary | ${vpp_echo_client_attr} | rx_bytes | ${rx_bytes}
| | Set To Dictionary | ${vpp_echo_client_attr} | tx_bytes | ${tx_bytes}
| | Set To Dictionary
| | ... | ${vpp_echo_client_attr} | rx_results_diff | ${rx_results_diff}
| | Set To Dictionary
| | ... | ${vpp_echo_client_attr} | tx_results_diff | ${tx_results_diff}

| Set Iperf3 Server Attributes
| | [Documentation]
| | ... | Set the HostStack iperf3 test program attributes
| | ... | in the iperf3_server_attr dictionary.
| |
| | ... | *Arguments:*
| | ... | - ${vcl_config} - VCL configuration file name Type: string
| | ... | - ${ld_preload} - Use the VCL LD_PRELOAD library Type: bool
| | ... | - ${transparent_tls} - Use VCL Transparent-TLS mode Type: bool
| | ... | - ${ip_version} - IP version (4 or 6) Type: int
| |
| | ... | *Example:*
| |
| | ... | \| Set Iperf3 Server Attributes \| vcl_config=${vcl_config} \|
| | ... | \| ip_version=${ip_version} \|
| |
| | [Arguments]
| | ... | ${vcl_config}=${iperf3_server_attr}[vcl_config]
| | ... | ${ld_preload}=${iperf3_server_attr}[ld_preload]
| | ... | ${transparent_tls}=${iperf3_server_attr}[transparent_tls]
| | ... | ${ip_version}=${iperf3_server_attr}[ip_version]
| |
| | Set To Dictionary | ${iperf3_server_attr} | vcl_config | ${vcl_config}
| | Set To Dictionary | ${iperf3_server_attr} | ld_preload | ${ld_preload}
| | Set To Dictionary | ${iperf3_server_attr} | transparent_tls
| | ... | ${transparent_tls}
| | Set To Dictionary | ${iperf3_server_attr} | ip_version | ${ip_version}

| Set Iperf3 Client Attributes
| | [Documentation]
| | ... | Set the HostStack iperf3 test program attributes
| | ... | in the iperf3_client_attr dictionary.
| |
| | ... | *Arguments:*
| | ... | - ${vcl_config} - VCL configuration file name Type: string
| | ... | - ${ld_preload} - Use the VCL LD_PRELOAD library Type: bool
| | ... | - ${transparent_tls} - Use VCL Transparent-TLS mode Type: bool
| | ... | - ${ip_version} - IP version (4 or 6) Type: int
| | ... | - ${parallel} - Number of parallel streams Type: int
| | ... | - ${bytes} - Number of bytes to send Type: string
| |
| | ... | *Example:*
| |
| | ... | \| Set Iperf3 Client Attributes \| vcl_config=${vcl_config} \|
| | ... | \| ip_version=${ip_version} \| parallel=${streams} \|
| |
| | [Arguments]
| | ... | ${vcl_config}=${iperf3_client_attr}[vcl_config]
| | ... | ${ld_preload}=${iperf3_client_attr}[ld_preload]
| | ... | ${transparent_tls}=${iperf3_client_attr}[transparent_tls]
| | ... | ${ip_version}=${iperf3_client_attr}[ip_version]
| | ... | ${parallel}=${iperf3_client_attr}[parallel]
| | ... | ${bytes}=${iperf3_client_attr}[bytes]
| |
| | Set To Dictionary | ${iperf3_client_attr} | vcl_config | ${vcl_config}
| | Set To Dictionary | ${iperf3_client_attr} | ld_preload | ${ld_preload}
| | Set To Dictionary | ${iperf3_client_attr} | transparent_tls
| | ... | ${transparent_tls}
| | Set To Dictionary | ${iperf3_client_attr} | ip_version | ${ip_version}
| | Set To Dictionary | ${iperf3_client_attr} | parallel | ${parallel}
| | Set To Dictionary | ${iperf3_client_attr} | bytes | ${bytes}

| Run hoststack test program on DUT
| | [Documentation]
| | ... | Configure IP address on the port, set it up and start the specified
| | ... | HostStack test program on the specified DUT.
| |
| | ... | *Arguments:*
| | ... | - ${node} - VPP DUT node Type: Node
| | ... | - ${intf} - VPP DUT node interface key Type: string
| | ... | - ${ip4_addr} - VPP DUT node interface ip4 address Type: string
| | ... | - ${ip4_mask} - VPP DUT node interface ip4 network mask Type: string
| | ... | - ${namespace} - Network namespace to run test program in Type: string
| | ... | - ${cfg_vpp_feature} - VPP hoststack feature requiring
| | ... | additional VPP configuration Type: string
| | ... | - ${test_program} - Host Stack test program Type: dict
| |
| | ... | *Example:*
| |
| | ... | \| Run hoststack test program on DUT \| ${dut1} \| ${dut1_if1} \|
| | ... | \| ${dut1_if1_ip4_addr} \| ${dut1_if1_ip4_mask} \| default \|
| | ... | \| quic \| ${vpp_echo_server} \|
| |
| | [Arguments] | ${node} | ${intf} | ${ip4_addr} | ${ip4_mask}
| | | ... | ${namespace} | ${cfg_vpp_feature} | ${test_program}
| |
| | Run Keyword If | ${vpp_nsim_attr}[output_feature_enable]
| | ... | Configure VPP NSIM | ${node} | ${vpp_nsim_attr} | ${intf}
| | Run Keyword If | '${cfg_vpp_feature}' != ''
| | ... | Additional VPP Config for Feature ${cfg_vpp_feature} | ${node}
| | VPP Get Interface Data | ${node}
| | Set Interface State | ${node} | ${intf} | up
| | VPP Interface Set IP Address | ${node} | ${intf} | ${ip4_addr}
| | ... | ${ip4_mask}
| | Vpp Node Interfaces Ready Wait | ${node}
| | ${hoststack_test_program_pid}= | Start Hoststack Test Program
| | ... | ${node} | ${namespace} | ${test_program}
| | Return From Keyword | ${hoststack_test_program_pid}

| Additional VPP Config For Feature quic
| | [Documentation]
| | ... | Configure VPP quic attributes on the specified DUT.
| |
| | ... | *Arguments:*
| | ... | - ${node} - VPP DUT node Type: Node
| |
| | [Arguments] | ${node}
| |
| | Set hoststack quic fifo size | ${node} | ${quic_fifo_size}
| | Set hoststack quic crypto engine | ${node} | ${quic_crypto_engine}

| Configure VPP hoststack attributes on all DUTs
| | [Documentation]
| | ... | Configure VPP HostStack attributes on all DUTs.
| |
| | Set Max Rate And Jumbo
| | Add worker threads to all DUTs
| | ... | ${vpp_hoststack_attr}[phy_cores] | ${vpp_hoststack_attr}[rxq]
| | Pre-initialize layer driver | ${nic_driver}
| | FOR | ${dut} | IN | @{duts}
| | | Import Library | resources.libraries.python.VppConfigGenerator
| | | ... | WITH NAME | ${dut}
| | | Run keyword | ${dut}.Add socksvr | ${vpp_hoststack_attr}[vpp_api_socket]
| | | Run keyword | ${dut}.Add api segment global size
| | | ... | ${vpp_hoststack_attr}[api_seg_global_size]
| | | Run keyword | ${dut}.Add api segment api size
| | | ... | ${vpp_hoststack_attr}[api_seg_api_size]
| | | Run keyword | ${dut}.Add api segment gid | testuser
| | | Run keyword | ${dut}.Add session enable
| | | Run keyword | ${dut}.Add session event queues memfd segment
| | | Run keyword | ${dut}.Add session event queues segment size
| | | ... | ${vpp_hoststack_attr}[sess_evt_q_seg_size]
| | | Run keyword | ${dut}.Add session event queue length
| | | ... | ${vpp_hoststack_attr}[sess_evt_q_length]
| | | Run keyword | ${dut}.Add session preallocated sessions
| | | ... | ${vpp_hoststack_attr}[sess_prealloc_sess]
| | | Run keyword | ${dut}.Add session v4 session table buckets
| | | ... | ${vpp_hoststack_attr}[sess_v4_tbl_buckets]
| | | Run keyword | ${dut}.Add session v4 session table memory
| | | ... | ${vpp_hoststack_attr}[sess_v4_tbl_mem]
| | | Run keyword | ${dut}.Add session v4 halfopen table buckets
| | | ... | ${vpp_hoststack_attr}[sess_v4_hopen_buckets]
| | | Run keyword | ${dut}.Add session v4 halfopen table memory
| | | ... | ${vpp_hoststack_attr}[sess_v4_hopen_mem]
| | | Run keyword | ${dut}.Add session local endpoints table buckets
| | | ... | ${vpp_hoststack_attr}[sess_lendpt_buckets]
| | | Run keyword | ${dut}.Add session local endpoints table memory
| | | ... | ${vpp_hoststack_attr}[sess_lendpt_mem]
| | END
| | Apply startup configuration on all VPP DUTs

| Get Test Results From Hoststack VPP Echo Test
| | [Documentation]
| | ... | Configure IP address on the port, set it up and start the specified
| | ... | HostStack test programs on the DUTs. Gather test program
| | ... | output and append test results in message.
| | ... | Return boolean indicating when no results were available from
| | ... | both the server and client test programs.
| |
| | Set To Dictionary | ${vpp_echo_server_attr} | uri_ip4_addr
| | ... | ${dut2_if1_ip4_addr}
| | Set To Dictionary | ${vpp_echo_client_attr} | uri_ip4_addr
| | ... | ${dut2_if1_ip4_addr}
| | Configure VPP Hoststack Attributes on all DUTs
| | ${vpp_echo_server}= | Get VPP Echo Command | ${vpp_echo_server_attr}
| | ${server_pid}= | Run hoststack test program on DUT
| | ... | ${dut2} | ${dut2_if1} | ${dut2_if1_ip4_addr} | ${dut2_if1_ip4_prefix}
| | ... | ${vpp_echo_server_attr}[namespace]
| | ... | ${vpp_echo_server_attr}[cfg_vpp_feature] | ${vpp_echo_server}
| | ${vpp_echo_client}= | Get VPP Echo Command | ${vpp_echo_client_attr}
| | ${client_pid}= | Run hoststack test program on DUT
| | ... | ${dut1} | ${dut1_if1} | ${dut1_if1_ip4_addr} | ${dut1_if1_ip4_prefix}
| | ... | ${vpp_echo_client_attr}[namespace]
| | ... | ${vpp_echo_client_attr}[cfg_vpp_feature] | ${vpp_echo_client}
| | When Hoststack Test Program Finished | ${dut1} | ${client_pid}
| | ${client_no_results} | ${client_output}=
| | ... | Analyze hoststack test program output | ${dut1} | Client
| | ... | ${vpp_nsim_attr} | ${vpp_echo_client}
| | Then Set test message | ${client_output}
| | And Hoststack Test Program Finished | ${dut2} | ${server_pid}
| | ${server_no_results} | ${server_output}=
| | ... | Analyze hoststack test program output | ${dut2} | Server
| | ... | ${vpp_nsim_attr} | ${vpp_echo_server}
| | Set test message | ${server_output} | append=True
| | Run Keyword And Return | No Hoststack Test Program Results
| | ... | ${server_no_results} | ${client_no_results}

| Get Test Results From Hoststack Iperf3 Test
| | [Documentation]
| | ... | Configure IP address on the port, set it up and start the specified
| | ... | HostStack test programs on the DUTs. Gather test program
| | ... | output and append test results in message.
| | ... | Return boolean indicating when no results were available from
| | ... | both the server and client test programs.
| |
| | Set To Dictionary | ${iperf3_client_attr} | ip_address
| | ... | ${dut2_if1_ip4_addr}
| | Configure VPP Hoststack Attributes on all DUTs
| | ${iperf3_server}= | Get Iperf3 Command | ${iperf3_server_attr}
| | ${server_pid}= | Run hoststack test program on DUT
| | ... | ${dut2} | ${dut2_if1} | ${dut2_if1_ip4_addr} | ${dut2_if1_ip4_prefix}
| | ... | ${iperf3_server_attr}[namespace]
| | ... | ${iperf3_server_attr}[cfg_vpp_feature] | ${iperf3_server}
| | ${iperf3_client}= | Get Iperf3 Command | ${iperf3_client_attr}
| | ${client_pid}= | Run hoststack test program on DUT
| | ... | ${dut1} | ${dut1_if1} | ${dut1_if1_ip4_addr} | ${dut1_if1_ip4_prefix}
| | ... | ${iperf3_client_attr}[namespace]
| | ... | ${iperf3_client_attr}[cfg_vpp_feature] | ${iperf3_client}
| | When Hoststack Test Program Finished | ${dut1} | ${client_pid}
| | ${client_no_results} | ${client_output}=
| | ... | Analyze hoststack test program output | ${dut1} | Client
| | ... | ${vpp_nsim_attr} | ${iperf3_client}
| | Then Set test message | ${client_output}
| | Return From Keyword | ${client_no_results}