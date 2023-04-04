`timescale 1ns / 1ps
/* -----------------------------------------------------------------------------
 Copyright (c) 2014-2021 All rights reserved
 -----------------------------------------------------------------------------
 Author     : lwings    https://github.com/Lvwings
 File       : udp_tx.sv
 Create     : 2022-06-21 15:11:00
 Revise     : 2022-06-21 15:11:00
 Language   : Verilog 2001
 -----------------------------------------------------------------------------*/

 module eth_tx #(
        // UDP parameters
        parameter LOCAL_IP                  =   32'hC0A8_006E,
        parameter LOCAL_MAC                 =   48'hABCD_1234_5678,
        parameter LOCAL_SP                  =   16'd8080,
        parameter LOCAL_DP                  =   16'd8080,    
        // AXI information          
        parameter C_AXI_ADDR_WIDTH          =   32,               // This is AXI address width for all         // SI and MI slots
        parameter C_AXI_DATA_WIDTH          =   64,               // Width of the AXI write and read data
        parameter C_AXI_ID_WIDTH            =   3,
        // FIFO DEPTH
        parameter TX_FIFO_BYTE_DEPTH        =   1024

     )(
        input                               axi_clk,
        input                               axi_rstn,    
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

    // AXIS TX RGMII
        output  [7:0]                       rgmii_tdata,
        output                              rgmii_tvalid,
        output                              rgmii_tlast,
        output                              rgmii_tuser,
        input                               rgmii_tready,

    // arp 
        input                               trig_arp_tx,
        input   [31:0]                      target_ip,
        input   [47:0]                      target_mac         
     
 );
/*------------------------------------------------------------------------------
--  reset localization
------------------------------------------------------------------------------*/
    logic   local_rstn   =   '0;

    always_ff @(posedge axi_clk) begin
        local_rstn <= axi_rstn;
    end    
/*-----------------------------------------------------------------------------    
// AXI Internal logicister and wire declarations
//---------------------------------------------------------------------------*/            

// AXI write address channel signals
    logic [C_AXI_ADDR_WIDTH-1:0]      s_awaddr  =   '0;
    logic                             s_awvalid =   '0;  
    logic                             s_awready =   '0;

// AXI write data channel signals
    logic [C_AXI_DATA_WIDTH-1:0]      s_wdata   =   '0;
    logic                             s_wready  =   '0;

// AXI write response channel signals 
    logic                             s_bvalid  =   '0;
    logic [1:0]                       s_bresp   =   '0;

// AXI read address channel signals
    logic [C_AXI_ADDR_WIDTH-1:0]      s_araddr  =   '0;
    logic                             s_aready  =   '0;

// AXI read data channel signals    
    logic [1:0]                       s_rresp   =   '0;
    logic                             s_rvalid  =   '0;
    logic [C_AXI_DATA_WIDTH-1:0]      s_rdata   =   '0;  
    logic                             s_rlast   =   '0;

    //  awready
    logic       fifo_sready;
    always_ff @(posedge axi_clk) begin
        s_awready <= local_rstn && fifo_sready;
    end

    logic   flag_data_over  =   '0;
    always_ff @(posedge axi_clk) begin
        flag_data_over  <=  s_axi_wvalid && s_axi_wready && s_axi_wlast;
    end    

    assign  s_axi_awready   =   s_awready;
    assign  s_axi_bvalid    =   flag_data_over; 
/*-----------------------------------------------------------------------------    
// AXI support signals
//---------------------------------------------------------------------------*/            

    // function called clogb2 that returns an integer which has the value of the ceiling of the log base 2.                      
    function integer clogb2 (input integer bit_depth);              
        begin                                                           
            for(clogb2=0; bit_depth>0; clogb2=clogb2+1)                   
                bit_depth = bit_depth >> 1;                                 
        end                                                           
    endfunction 

    //  AXI_SIZE : the data bytes of each burst
    localparam  [2:0]   AXI_SIZE        =   clogb2(C_AXI_DATA_WIDTH/8-1);

    //  AXI_ADDR_INC : axi address increment associate with data width
    localparam  [7:0]   AXI_ADDR_INC    =   C_AXI_DATA_WIDTH/8;

/*------------------------------------------------------------------------------
--  receive data from axi-lite
------------------------------------------------------------------------------*/         

    //  rx fifo
    localparam  FIFO_DEPTH  = TX_FIFO_BYTE_DEPTH*8/C_AXI_DATA_WIDTH;  //  udp length < 1500-byte  
    logic   [C_AXI_DATA_WIDTH-1 : 0]    fifo_tdata;
    logic                               fifo_tvalid;
    logic                               fifo_tready;
    logic                               fifo_tlast;

    xpm_fifo_axis #(
        .CLOCKING_MODE  ("common_clock"),       //  "common_clock" or "independent_clock"  Default value = "common_clock". 
        .RELATED_CLOCKS (0),                    //  Specifies if the s_aclk and m_aclk are related having the same source but different clock ratios. Default value = 0 
        .FIFO_DEPTH     (FIFO_DEPTH),           //  Range: 16 - 4194304. Default value = 2048
        .TDATA_WIDTH    (C_AXI_DATA_WIDTH),     //  Range: 8 - 2048. Default value = 32        
        .PACKET_FIFO    ("false")               //  "false" or "true". Default value = "false"      
   )
   udp_tx_fifo (
    //  axis slave
        .s_aclk         (axi_clk),                        
        .s_aresetn      (local_rstn),                 
        .s_axis_tdata   (s_axi_wdata), 
        .s_axis_tvalid  (s_axi_wvalid && s_axi_wready), 
        .s_axis_tready  (fifo_sready), 
        .s_axis_tlast   (s_axi_wlast),
        .s_axis_tuser   (), 

    //  axis master    
        .m_aclk         (axi_clk),                                                                      
        .m_axis_tdata   (fifo_tdata),           
        .m_axis_tvalid  (fifo_tvalid),
        .m_axis_tready  (fifo_tready), 
        .m_axis_tlast   (fifo_tlast), 
        .m_axis_tuser   ()
   ); 

 /*------------------------------------------------------------------------------
 --  eth frame paramter
 ------------------------------------------------------------------------------*/
    localparam  GLOBAL_MAC      =   48'hFFFF_FFFF_FFFF;
    localparam  IP_TYPE         =   16'h0800;
    //  IP HEAD
    localparam  IP_VISION_TOS   =   16'h4500;   //  vision 4, length 5, tos 00
    localparam  IP_FLAG_OFFSET  =   16'h4000;   //  dont fragment flag = 1
    localparam  IP_TTL_PROTO    =   16'h8011;   //  TTL 80, proto 11 (udp)

    localparam  ETH_HEAD_LENGTH =   8'd14;
    localparam  IP_HEAD_LENGTH  =   8'd20;    
    localparam  UDP_HEAD_LENGTH =   8'd8;
    localparam  UDP_MIN_LENGTH  =   8'd26;      //  UDP_HEAD_LENGTH + MIN_DATA_LENGTH
    localparam  ARP_LENGTH      =   8'd42;      //  include ETH_HEAD_LENGTH

/*------------------------------------------------------------------------------
--  send arp

     Destination MAC address     6 octets
     Source MAC address          6 octets
     Ethertype (0x0806)          2 octets       14

     HTYPE (1)                   2 octets       ----- ARP_PROTO
     PTYPE (0x0800)              2 octets
     HLEN (6)                    1 octets
     PLEN (4)                    1 octets       20

     OPER                        2 octets       ----- ARP_RLOCAL         
     SHA Sender MAC              6 octets
     SPA Sender IP               4 octets       32

     THA Target MAC              6 octets
     TPA Target IP               4 octets       42
------------------------------------------------------------------------------*/ 
    localparam          ARP_TYPE            =   16'h0806;
    localparam          OPCODE_QUERY        =   16'h0001;
    localparam          OPCODE_RESPONSE     =   16'h0002;    
    localparam  [47:0]  ARP_PROTO           =   {16'h0001,16'h0800,8'h06,8'h04};
    localparam  [95:0]  ARP_QLOCAL          =   {OPCODE_QUERY, LOCAL_MAC, LOCAL_IP};
    localparam  [95:0]  ARP_RLOCAL          =   {OPCODE_RESPONSE, LOCAL_MAC, LOCAL_IP};    

/*-----------------------------------------------------------------------------    
// state machine declarations (* fsm_encoding = "one-hot" *)
//---------------------------------------------------------------------------*/            
    typedef enum   {IDLE,ETH_HEAD,IP_HEAD,UDP_HEAD,UDP_DATA,ARP}    state_t;
    state_t udp_state,udp_next;

    always_ff @(posedge axi_clk) begin 
        if(!local_rstn) begin
            udp_state <= IDLE;
        end else begin
            udp_state <= udp_next;
        end
    end

/*-----------------------------------------------------------------------------    
// state jump
//---------------------------------------------------------------------------*/            
    logic           flag_tx_start   =   '0;
    logic           flag_tx_over    =   '0;

    always_ff @(posedge axi_clk) begin 
        flag_tx_start    <= s_axi_bvalid && s_axi_bready;
    end
    
    always_comb begin 
        case (udp_state)
            IDLE        :   udp_next    =   flag_tx_start   ? ETH_HEAD  : (trig_arp_tx ? ARP : IDLE);
            ETH_HEAD    :   udp_next    =   flag_tx_over    ? IP_HEAD   : ETH_HEAD;
            IP_HEAD     :   udp_next    =   flag_tx_over    ? UDP_HEAD  : IP_HEAD;
            UDP_HEAD    :   udp_next    =   flag_tx_over    ? UDP_DATA  : UDP_HEAD;
            UDP_DATA    :   udp_next    =   flag_tx_over    ? IDLE      : UDP_DATA;
            ARP         :   udp_next    =   flag_tx_over    ? IDLE      : ARP;
            default :       udp_next    =   IDLE;
        endcase
    end 
   
/*------------------------------------------------------------------------------
--  udp data sum calculate
------------------------------------------------------------------------------*/
    logic   [31:0]      udp_datasum     =   '0;
    logic   [15:0]      udp_data_cnt    =   '0;     //   byte counter
    logic   [15:0]      ip_length       =   '0;
    logic   [15:0]      udp_length      =   '0;
    logic   [15:0]      ip_length_r     =   '0;
    logic   [15:0]      udp_length_r    =   '0;  

    localparam  WORD_SIZE   =   (C_AXI_DATA_WIDTH >> 4);

    logic   [31 : 0] one_datasum [WORD_SIZE : 0];
    assign  one_datasum[0] = '0;

    genvar i;
    generate
         for (i = 0; i < WORD_SIZE; i = i+1) begin
            lca_mbit #(.DATA_WIDTH(32)) 
            inst_lca_onedata (
                .a(one_datasum[i]), 
                .b({16'h0,s_axi_wdata[16*i +: 16]}), 
                .cin(0), 
                .sum(one_datasum[i+1]), 
                .cout());
        end       
    endgenerate

    assign  s_axi_wready = s_axi_wvalid && fifo_sready;

    always_ff @(posedge axi_clk) begin 
        if (flag_tx_start) begin
            udp_datasum     <=  '0;
            udp_data_cnt    <=  '0;
            ip_length       <=  '0;
            udp_length      <=  '0;            
            ip_length_r     <=  ip_length ;
            udp_length_r    <=  udp_length;           
        end
        else begin                  
            if (flag_data_over) begin
                ip_length    <=  udp_data_cnt + UDP_HEAD_LENGTH + IP_HEAD_LENGTH;
                udp_length   <=  udp_data_cnt + UDP_HEAD_LENGTH;
            end 
            else if (s_axi_wvalid && s_axi_wready) begin
                udp_datasum  <=  udp_datasum + one_datasum[WORD_SIZE];
                udp_data_cnt <=  udp_data_cnt + (WORD_SIZE << 1);
            end 
            else begin
                udp_datasum  <=  udp_datasum;
                udp_data_cnt <=  udp_data_cnt;
            end         
        end 
    end    

/*------------------------------------------------------------------------------
--  eth head 
------------------------------------------------------------------------------*/
    logic   [15:0]  octec_cnt       =   '0;     //  byte counter
    logic   [15:0]  ip_identify     =   '0;
    logic   [31:0]  ip_checksum     =   '0; 
    logic   [31:0]  udp_checksum    =   '0;
    logic   [15:0]  udp_data_len    =   '0; 


    logic   [7:0]   o_tdata         =   '0;
    logic           o_tvalid        =   '0;
    logic           o_tlast         =   '0;

    assign          rgmii_tdata     =   o_tdata;
    assign          rgmii_tvalid    =   o_tvalid;
    assign          rgmii_tlast     =   o_tlast;
    assign          rgmii_tuser     =   '0;

    //  ip_identify
    always_ff @(posedge axi_clk) begin
        if (!axi_rstn) begin
            ip_identify <=  '0;
        end
        else begin
            if (s_axi_bvalid && s_axi_bready)
                ip_identify <=  ip_identify + 1;
            else
                ip_identify <=  ip_identify;
        end
    end
    

    logic   [AXI_SIZE-1 : 0]    byte_cnt    =   '0;

    always_ff @(posedge axi_clk) begin 
        case (udp_next)
            ETH_HEAD    : begin
                    if (octec_cnt == ETH_HEAD_LENGTH-1) begin
                        octec_cnt           <=  0;
                        flag_tx_over        <=  1;
                    end
                    else begin
                        octec_cnt           <=  octec_cnt + (rgmii_tvalid && rgmii_tready);
                        flag_tx_over        <=  0;                                             
                    end
                    
                    o_tvalid        <=  1;
                    udp_data_len    <=  udp_data_cnt;

                    case (octec_cnt)
                            16'd00  :   o_tdata   <=  rgmii_tready ? target_mac[39:32] : target_mac[47:40];
                            16'd01  :   o_tdata   <=  target_mac[31:24];
                            16'd02  :   o_tdata   <=  target_mac[23:16];
                            16'd03  :   o_tdata   <=  target_mac[15:08];
                            16'd04  :   o_tdata   <=  target_mac[07:00];
                            16'd05  :   o_tdata   <=  LOCAL_MAC[47:40];
                            16'd06  :   o_tdata   <=  LOCAL_MAC[39:32];
                            16'd07  :   o_tdata   <=  LOCAL_MAC[31:24];
                            16'd08  :   o_tdata   <=  LOCAL_MAC[23:16];
                            16'd09  :   o_tdata   <=  LOCAL_MAC[15:08];
                            16'd10  :   o_tdata   <=  LOCAL_MAC[07:00];
                            16'd11  :   o_tdata   <=  IP_TYPE[15:08];
                            16'd12  :   o_tdata   <=  IP_TYPE[07:00];
                            16'd13  :   o_tdata   <=  IP_VISION_TOS[15:8];    //  next data
                            default :   o_tdata   <=  '0;
                    endcase                                                                                                      
            end // ETH_HEAD    

            IP_HEAD     : begin
                    if (octec_cnt == IP_HEAD_LENGTH-1) begin
                        octec_cnt           <=  0;
                        flag_tx_over        <=  1;                        
                    end
                    else begin
                        octec_cnt           <=  octec_cnt + (rgmii_tvalid && rgmii_tready);
                        flag_tx_over        <=  0;                       
                    end

                    case (octec_cnt)
                            16'd00  :   o_tdata   <=  IP_VISION_TOS[7:0];
                            16'd01  :   o_tdata   <=  ip_length_r[15:8];
                            16'd02  :   o_tdata   <=  ip_length_r[07:0];
                            16'd03  :   o_tdata   <=  ip_identify[15:8];
                            16'd04  :   o_tdata   <=  ip_identify[07:0];
                            16'd05  :   o_tdata   <=  IP_FLAG_OFFSET[15:8];
                            16'd06  :   o_tdata   <=  IP_FLAG_OFFSET[07:0];
                            16'd07  :   o_tdata   <=  IP_TTL_PROTO[15:8];
                            16'd08  :   o_tdata   <=  IP_TTL_PROTO[07:0];
                            16'd09  :   o_tdata   <=  ip_checksum[15:8];
                            16'd10  :   o_tdata   <=  ip_checksum[07:0];
                            16'd11  :   o_tdata   <=  LOCAL_IP[31:24];
                            16'd12  :   o_tdata   <=  LOCAL_IP[23:16];
                            16'd13  :   o_tdata   <=  LOCAL_IP[15:8];
                            16'd14  :   o_tdata   <=  LOCAL_IP[07:0];
                            16'd15  :   o_tdata   <=  target_ip[31:24];
                            16'd16  :   o_tdata   <=  target_ip[23:16];
                            16'd17  :   o_tdata   <=  target_ip[15:8];
                            16'd18  :   o_tdata   <=  target_ip[07:0];
                            16'd19  :   o_tdata   <=  LOCAL_SP[15:8];     //  next data                 
                            default :   o_tdata   <=  '0;
                    endcase  
            end // IP_HEAD    

            UDP_HEAD    : begin
                    if (octec_cnt == UDP_HEAD_LENGTH-1) begin
                        octec_cnt           <=  0;
                        flag_tx_over        <=  1;                                             
                    end
                    else begin
                        octec_cnt           <=  octec_cnt + (rgmii_tvalid && rgmii_tready);
                        flag_tx_over        <=  0;                       
                    end

                    case (octec_cnt)
                            16'd00  :       o_tdata   <=  LOCAL_SP[7:0];
                            16'd01  :       o_tdata   <=  LOCAL_DP[15:8];
                            16'd02  :       o_tdata   <=  LOCAL_DP[07:0];
                            16'd03  :       o_tdata   <=  udp_length_r[15:8];
                            16'd04  :       o_tdata   <=  udp_length_r[07:0];
                            16'd05  :       o_tdata   <=  udp_checksum[15:8];
                            16'd06  :       o_tdata   <=  udp_checksum[07:0];
                            16'd07  :       o_tdata   <=  fifo_tdata[C_AXI_DATA_WIDTH -1 -: 8];       //  next data                   
                            default :       o_tdata   <=  '0;
                    endcase
            end // UDP_HEAD 

            UDP_DATA    : begin
                    if (rgmii_tlast) begin
                        flag_tx_over <=  1;
                        fifo_tready  <=  '0;
                        o_tdata      <=  '0;
                        o_tvalid     <=  '0;
                        o_tlast      <=  '0;                        
                    end
                    else begin
                        byte_cnt            <=  byte_cnt - (rgmii_tvalid && rgmii_tready);
                        flag_tx_over        <=  0; 

                        fifo_tready <=  (byte_cnt == 1);
                        o_tdata     <=  fifo_tdata[8*byte_cnt +: 8];
                        o_tlast     <=  fifo_tlast && (byte_cnt == '0);                                              
                    end

            end // UDP_DATA    

            ARP     : begin
                    if (octec_cnt == ARP_LENGTH - 1) begin
                        octec_cnt       <=  0;
                        flag_tx_over    <=  1;
                        o_tdata         <=  '0;
                        o_tvalid        <=  '0;
                        o_tlast         <=  '0;                                                                                                                      
                    end
                    else begin
                        octec_cnt       <=  octec_cnt + (rgmii_tvalid && rgmii_tready);
                        flag_tx_over    <=  0;

                        o_tvalid        <=  1;
                        o_tlast         <=  (octec_cnt == 40);
                        case (octec_cnt)
                                16'd00  :   o_tdata   <=  rgmii_tready ? target_mac[39:32] : target_mac[47:40];
                                16'd01  :   o_tdata   <=  target_mac[31:24];
                                16'd02  :   o_tdata   <=  target_mac[23:16];
                                16'd03  :   o_tdata   <=  target_mac[15:08];
                                16'd04  :   o_tdata   <=  target_mac[07:00];
                                16'd05  :   o_tdata   <=  LOCAL_MAC[47:40];
                                16'd06  :   o_tdata   <=  LOCAL_MAC[39:32];
                                16'd07  :   o_tdata   <=  LOCAL_MAC[31:24];
                                16'd08  :   o_tdata   <=  LOCAL_MAC[23:16];
                                16'd09  :   o_tdata   <=  LOCAL_MAC[15:08];
                                16'd10  :   o_tdata   <=  LOCAL_MAC[07:00];
                                16'd11  :   o_tdata   <=  ARP_TYPE[15:08];
                                16'd12  :   o_tdata   <=  ARP_TYPE[07:00];                                        
                            default : begin
                                if (octec_cnt < 19)
                                    o_tdata <=  ARP_PROTO[8*(18-octec_cnt) +: 8];
                                else if (octec_cnt < 31)
                                    o_tdata <=  ARP_RLOCAL[8*(30-octec_cnt) +: 8];
                                else if (octec_cnt < 37) 
                                    o_tdata <=  target_mac[8*(36-octec_cnt) +: 8];
                                else
                                    o_tdata <=  target_ip[8*(40-octec_cnt) +: 8];
                            end
                        endcase  
                    end                  
            end
            default : begin
                    octec_cnt    <=  '0;
                    byte_cnt     <=  {AXI_SIZE{1'b1}} -1;
                    flag_tx_over <=  '0;
                    fifo_tready  <=  '0;
                    udp_data_len <=  '0;
                    o_tdata      <=  '0;
                    o_tvalid     <=  '0;
                    o_tlast      <=  '0;               
            end // default 
        endcase
    end
/*------------------------------------------------------------------------------
--  IP check sum
------------------------------------------------------------------------------*/
    localparam  [31:0]  IP_LOCAL_SUM    =   IP_VISION_TOS + IP_FLAG_OFFSET + IP_TTL_PROTO + LOCAL_IP[31:16] + LOCAL_IP[15:0];
    logic       [16:0]  ip_sum; 

    lca_mbit #(.DATA_WIDTH(16)) 
    inst_lca_ipsum (
        .a(target_ip[31:16]), 
        .b(target_ip[15:0]), 
        .cin(0), 
        .sum(ip_sum[15:0]), 
        .cout(ip_sum[16]));

    logic       [31:0]  ip_checkdata [2:0];

    always_ff @(posedge axi_clk) begin 
        if (flag_tx_start) begin
            ip_checkdata[0]    <=  ip_sum;
            ip_checkdata[1]    <=  ip_identify;
            ip_checkdata[2]    <=  ip_length;
        end
    end 

    always_ff @(posedge axi_clk) begin 
        case (udp_state)
            IDLE        : begin
                    ip_checksum     <= IP_LOCAL_SUM;
            end // IDLE       
            
            //  When using IP [tri-mode eth mac] as MAC, transmission signal [tx_axis_ready] will be deasserted
            //  after 2nd handshake for several clocks (see figure 3-22)
            //  So the ip/udp checksum starts calculating after 3rd handshake. 
            ETH_HEAD    : begin
                   case (octec_cnt)                        
                       16'h3,16'h4,16'h5  :   ip_checksum <=  ip_checksum + ip_checkdata[octec_cnt-3];
                       16'h6  :     ip_checksum <=  ip_checksum[31:16] + ip_checksum[15:0];   
                       16'h7  :     ip_checksum <=  ~(ip_checksum[31:16] + ip_checksum[15:0]);                     
                       default :   ip_checksum <=  ip_checksum;
                   endcase                    
            end // ETH_HEAD    
    
            default : begin
                     ip_checksum <=  ip_checksum;
            end
        endcase
    end
/*------------------------------------------------------------------------------
--  udp check sum
    check range : pseudo header + udp header + data

    pseudo header
    source ip (4 octets) destination ip (4 octets) 0 (1 octet) 11 (1 octet) udp length (2 octet)
------------------------------------------------------------------------------*/
    localparam  [31:0]  UDP_LOCAL_SUM   =   LOCAL_IP[31:16] + LOCAL_IP[15:0] + {8'h00,8'h11} + LOCAL_SP + LOCAL_DP;
    logic       [31:0]  udp_checkdata [2:0];


    always_ff @(posedge axi_clk) begin 
        if (flag_tx_start) begin
            udp_checkdata[0]    <=  ip_sum;
            udp_checkdata[1]    <=  udp_datasum;
            udp_checkdata[2]    <=  udp_length << 1;
        end
    end
      
    always_ff @(posedge axi_clk) begin 
        case (udp_state)
            IDLE    : begin
                    udp_checksum    <=  UDP_LOCAL_SUM;
            end // IDLE   

            ETH_HEAD : begin
                    case (octec_cnt)
                        16'h3,16'h4,16'h5  : udp_checksum <=  udp_checksum + udp_checkdata[octec_cnt-3]; 
                        16'h6  :   udp_checksum <=  udp_checksum[31:16] + udp_checksum[15:0];    
                        16'h7  :   udp_checksum <=  ~(udp_checksum[31:16] + udp_checksum[15:0]);                    
                        default :   udp_checksum <=  udp_checksum;
                    endcase                                         
            end // ETH_HEAD 

            default : begin
                    udp_checksum    <=  udp_checksum;
            end // default
        endcase
    end 

 endmodule : eth_tx