
.. raw:: latex

    \clearpage

.. raw:: html

    <script type="text/javascript">

        function getDocHeight(doc) {
            doc = doc || document;
            var body = doc.body, html = doc.documentElement;
            var height = Math.max( body.scrollHeight, body.offsetHeight,
                html.clientHeight, html.scrollHeight, html.offsetHeight );
            return height;
        }

        function setIframeHeight(id) {
            var ifrm = document.getElementById(id);
            var doc = ifrm.contentDocument? ifrm.contentDocument:
                ifrm.contentWindow.document;
            ifrm.style.visibility = 'hidden';
            ifrm.style.height = "10px"; // reset to minimal height ...
            // IE opt. for bing/msn needs a bit added or scrollbar appears
            ifrm.style.height = getDocHeight( doc ) + 4 + "px";
            ifrm.style.visibility = 'visible';
        }

    </script>

2n-zn2-cx556a
~~~~~~~~~~~~~

64b-vhost-base-rdma-core-testpmd
--------------------------------

.. raw:: html

    <center>
    <iframe id="01" onload="setIframeHeight(this.id)" width="700" frameborder="0" scrolling="no" src="../../_static/vpp/2n-zn2-cx556a-64b-rdma-l2-vhost-base-ndr-tsa.html"></iframe>
    <p><br></p>
    </center>

.. raw:: latex

    \begin{figure}[H]
        \centering
            \graphicspath{{../_build/_static/vpp/}}
            \includegraphics[clip, trim=0cm 0cm 5cm 0cm, width=0.70\textwidth]{2n-zn2-cx556a-64b-rdma-l2-vhost-base-ndr-tsa}
            \label{fig:2n-zn2-cx556a-64b-rdma-l2-vhost-base-ndr-tsa}
    \end{figure}

.. raw:: latex

    \clearpage

.. raw:: html

    <center>
    <iframe id="02" onload="setIframeHeight(this.id)" width="700" frameborder="0" scrolling="no" src="../../_static/vpp/2n-zn2-cx556a-64b-rdma-l2-vhost-base-pdr-tsa.html"></iframe>
    <p><br></p>
    </center>

.. raw:: latex

    \begin{figure}[H]
        \centering
            \graphicspath{{../_build/_static/vpp/}}
            \includegraphics[clip, trim=0cm 0cm 5cm 0cm, width=0.70\textwidth]{2n-zn2-cx556a-64b-rdma-l2-vhost-base-pdr-tsa}
            \label{fig:2n-zn2-cx556a-64b-rdma-l2-vhost-base-pdr-tsa}
    \end{figure}

.. raw:: latex

    \clearpage

64b-vhost-base-rdma-core-vpp
----------------------------

.. raw:: html

    <center>
    <iframe id="04" onload="setIframeHeight(this.id)" width="700" frameborder="0" scrolling="no" src="../../_static/vpp/2n-zn2-cx556a-64b-rdma-l2-vhost-vppl2xc-base-ndr-tsa.html"></iframe>
    <p><br></p>
    </center>

.. raw:: latex

    \begin{figure}[H]
        \centering
            \graphicspath{{../_build/_static/vpp/}}
            \includegraphics[clip, trim=0cm 0cm 5cm 0cm, width=0.70\textwidth]{2n-zn2-cx556a-64b-rdma-l2-vhost-vppl2xc-base-ndr-tsa}
            \label{fig:2n-zn2-cx556a-64b-rdma-l2-vhost-vppl2xc-base-ndr-tsa}
    \end{figure}

.. raw:: latex

    \clearpage

.. raw:: html

    <center>
    <iframe id="05" onload="setIframeHeight(this.id)" width="700" frameborder="0" scrolling="no" src="../../_static/vpp/2n-zn2-cx556a-64b-rdma-l2-vhost-vppl2xc-base-pdr-tsa.html"></iframe>
    <p><br></p>
    </center>

.. raw:: latex

    \begin{figure}[H]
        \centering
            \graphicspath{{../_build/_static/vpp/}}
            \includegraphics[clip, trim=0cm 0cm 5cm 0cm, width=0.70\textwidth]{2n-zn2-cx556a-64b-rdma-l2-vhost-vppl2xc-base-pdr-tsa}
            \label{fig:2n-zn2-cx556a-64b-rdma-l2-vhost-vppl2xc-base-pdr-tsa}
    \end{figure}
