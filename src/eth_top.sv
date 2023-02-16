`timescale 1ns / 1ps
/* -----------------------------------------------------------------------------
 Copyright (c) 2014-2022 All rights reserved
 -----------------------------------------------------------------------------
 Author     : lwings    https://github.com/Lvwings
 File       : eth_top.sv
 Create     : 2022-06-21 14:40:32
 Revise     : 2022-06-21 14:40:32
 Language   : Verilog 2001
 -----------------------------------------------------------------------------*/

 module eth_top #(
        // UDP parameters
        parameter LOCAL_IP                  =   32'hC0A8_006E,
        parameter LOCAL_MAC                 =   48'hABCD_1234_5678,
        parameter LOCAL_SP                  =   16'd8080,
        parameter LOCAL_DP                  =   16'd8080,    
        // AXI information          
        parameter C_AXI_ADDR_WIDTH          =   32,               // This is AXI address width for all         // SI and MI slots
        parameter C_AXI_DATA_WIDTH          =   64,               // Width of the AXI write and read data
        parameter C_AXI_ID_WIDTH            =   3,
        parameter C_AXI_BURST_TYPE          =   2'b00,            // 00 : FIXED, 01 : INCR , 10 : WRAP
        // FIFO DEPTH
        parameter TX_FIFO_BYTE_DEPTH        =   2048,
        parameter RX_FIFO_BYTE_DEPTH        =   2048           
     )
     (
            (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 axi_clk CLK" *)
            (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF rgmii_tx:m_axi:s_axi" *)
            input                               axi_clk,
            input                               axi_rstn,
        // AXI write address channel signals
            input                               m_axi_awready, // Indicates slave is ready to accept a 
            output [C_AXI_ID_WIDTH-1:0]         m_axi_awid,    // Write ID
            output [C_AXI_ADDR_WIDTH-1:0]       m_axi_awaddr,  // Write address
            output [7:0]                        m_axi_awlen,   // Write Burst Length
            output [2:0]                        m_axi_awsize,  // Write Burst size
            output [1:0]                        m_axi_awburst, // Write Burst type
            output [1:0]                        m_axi_awlock,  // Write lock type
            output [3:0]                        m_axi_awcache, // Write Cache type
            output [2:0]                        m_axi_awprot,  // Write Protection type
            output                              m_axi_awvalid, // Write address valid
          
        // AXI write data channel signals
            input                               m_axi_wready,  // Write data ready
            output [C_AXI_DATA_WIDTH-1:0]       m_axi_wdata,    // Write data
            output [C_AXI_DATA_WIDTH/8-1:0]     m_axi_wstrb,    // Write strobes
            output                              m_axi_wlast,    // Last write transaction   
            output                              m_axi_wvalid,   // Write valid
          
        // AXI write response channel signals
            input  [C_AXI_ID_WIDTH-1:0]         m_axi_bid,     // Response ID
            input  [1:0]                        m_axi_bresp,   // Write response
            input                               m_axi_bvalid,  // Write reponse valid
            output                              m_axi_bready,  // Response ready
          
        // AXI read address channel signals
            input                               m_axi_arready,     // Read address ready
            output [C_AXI_ID_WIDTH-1:0]         m_axi_arid,        // Read ID
            output [C_AXI_ADDR_WIDTH-1:0]       m_axi_araddr,      // Read address
            output [7:0]                        m_axi_arlen,       // Read Burst Length
            output [2:0]                        m_axi_arsize,      // Read Burst size
            output [1:0]                        m_axi_arburst,     // Read Burst type
            output [1:0]                        m_axi_arlock,      // Read lock type
            output [3:0]                        m_axi_arcache,     // Read Cache type
            output [2:0]                        m_axi_arprot,      // Read Protection type
            output                              m_axi_arvalid,     // Read address valid
          
        // AXI read data channel signals   
            input  [C_AXI_ID_WIDTH-1:0]         m_axi_rid,     // Response ID
            input  [1:0]                        m_axi_rresp,   // Read response
            input                               m_axi_rvalid,  // Read reponse valid
            input  [C_AXI_DATA_WIDTH-1:0]       m_axi_rdata,   // Read data
            input                               m_axi_rlast,   // Read last
            output                              m_axi_rready,   // Read Response ready 

        // AXI write address channel signals
            output                              s_axi_awready,   // Indicates slave is ready to accept a 
            input   [C_AXI_ID_WIDTH-1:0]        s_axi_awid,      // Write ID
            input   [C_AXI_ADDR_WIDTH-1:0]      s_axi_awaddr,    // Write address
            input   [7:0]                       s_axi_awlen,     // Write Burst Length
            input   [2:0]                       s_axi_awsize,    // Write Burst size
            input   [1:0]                       s_axi_awburst,   // Write Burst type
            input   [1:0]                       s_axi_awlock,    // Write lock type
            input   [3:0]                       s_axi_awcache,   // Write Cache type
            input   [2:0]                       s_axi_awprot,    // Write Protection type
            input                               s_axi_awvalid,   // Write address valid

        // AXI write data channel signals
            output                              s_axi_wready,    // Write data ready
            input   [C_AXI_DATA_WIDTH-1:0]      s_axi_wdata,     // Write data
            input   [C_AXI_DATA_WIDTH/8-1:0]    s_axi_wstrb,     // Write strobes
            input                               s_axi_wlast,     // Last write transaction   
            input                               s_axi_wvalid,    // Write valid

        // AXI write response channel signals
            output  [C_AXI_ID_WIDTH-1:0]        s_axi_bid,       // Response ID
            output  [1:0]                       s_axi_bresp,     // Write response
            output                              s_axi_bvalid,    // Write reponse valid
            input                               s_axi_bready,    // Response ready

        // AXI read address channel signals
            output                              s_axi_arready,   // Read address ready
            input   [C_AXI_ID_WIDTH-1:0]        s_axi_arid,      // Read ID
            input   [C_AXI_ADDR_WIDTH-1:0]      s_axi_araddr,    // Read address
            input   [7:0]                       s_axi_arlen,     // Read Burst Length
            input   [2:0]                       s_axi_arsize,    // Read Burst size
            input   [1:0]                       s_axi_arburst,   // Read Burst type
            input   [1:0]                       s_axi_arlock,    // Read lock type
            input   [3:0]                       s_axi_arcache,   // Read Cache type
            input   [2:0]                       s_axi_arprot,    // Read Protection type
            input                               s_axi_arvalid,   // Read address valid

        // AXI read data channel signals   
            output  [C_AXI_ID_WIDTH-1:0]        s_axi_rid,      // Response ID
            output  [1:0]                       s_axi_rresp,    // Read response
            output                              s_axi_rvalid,   // Read reponse valid
            output  [C_AXI_DATA_WIDTH-1:0]      s_axi_rdata,    // Read data
            output                              s_axi_rlast,    // Read last
            input                               s_axi_rready,    // Read Response ready  

        // AXIS RX RGMII
            (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 rgmii_rxc CLK" *)
            (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF rgmii_rx" *)
            input                               rgmii_rxc,
            (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 rgmii_rx TDATA" *)
            input   [7:0]                       rgmii_rdata,
            (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 rgmii_rx TVALID" *)
            input                               rgmii_rvalid,
            (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 rgmii_rx TLAST" *)
            input                               rgmii_rlast,
            (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 rgmii_rx TUSER" *)
            input                               rgmii_ruser,
            (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 rgmii_rx TREADY" *)
            output                              rgmii_rready,
        // AXIS TX RGMII
            (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 rgmii_tx TDATA" *)
            output  [7:0]                       rgmii_tdata,
            (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 rgmii_tx TVALID" *)
            output                              rgmii_tvalid,
            (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 rgmii_tx TLAST" *)
            output                              rgmii_tlast,
            (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 rgmii_tx TUSER" *)
            output                              rgmii_tuser,
            (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 rgmii_tx TREADY" *)
            input                               rgmii_tready
     );

    



    wire    [47:0]  target_mac;
    wire    [31:0]  target_ip;

    eth_rx #(
            .LOCAL_IP(LOCAL_IP),
            .LOCAL_MAC(LOCAL_MAC),
            .LOCAL_SP(LOCAL_SP),
            .LOCAL_DP(LOCAL_DP),
            .C_AXI_ADDR_WIDTH(C_AXI_ADDR_WIDTH),
            .C_AXI_DATA_WIDTH(C_AXI_DATA_WIDTH),
            .C_AXI_ID_WIDTH(C_AXI_ID_WIDTH),
            .C_AXI_BURST_TYPE(C_AXI_BURST_TYPE),
            .RX_FIFO_BYTE_DEPTH(RX_FIFO_BYTE_DEPTH)
        ) inst_eth_rx (
            .axi_clk       (axi_clk),
            .axi_rstn      (axi_rstn),
            .m_axi_awready (m_axi_awready),
            .m_axi_awid    (m_axi_awid),
            .m_axi_awaddr  (m_axi_awaddr),
            .m_axi_awlen   (m_axi_awlen),
            .m_axi_awsize  (m_axi_awsize),
            .m_axi_awburst (m_axi_awburst),
            .m_axi_awlock  (m_axi_awlock),
            .m_axi_awcache (m_axi_awcache),
            .m_axi_awprot  (m_axi_awprot),
            .m_axi_awvalid (m_axi_awvalid),
            .m_axi_wready  (m_axi_wready),
            .m_axi_wdata   (m_axi_wdata),
            .m_axi_wstrb   (m_axi_wstrb),
            .m_axi_wlast   (m_axi_wlast),
            .m_axi_wvalid  (m_axi_wvalid),
            .m_axi_bid     (m_axi_bid),
            .m_axi_bresp   (m_axi_bresp),
            .m_axi_bvalid  (m_axi_bvalid),
            .m_axi_bready  (m_axi_bready),
            .m_axi_arready (m_axi_arready),
            .m_axi_arid    (m_axi_arid),
            .m_axi_araddr  (m_axi_araddr),
            .m_axi_arlen   (m_axi_arlen),
            .m_axi_arsize  (m_axi_arsize),
            .m_axi_arburst (m_axi_arburst),
            .m_axi_arlock  (m_axi_arlock),
            .m_axi_arcache (m_axi_arcache),
            .m_axi_arprot  (m_axi_arprot),
            .m_axi_arvalid (m_axi_arvalid),
            .m_axi_rid     (m_axi_rid),
            .m_axi_rresp   (m_axi_rresp),
            .m_axi_rvalid  (m_axi_rvalid),
            .m_axi_rdata   (m_axi_rdata),
            .m_axi_rlast   (m_axi_rlast),
            .m_axi_rready  (m_axi_rready),
            .rgmii_rxc     (rgmii_rxc),
            .rgmii_rdata   (rgmii_rdata),
            .rgmii_rvalid  (rgmii_rvalid),
            .rgmii_rlast   (rgmii_rlast),
            .rgmii_ruser   (rgmii_ruser),
            .rgmii_rready  (rgmii_rready),
            .trig_arp_tx   (trig_arp_tx),
            .target_ip     (target_ip),
            .target_mac    (target_mac)
        );

               
    eth_tx #(
            .LOCAL_IP(LOCAL_IP),
            .LOCAL_MAC(LOCAL_MAC),
            .LOCAL_SP(LOCAL_SP),
            .LOCAL_DP(LOCAL_DP),
            .C_AXI_ADDR_WIDTH(C_AXI_ADDR_WIDTH),
            .C_AXI_DATA_WIDTH(C_AXI_DATA_WIDTH),
            .C_AXI_ID_WIDTH(C_AXI_ID_WIDTH),
            .TX_FIFO_BYTE_DEPTH(TX_FIFO_BYTE_DEPTH)
        ) inst_eth_tx (
            .axi_clk       (axi_clk),
            .axi_rstn      (axi_rstn),
            .s_axi_awready (s_axi_awready),
            .s_axi_awid    (s_axi_awid),
            .s_axi_awaddr  (s_axi_awaddr),
            .s_axi_awlen   (s_axi_awlen),
            .s_axi_awsize  (s_axi_awsize),
            .s_axi_awburst (s_axi_awburst),
            .s_axi_awlock  (s_axi_awlock),
            .s_axi_awcache (s_axi_awcache),
            .s_axi_awprot  (s_axi_awprot),
            .s_axi_awvalid (s_axi_awvalid),
            .s_axi_wready  (s_axi_wready),
            .s_axi_wdata   (s_axi_wdata),
            .s_axi_wstrb   (s_axi_wstrb),
            .s_axi_wlast   (s_axi_wlast),
            .s_axi_wvalid  (s_axi_wvalid),
            .s_axi_bid     (s_axi_bid),
            .s_axi_bresp   (s_axi_bresp),
            .s_axi_bvalid  (s_axi_bvalid),
            .s_axi_bready  (s_axi_bready),
            .s_axi_arready (s_axi_arready),
            .s_axi_arid    (s_axi_arid),
            .s_axi_araddr  (s_axi_araddr),
            .s_axi_arlen   (s_axi_arlen),
            .s_axi_arsize  (s_axi_arsize),
            .s_axi_arburst (s_axi_arburst),
            .s_axi_arlock  (s_axi_arlock),
            .s_axi_arcache (s_axi_arcache),
            .s_axi_arprot  (s_axi_arprot),
            .s_axi_arvalid (s_axi_arvalid),
            .s_axi_rid     (s_axi_rid),
            .s_axi_rresp   (s_axi_rresp),
            .s_axi_rvalid  (s_axi_rvalid),
            .s_axi_rdata   (s_axi_rdata),
            .s_axi_rlast   (s_axi_rlast),
            .s_axi_rready  (s_axi_rready),
            .rgmii_tdata   (rgmii_tdata),
            .rgmii_tvalid  (rgmii_tvalid),
            .rgmii_tlast   (rgmii_tlast),
            .rgmii_tuser   (rgmii_tuser),
            .rgmii_tready  (rgmii_tready),
            .trig_arp_tx   (trig_arp_tx),
            .target_ip     (target_ip),
            .target_mac    (target_mac)
        );


 
 endmodule : eth_top