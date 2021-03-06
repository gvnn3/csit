
.. raw:: latex

    \clearpage

IPv6 Routing
============

Following sections include Throughput Speedup Analysis for VPP multi-
core multi-thread configurations with no Hyper-Threading, specifically
for tested 2t2c (2threads, 2cores) and 4t4c scenarios. 1t1c throughput
results are used as a reference for reported speedup ratio. Input data
used for the graphs comes from Phy-to-Phy 78B performance tests with VPP
IPv6 Routed-Forwarding, including NDR throughput (zero packet loss) and
PDR throughput (<0.5% packet loss).

CSIT source code for the test cases used for plots can be found in
`CSIT git repository <https://git.fd.io/csit/tree/tests/vpp/perf/ip6?h=rls2009>`_.

.. toctree::

    ip6-2n-skx-xxv710
    ip6-2n-skx-x710
    ip6-3n-skx-xxv710
    ip6-3n-skx-x710
    ip6-2n-clx-xxv710
    ip6-2n-clx-x710
    ip6-2n-clx-cx556a
    ip6-2n-zn2-xxv710
    ip6-2n-zn2-x710
    ip6-2n-zn2-cx556a
    ip6-2n-zn2-turbo-xxv710
    ip6-2n-zn2-turbo-x710
    ip6-2n-zn2-turbo-cx556a
    ip6-3n-hsw-xl710
    ip6-3n-tsh-x520
    ip6-2n-dnv-x553
    ip6-3n-dnv-x553
