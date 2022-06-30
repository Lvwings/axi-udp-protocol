`timescale 1ns / 1ps
/* -----------------------------------------------------------------------------
 Copyright (c) 2014-2021 All rights reserved
 -----------------------------------------------------------------------------
 Author     : lwings    https://github.com/Lvwings
 File       : eth_rx.sv
 Create     : 2022-06-28 11:04:53
 Revise     : 2022-06-28 11:04:53
 Language   : Verilog 2001
 -----------------------------------------------------------------------------*/

 module eth_rx #(
        // UDP parameters
        parameter LOCAL_IP                  =   32'hC0A8_006E,
        parameter LOCAL_MAC                 =   48'hABCD_1234_5678,
        parameter LOCAL_SP                  =   16'd8080,
        parameter LOCAL_DP                  =   16'd8080,    
        // AXI information          
        parameter C_AXI_ADDR_WIDTH          =   32,               // This is AXI address width for all         // SI and MI slots
        parameter C_AXI_DATA_WIDTH          =   64,               // Width of the AXI write and read data
        parameter C_BEGIN_ADDRESS           =   0,                // Start address of the address map
        parameter C_END_ADDRESS             =   32'hFFFF_FFFF     // End address of the address map    
     )(

            input                               axi_clk,
            input                               axi_rstn,
     // AXI write address channel signals
            input                               m_axi_awready, // Indicates slave is ready to accept a 
            output [C_AXI_ADDR_WIDTH-1:0]       m_axi_awaddr,  // Write address
            output                              m_axi_awvalid, // Write address valid
       
     // AXI write data channel signals
            input                               m_axi_wready,   // Write data ready
            output [C_AXI_DATA_WIDTH-1:0]       m_axi_wdata,    // Write data
            output [C_AXI_DATA_WIDTH/8-1:0]     m_axi_wstrb,    // Write strobes
            output                              m_axi_wlast,    // Last write transaction   
            output                              m_axi_wvalid,   // Write valid
       
     // AXI write response channel signals
            input  [1:0]                        m_axi_bresp,   // Write response
            input                               m_axi_bvalid,  // Write reponse valid
            output                              m_axi_bready,  // Response ready
       
     // AXI read address channel signals
            input                               m_axi_arready,     // Read address ready
            output [C_AXI_ADDR_WIDTH-1:0]       m_axi_araddr,      // Read address
            output                              m_axi_arvalid,     // Read address valid
       
     // AXI read data channel signals   
            input  [1:0]                        m_axi_rresp,   // Read response
            input                               m_axi_rvalid,  // Read reponse valid
            input  [C_AXI_DATA_WIDTH-1:0]       m_axi_rdata,   // Read data
            input                               m_axi_rlast,   // Read last
            output                              m_axi_rready,   // Read Response ready

        // AXIS RX RGMII
            input                               rgmii_rxc,
            input   [7:0]                       rgmii_rdata,
            input                               rgmii_rvalid,
            input                               rgmii_rlast,
            input                               rgmii_ruser,
            output                              rgmii_rready,
        // arp 
            output                              trig_arp_tx,
            output   [31:0]                     target_ip,
            output   [47:0]                     target_mac             
         );
         
    //*****************************************************************************
    // AXI support signals
    //*****************************************************************************    
        // function called clogb2 that returns an integer which has the 
        // value of the ceiling of the log base 2.                      
        function integer clogb2 (input integer bit_depth);              
            begin                                                           
                for(clogb2=0; bit_depth>0; clogb2=clogb2+1)                   
                  bit_depth = bit_depth >> 1;                                 
            end                                                           
        endfunction 
    
        //    AXI_SIZE : the data bytes of each burst
        localparam    [2:0]    AXI_SIZE        =    clogb2(C_AXI_DATA_WIDTH/8-1);
    
        //    AXI_ADDR_INC : axi address increment associate with data width
        localparam    [7:0]    AXI_ADDR_INC    =    C_AXI_DATA_WIDTH/8;

    /*------------------------------------------------------------------------------
    --  reset localization
    ------------------------------------------------------------------------------*/
        logic   local_rstn   =   '0;

        always_ff @(posedge axi_clk) begin
            local_rstn <= axi_rstn;
        end

        logic   rgmii_cdc_rstn;

        xpm_cdc_sync_rst #(
           .DEST_SYNC_FF(4),   // DECIMAL; range: 2-10
           .INIT(1),           // DECIMAL; 0=initialize synchronization registers to 0, 1=initialize synchronization
                               // registers to 1
           .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
           .SIM_ASSERT_CHK(0)  // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
        )
        xpm_cdc_sync_rst_inst (
           .dest_rst(rgmii_cdc_rstn), // 1-bit output: src_rst synchronized to the destination clock domain. This output
                                // is registered.
           .dest_clk(rgmii_rxc), // 1-bit input: Destination clock.
           .src_rst(axi_rstn)    // 1-bit input: Source reset signal.
        );  

    /*------------------------------------------------------------------------------
    --  rgmii rx
    ------------------------------------------------------------------------------*/
        //  rx fifo
        localparam  FIFO_DEPTH  = 2048;  //  udp length < 1500-byte  
        logic   [8-1 : 0]   fifo_tdata;
        logic               fifo_tvalid;
        logic               fifo_tready =   '0;
        logic               fifo_tlast;
        logic               fifo_tuser;

        xpm_fifo_axis #(
            .CLOCKING_MODE  ("independent_clock"),  //  "common_clock" or "independent_clock"  Default value = "common_clock". 
            .RELATED_CLOCKS (0),                    //  Specifies if the s_aclk and m_aclk are related having the same source but different clock ratios. Default value = 0 
            .FIFO_DEPTH     (FIFO_DEPTH),           //  Range: 16 - 4194304. Default value = 2048
            .TDATA_WIDTH    (8),                    //  Range: 8 - 2048. Default value = 32        
            .PACKET_FIFO    ("false")               //  "false" or "true". Default value = "false"      
       )
       udp_tx_fifo (
        //  axis slave
            .s_aclk         (rgmii_rxc),                        
            .s_aresetn      (rgmii_cdc_rstn),                 
            .s_axis_tdata   (rgmii_rdata), 
            .s_axis_tvalid  (rgmii_rvalid), 
            .s_axis_tready  (rgmii_rready), 
            .s_axis_tlast   (rgmii_rlast),
            .s_axis_tuser   (rgmii_ruser), 

        //  axis master    
            .m_aclk         (axi_clk),                                                                      
            .m_axis_tdata   (fifo_tdata),           
            .m_axis_tvalid  (fifo_tvalid),
            .m_axis_tready  (fifo_tready), 
            .m_axis_tlast   (fifo_tlast), 
            .m_axis_tuser   (fifo_tuser)
       );

    /*------------------------------------------------------------------------------
    --  eth receive state parameter
    ------------------------------------------------------------------------------*/    
        typedef enum {IDLE,ETH_HEADER,IP_HEADER,UDP_HEADER,ARP,AXI_ADDR,AXI_DATA,AXI_RESPONSE} eth_state;
(* keep="true" *)        eth_state rx_state,rx_next;

        always_ff @(posedge axi_clk) begin 
            if(!local_rstn) begin
                rx_state <= IDLE;
            end else begin
                rx_state <= rx_next;
            end
        end              

    /*------------------------------------------------------------------------------
    --  state jump
    ------------------------------------------------------------------------------*/
(* keep="true" *)        logic           flag_rx_start   =   '0;
(* keep="true" *)        logic           flag_rx_err     =   '0;     //  not target frame
(* keep="true" *)        logic           flag_arp        =   '0;
(* keep="true" *)        logic           flag_rx_over    =   '0;

        always_ff @(posedge axi_clk) begin
            flag_rx_start   <= fifo_tvalid && !flag_rx_err;
        end 

        always_comb begin
            case (rx_state)
                IDLE        :   rx_next     =   flag_rx_start   ?   ETH_HEADER  :   IDLE;

                ETH_HEADER  :   if (flag_rx_err)        rx_next =   IDLE;
                                else if (flag_arp)      rx_next =   ARP;
                                else if (flag_rx_over)  rx_next =   IP_HEADER;
                                else                    rx_next =   ETH_HEADER;

                IP_HEADER   :   if (flag_rx_err)        rx_next =   IDLE;
                                else if (flag_rx_over)  rx_next =   UDP_HEADER;
                                else                    rx_next =   IP_HEADER;    

                UDP_HEADER  :   if (flag_rx_err)        rx_next =   IDLE;
                                else if (flag_rx_over)  rx_next =   AXI_ADDR;
                                else                    rx_next =   UDP_HEADER;

                ARP         :   if (flag_rx_err)        rx_next =   IDLE;
                                else if (flag_rx_over)  rx_next =   IDLE;
                                else                    rx_next =   ARP;                                

                AXI_ADDR    :   rx_next =   (m_axi_awready && m_axi_awvalid)                ? AXI_DATA : AXI_ADDR;

                AXI_DATA    :   rx_next =   (m_axi_wvalid && m_axi_wready && m_axi_wlast)   ? AXI_RESPONSE : AXI_DATA;

                AXI_RESPONSE:   rx_next =   (m_axi_bvalid && m_axi_bready)                  ? IDLE : AXI_RESPONSE;
                default :       rx_next =   IDLE;
            endcase                
        end       

    /*------------------------------------------------------------------------------
    --  eth frame paramter
    ------------------------------------------------------------------------------*/
       localparam  GLOBAL_MAC      =   48'hFFFF_FFFF_FFFF;
       localparam  IP_TYPE         =   16'h0800;
       localparam  ARP_TYPE        =   16'h0806;
       localparam  ARP_REQUEST     =   16'h0001;
       localparam  ICMP_REQUEST    =   8'h08;
       //  IP HEAD
       localparam  IP_VISION_TOS   =   16'h4500;   //  vision 4, length 5, tos 00
       localparam  IP_FLAG_OFFSET  =   16'h4000;   //  dont fragment flag = 1
       localparam  IP_TTL_PROTO    =   16'h8011;   //  TTL 80, proto 11 (udp)

       localparam  ETH_HEAD_LENGTH =   8'd14;
       localparam  IP_HEAD_LENGTH  =   8'd20;    
       localparam  UDP_HEAD_LENGTH =   8'd8;
       localparam  UDP_MIN_LENGTH  =   8'd26;      //  UDP_HEAD_LENGTH + MIN_DATA_LENGTH 
       localparam  ARP_LENGTH      =   8'd28;
       localparam  ICMP_LENGTH     =   8'd40;

    /*------------------------------------------------------------------------------
    --  reveice data
    ------------------------------------------------------------------------------*/
(* keep="true" *)        logic   [15:0]  rx_cnt  =   '0;
        //  eth header
        logic   [15:0]  eth_type     =   '0;     //  收到的帧类型
        logic   [47:0]  eth_da_mac   =   '0,
                        eth_sa_mac   =   '0;
        //  ip header
        logic   [15:0]  ip_idf       =   '0;     //    16位标识
        logic   [15:0]  ip_vis_tos   =   '0;
        logic   [15:0]  ip_ttl_prtc  =   '0;
        
        logic   [31:0]  da_ip        =   '0,
                        sa_ip        =   '0;
        //  udp header
        logic   [15:0]  udp_dp          =   '0,  
                        udp_sp          =   '0,  
                        udp_len         =   '0;
        logic   [15:0]  udp_data_len    =   '0;

        logic   [31:0]  axi_awaddr      =   '0;
        //  arp
(* keep="true" *)        logic   [47:0]  arp_sa_mac      =   '0;      
(* keep="true" *)        logic   [31:0]  arp_sa_ip       =   '0,
                        arp_da_ip       =   '0;        
        logic   [15:0]  arp_opcode      =   '0;
(* keep="true" *)        logic           o_trig_arp_tx   =   '0;
(* keep="true" *)        logic   [7:0]   watch_dog   =   '0;

        assign  target_ip   =   arp_sa_ip;
        assign  target_mac  =   arp_sa_mac;
        assign  trig_arp_tx =   o_trig_arp_tx;
    //*****************************************************************************
    // AXI Internal register and wire declarations
    //*****************************************************************************   
    // AXI m_write address channel signals    
        logic   [C_AXI_ADDR_WIDTH-1:0]      m_awaddr    =    '0;
        logic                               m_awvalid   =    '0;
    
    // AXI m_write data channel signals    
        logic   [C_AXI_DATA_WIDTH-1:0]      m_wdata     =    '0;
        logic                               m_wlast     =    '0;
        logic                               m_wvalid    =    '0;
    
    // AXI m_write response channel signals        
        logic                               m_bready    =    '0;
    
    // AXI read address channel signals    
        logic   [C_AXI_ADDR_WIDTH-1:0]      m_araddr    =    '0;
        logic                               m_arvalid   =    '0;
    
    // AXI read data channel signals        
        logic                               m_rready    =    '0;

        assign    m_axi_awaddr          =   m_awaddr;
        assign    m_axi_awvalid         =   m_awvalid;        
        assign    m_axi_wdata           =   m_wdata;
        assign    m_axi_wstrb           =   {(C_AXI_DATA_WIDTH/8){1'b1}};
        assign    m_axi_wlast           =   m_wlast;
        assign    m_axi_wvalid          =   m_wvalid;    
        assign    m_axi_bready          =   m_bready;

        logic   [AXI_SIZE-1 : 0]            byte_cnt    =   {AXI_SIZE{1'b1}} -1;
    /*------------------------------------------------------------------------------
    --  state
    ------------------------------------------------------------------------------*/
        always_ff @(posedge axi_clk) begin
            case (rx_next)
                ETH_HEADER  : begin
                    if (rx_cnt == ETH_HEAD_LENGTH) begin
                        if ((eth_type ==  IP_TYPE) && (eth_da_mac == LOCAL_MAC)) 
                            flag_rx_over    <=  1;
                        else if (eth_type == ARP_TYPE && (eth_da_mac == GLOBAL_MAC || eth_da_mac == LOCAL_MAC))
                            flag_arp        <=  1;
                        else begin
                            flag_rx_over    <=  0;
                            flag_arp        <=  0;
                            flag_rx_err     <=  1;
                        end
                        rx_cnt      <=  0;  
                        watch_dog   <=  '0;                      
                    end
                    else begin
                        fifo_tready <=  1;
                        watch_dog   <=  watch_dog + 1;
                        //  sometimes fifo_tvalid will be reasserted after frame over
                        rx_cnt      <=  rx_cnt + (fifo_tvalid && fifo_tready);
                        flag_rx_err <=  fifo_tuser || (watch_dog > ETH_HEAD_LENGTH+1);

                        case (rx_cnt) 
                             // DA MAC
                             16'd00: begin eth_da_mac[47:40] <= fifo_tdata; end
                             16'd01: begin eth_da_mac[39:32] <= fifo_tdata; end
                             16'd02: begin eth_da_mac[31:24] <= fifo_tdata; end
                             16'd03: begin eth_da_mac[23:16] <= fifo_tdata; end
                             16'd04: begin eth_da_mac[15:08] <= fifo_tdata; end
                             16'd05: begin eth_da_mac[07:00] <= fifo_tdata; end
                            // SA MAC                
                             16'd06: begin eth_sa_mac[47:40] <= fifo_tdata; end
                             16'd07: begin eth_sa_mac[39:32] <= fifo_tdata; end
                             16'd08: begin eth_sa_mac[31:24] <= fifo_tdata; end
                             16'd09: begin eth_sa_mac[23:16] <= fifo_tdata; end
                             16'd10: begin eth_sa_mac[15:08] <= fifo_tdata; end
                             16'd11: begin eth_sa_mac[07:00] <= fifo_tdata; end
                             // TYPE
                             16'd12: begin eth_type[15:08] <= fifo_tdata; end
                             16'd13: begin eth_type[07:00] <= fifo_tdata; fifo_tready <= 0;end
                             default : begin end
                        endcase                        
                    end
                end

                IP_HEADER   :  begin
                    if (rx_cnt == IP_HEAD_LENGTH) begin
                        if (ip_vis_tos == IP_VISION_TOS && ip_ttl_prtc == IP_TTL_PROTO && da_ip ==  LOCAL_IP) begin
                            flag_rx_over    <=  1;
                        end
                        else begin
                            flag_rx_over    <=  0;
                            flag_rx_err     <=  1;                            
                        end
                        rx_cnt  <=  0;
                    end
                    else begin
                        flag_rx_over<=  0;
                        fifo_tready <=  1;
                        rx_cnt      <=  rx_cnt + (fifo_tvalid && fifo_tready);
                        flag_rx_err <=  fifo_tuser;

                        case (rx_cnt)
                             8'd00: begin ip_vis_tos[15:08]  <=  fifo_tdata; end
                             8'd01: begin ip_vis_tos[07:00]  <=  fifo_tdata; end
                             // 16位IP总长度 = 20字节IP帧头 + 8字节UDP帧头 + 数据
                             8'd02: begin end   
                             8'd03: begin end
                             // 16位标识 用于CMD返回
                             8'd04: begin ip_idf[15:08] <= fifo_tdata; end
                             8'd05: begin ip_idf[07:00] <= fifo_tdata; end        // 不清零
                             // 16位标志+偏移                                
                             8'd06: begin end
                             8'd07: begin end
                             // 8位 TTL protocol  用于CMD返回
                             8'd08: begin ip_ttl_prtc[15:08]   <= fifo_tdata; end  // 不清零
                             8'd09: begin ip_ttl_prtc[07:00]   <= fifo_tdata; end
                             // 16位首部校验和
                             8'd10: begin end
                             8'd11: begin end
                             // 32位源IP地址
                             8'd12: begin sa_ip[31:24] <= fifo_tdata; end
                             8'd13: begin sa_ip[23:16] <= fifo_tdata; end
                             8'd14: begin sa_ip[15:08] <= fifo_tdata; end
                             8'd15: begin sa_ip[07:00] <= fifo_tdata; end
                             // 32位目的IP地址
                             8'd16: begin da_ip[31:24] <= fifo_tdata; end
                             8'd17: begin da_ip[23:16] <= fifo_tdata; end
                             8'd18: begin da_ip[15:08] <= fifo_tdata; end
                             8'd19: begin da_ip[07:00] <= fifo_tdata; fifo_tready <= 0;end                
                             default : begin end                    
                        endcase                       
                    end
                end // IP_HEADER 

                UDP_HEADER : begin
                    if (rx_cnt == UDP_HEAD_LENGTH + 4) begin
                        if (udp_dp == LOCAL_DP) begin
                            flag_rx_over    <=  1;
                        end
                        else begin
                            flag_rx_over    <=  0;
                            flag_rx_err     <=  1;                            
                        end
                        rx_cnt          <=  0;
                        udp_data_len    <=  udp_len - UDP_HEAD_LENGTH - 4; // data_len : substract 4-byte awaddr
                    end
                    else begin
                        flag_rx_over<=  0;
                        fifo_tready <=  1;
                        rx_cnt      <=  rx_cnt + (fifo_tvalid && fifo_tready);
                        flag_rx_err <=  fifo_tuser;

                        case (rx_cnt)
                             // 16位源端口号
                             8'd00: begin udp_sp[15:08] <= fifo_tdata; end
                             8'd01: begin udp_sp[07:00] <= fifo_tdata; end
                             // 16位目的端口号
                             8'd02: begin udp_dp[15:08] <= fifo_tdata; end
                             8'd03: begin udp_dp[07:00] <= fifo_tdata; end
                             // 16位UDP长度
                             8'd04: begin udp_len[15:08] <= fifo_tdata; end
                             8'd05: begin udp_len[07:00] <= fifo_tdata; end
                             // 16位UDP校验和                             
                             8'd06: begin end
                             8'd07: begin end
                             // 数据标识
                             8'd08: begin axi_awaddr[31:24] <= fifo_tdata; end
                             8'd09: begin axi_awaddr[23:16] <= fifo_tdata; end
                             8'd10: begin axi_awaddr[15:08] <= fifo_tdata; end
                             8'd11: begin axi_awaddr[07:00] <= fifo_tdata; fifo_tready   <=  0;end                 
                             default : begin end                    
                        endcase                       
                    end                    
                end  

                ARP : begin
                    if (fifo_tlast) begin
                        if (arp_opcode == ARP_REQUEST && arp_da_ip == LOCAL_IP) begin // ARP 请求 + 目的IP匹配
                            flag_rx_over    <=  1;
                            o_trig_arp_tx   <=  1;
                        end
                        else begin
                            flag_rx_over    <=  0;
                            flag_rx_err     <=  1;  
                            o_trig_arp_tx   <=  0;                          
                        end
                        rx_cnt <= 0;
                    end
                    else begin
                        flag_rx_over<=  0;
                        fifo_tready <=  1;
                        rx_cnt      <=  rx_cnt + (fifo_tvalid && fifo_tready);
                        flag_rx_err <=  fifo_tuser;

                        case (rx_cnt) 
                            // ARP operate code     16’h0001 : request
                            8'd06: begin arp_opcode[15:08] <= fifo_tdata; end
                            8'd07: begin arp_opcode[07:00] <= fifo_tdata; end                
                            // source mac
                            8'd08: begin arp_sa_mac[47:40] <= fifo_tdata; end
                            8'd09: begin arp_sa_mac[39:32] <= fifo_tdata; end
                            8'd10: begin arp_sa_mac[31:24] <= fifo_tdata; end
                            8'd11: begin arp_sa_mac[23:16] <= fifo_tdata; end
                            8'd12: begin arp_sa_mac[15:08] <= fifo_tdata; end
                            8'd13: begin arp_sa_mac[07:00] <= fifo_tdata; end                
                            // source ip                               
                            8'd14: begin arp_sa_ip[31:24] <= fifo_tdata; end
                            8'd15: begin arp_sa_ip[23:16] <= fifo_tdata; end
                            8'd16: begin arp_sa_ip[15:08] <= fifo_tdata; end
                            8'd17: begin arp_sa_ip[07:00] <= fifo_tdata; end
                             // target ip 
                            8'd24: begin arp_da_ip[31:24] <= fifo_tdata; end
                            8'd25: begin arp_da_ip[23:16] <= fifo_tdata; end
                            8'd26: begin arp_da_ip[15:08] <= fifo_tdata; end
                            8'd27: begin arp_da_ip[07:00] <= fifo_tdata; fifo_tready   <=  0;end                
                            default : begin  end
                        endcase                                 
                    end                     
                end // ARP

                AXI_ADDR : begin
                    flag_rx_over<=  0;
                    m_awaddr    <=  axi_awaddr;
                    m_awvalid   <=  1;
                end // AXI_ADDR 

                AXI_DATA : begin
                    m_awaddr    <=  '0;
                    m_awvalid   <=  '0;

                    //  considering if wready is asserted according to wvalid, fifo_tready should wait for handshark
                    fifo_tready                 <=  (byte_cnt == 1) ?  m_axi_wready : !fifo_tlast;    
                    rx_cnt                      <=  rx_cnt + (fifo_tvalid && fifo_tready);                    
                    byte_cnt                    <=  byte_cnt - (fifo_tvalid && fifo_tready);

                    //  if udp_data_len*8 can be divided by C_AXI_DATA_WIDTH
                    if (udp_data_len[AXI_SIZE-1 : 0] == '0) begin
                        m_wdata[8*byte_cnt +: 8]    <=  fifo_tdata;
                        m_wvalid                    <=  (byte_cnt == '0);  
                        m_wlast                     <=  (rx_cnt == udp_data_len - 1);                   
                    end
                    else begin
                        if (rx_cnt < (udp_data_len & {16'hFFFF << AXI_SIZE})) begin
                            m_wdata[8*byte_cnt +: 8]    <=  fifo_tdata;
                            m_wvalid                    <=  (byte_cnt == '0); 
                        end
                        //  last m_wdata should be shifted right -> {00,..,valid_data}
                        else begin
                            if (fifo_tlast) begin
                                if (fifo_tvalid) begin
                                    m_wdata[8*byte_cnt +: 8]    <=  fifo_tdata;                                    
                                    m_wvalid                    <=  0;                                    
                                end
                                else begin
                                    //  fifo_tdata is written to m_wadata from MSB, a right-shift should be applied
                                    m_wdata  <=  m_wdata >> (({AXI_SIZE{1'b1}} - (udp_data_len[AXI_SIZE-1 : 0] -1)) << 3);
                                    m_wvalid <=  1;
                                end
                            end
                            else begin
                                m_wdata[8*byte_cnt +: 8]    <=  fifo_tdata;
                                m_wvalid                    <=  0;
                            end
                            m_wlast                     <=  1;
                        end                 
                    end                  
                end // AXI_DATA 

                AXI_RESPONSE : begin
                    fifo_tready <=  '0;
                    m_wdata     <=  '0;    
                    m_wvalid    <=  '0;
                    m_wlast     <=  '0;

                    m_bready    <=  1;
                    watch_dog   <=  watch_dog + 1;
                end // AXI_RESPONSE     

                default : begin
                    watch_dog     <=  '0;
                    rx_cnt        <=  '0; 
                    eth_type      <=  '0;
                    eth_da_mac    <=  '0;
                    eth_sa_mac    <=  '0;
                    ip_idf        <=  '0;
                    ip_vis_tos    <=  '0;
                    ip_ttl_prtc   <=  '0;
                    da_ip         <=  '0;
                    sa_ip         <=  '0;
                    udp_dp        <=  '0;
                    udp_sp        <=  '0;
                    udp_len       <=  '0;
                    axi_awaddr    <=  '0;
                    arp_sa_mac    <=  arp_sa_mac;
                    arp_sa_ip     <=  arp_sa_ip;
                    arp_da_ip     <=  '0;
                    arp_opcode    <=  '0;
                    m_awaddr      <=  '0;
                    m_awvalid     <=  '0;
                    m_wdata       <=  '0; 
                    m_wlast       <=  '0;
                    m_wvalid      <=  '0;
                    m_bready      <=  '0; 
                    byte_cnt      <=  {AXI_SIZE{1'b1}};   
                    fifo_tready   <=  flag_rx_err ? fifo_tvalid : 0;
                    flag_rx_err   <=  fifo_tlast  ? 0 : flag_rx_err;
                    flag_rx_over  <=  '0;
                    flag_arp      <=  '0;   
                    udp_data_len  <=  '0;  
                    o_trig_arp_tx <=  '0;                            
                end // default :
            endcase
        end

 endmodule : eth_rx