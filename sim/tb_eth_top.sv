
`timescale 1ns/1ps

module tb_eth_top (); /* this is automatically generated */

    // clock
    logic clk;
    initial begin
        clk = '0;
        forever #(4) clk = ~clk;
    end

    // synchronous reset
    logic srstb;
    initial begin
        srstb <= '0;
        repeat(10)@(posedge clk);
        srstb <= '1;
    end

    // (*NOTE*) replace reset, clock, others

    parameter         LOCAL_IP = 32'hC0A8_006E;
    parameter        LOCAL_MAC = 48'h00D0_0800_0002;
    parameter         LOCAL_SP = 16'd8080;
    parameter         LOCAL_DP = 16'd8080;
    parameter C_AXI_ADDR_WIDTH = 32;
    parameter C_AXI_DATA_WIDTH = 32;
    parameter   C_AXI_ID_WIDTH = 3;
    parameter  C_BEGIN_ADDRESS = 0;
    parameter    C_END_ADDRESS = 32'hFFFF_FFFF;

    logic                          axi_clk;
    logic                          axi_rstn;
    logic                          m_axi_awready;
    logic   [C_AXI_ADDR_WIDTH-1:0] m_axi_awaddr;
    logic                          m_axi_awvalid;
    logic                          m_axi_wready;
    logic   [C_AXI_DATA_WIDTH-1:0] m_axi_wdata;
    logic [C_AXI_DATA_WIDTH/8-1:0] m_axi_wstrb;
    logic                          m_axi_wlast;
    logic                          m_axi_wvalid;
    logic                    [1:0] m_axi_bresp;
    logic                          m_axi_bvalid;
    logic                          m_axi_bready;
    logic                          m_axi_arready;
    logic   [C_AXI_ADDR_WIDTH-1:0] m_axi_araddr;
    logic                          m_axi_arvalid;
    logic                    [1:0] m_axi_rresp;
    logic                          m_axi_rvalid;
    logic   [C_AXI_DATA_WIDTH-1:0] m_axi_rdata;
    logic                          m_axi_rlast;
    logic                          m_axi_rready;
    logic                          s_axi_awready;
    logic     [C_AXI_ID_WIDTH-1:0] s_axi_awid;
    logic   [C_AXI_ADDR_WIDTH-1:0] s_axi_awaddr;
    logic                    [7:0] s_axi_awlen;
    logic                    [2:0] s_axi_awsize;
    logic                    [1:0] s_axi_awburst;
    logic                    [1:0] s_axi_awlock;
    logic                    [3:0] s_axi_awcache;
    logic                    [2:0] s_axi_awprot;
    logic                          s_axi_awvalid;
    logic                          s_axi_wready;
    logic   [C_AXI_DATA_WIDTH-1:0] s_axi_wdata;
    logic [C_AXI_DATA_WIDTH/8-1:0] s_axi_wstrb;
    logic                          s_axi_wlast;
    logic                          s_axi_wvalid;
    logic     [C_AXI_ID_WIDTH-1:0] s_axi_bid;
    logic                    [1:0] s_axi_bresp;
    logic                          s_axi_bvalid;
    logic                          s_axi_bready;
    logic                          s_axi_arready;
    logic     [C_AXI_ID_WIDTH-1:0] s_axi_arid;
    logic   [C_AXI_ADDR_WIDTH-1:0] s_axi_araddr;
    logic                    [7:0] s_axi_arlen;
    logic                    [2:0] s_axi_arsize;
    logic                    [1:0] s_axi_arburst;
    logic                    [1:0] s_axi_arlock;
    logic                    [3:0] s_axi_arcache;
    logic                    [2:0] s_axi_arprot;
    logic                          s_axi_arvalid;
    logic     [C_AXI_ID_WIDTH-1:0] s_axi_rid;
    logic                    [1:0] s_axi_rresp;
    logic                          s_axi_rvalid;
    logic   [C_AXI_DATA_WIDTH-1:0] s_axi_rdata;
    logic                          s_axi_rlast;
    logic                          s_axi_rready;
    logic                          rgmii_rxc;
    logic                    [7:0] rgmii_rdata;
    logic                          rgmii_rvalid;
    logic                          rgmii_rlast;
    logic                          rgmii_ruser;
    logic                          rgmii_rready;
    logic                    [7:0] rgmii_tdata;
    logic                          rgmii_tvalid;
    logic                          rgmii_tlast;
    logic                          rgmii_tuser;
    logic                          rgmii_tready;

    eth_top #(
            .LOCAL_IP(LOCAL_IP),
            .LOCAL_MAC(LOCAL_MAC),
            .LOCAL_SP(LOCAL_SP),
            .LOCAL_DP(LOCAL_DP),
            .C_AXI_ADDR_WIDTH(C_AXI_ADDR_WIDTH),
            .C_AXI_DATA_WIDTH(C_AXI_DATA_WIDTH),
            .C_AXI_ID_WIDTH(C_AXI_ID_WIDTH),
            .C_BEGIN_ADDRESS(C_BEGIN_ADDRESS),
            .C_END_ADDRESS(C_END_ADDRESS)
        ) inst_eth_top (
            .axi_clk       (axi_clk),
            .axi_rstn      (axi_rstn),
            .m_axi_awready (m_axi_awready),
            .m_axi_awaddr  (m_axi_awaddr),
            .m_axi_awvalid (m_axi_awvalid),
            .m_axi_wready  (m_axi_wready),
            .m_axi_wdata   (m_axi_wdata),
            .m_axi_wstrb   (m_axi_wstrb),
            .m_axi_wlast   (m_axi_wlast),
            .m_axi_wvalid  (m_axi_wvalid),
            .m_axi_bresp   (m_axi_bresp),
            .m_axi_bvalid  (m_axi_bvalid),
            .m_axi_bready  (m_axi_bready),
            .m_axi_arready (m_axi_arready),
            .m_axi_araddr  (m_axi_araddr),
            .m_axi_arvalid (m_axi_arvalid),
            .m_axi_rresp   (m_axi_rresp),
            .m_axi_rvalid  (m_axi_rvalid),
            .m_axi_rdata   (m_axi_rdata),
            .m_axi_rlast   (m_axi_rlast),
            .m_axi_rready  (m_axi_rready),
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
            .rgmii_rxc     (rgmii_rxc),
            .rgmii_rdata   (rgmii_rdata),
            .rgmii_rvalid  (rgmii_rvalid),
            .rgmii_rlast   (rgmii_rlast),
            .rgmii_ruser   (rgmii_ruser),
            .rgmii_rready  (rgmii_rready),
            .rgmii_tdata   (rgmii_tdata),
            .rgmii_tvalid  (rgmii_tvalid),
            .rgmii_tlast   (rgmii_tlast),
            .rgmii_tuser   (rgmii_tuser),
            .rgmii_tready  (rgmii_tready)
        );

    task init();
        m_axi_awready <= '1;
        m_axi_wready  <= '1;
        m_axi_bresp   <= '0;
        m_axi_bvalid  <= '1;
        m_axi_arready <= '0;
        m_axi_rresp   <= '0;
        m_axi_rvalid  <= '0;
        m_axi_rdata   <= '0;
        m_axi_rlast   <= '0;
        s_axi_awid    <= '0;
        s_axi_awaddr  <= '0;
        s_axi_awlen   <= '0;
        s_axi_awsize  <= '0;
        s_axi_awburst <= '0;
        s_axi_awlock  <= '0;
        s_axi_awcache <= '0;
        s_axi_awprot  <= '0;
        s_axi_awvalid <= '0;
        s_axi_wdata   <= '0;
        s_axi_wstrb   <= '0;
        s_axi_wlast   <= '0;
        s_axi_wvalid  <= '0;
        s_axi_bready  <= '1;
        s_axi_arid    <= '0;
        s_axi_araddr  <= '0;
        s_axi_arlen   <= '0;
        s_axi_arsize  <= '0;
        s_axi_arburst <= '0;
        s_axi_arlock  <= '0;
        s_axi_arcache <= '0;
        s_axi_arprot  <= '0;
        s_axi_arvalid <= '0;
        s_axi_rready  <= '0;
        rgmii_rdata   <= '0;
        rgmii_rvalid  <= '0;
        rgmii_rlast   <= '0;
        rgmii_ruser   <= '0;
        rgmii_tready  <= '0;
    endtask

        assign  axi_clk     = clk;
        assign  axi_rstn    = srstb;

     initial begin
        rgmii_rxc = '1;
        forever #(4) rgmii_rxc = ~rgmii_rxc;
    end
           
    initial begin
        // do something
        init();
    end

    always_ff @(posedge clk) begin 
        rgmii_tready <= rgmii_tvalid;
    end

    always_ff @(posedge clk) begin 
       // m_axi_wready <= m_axi_wvalid;
    end
/*------------------------------------------------------------------------------
--  s_axi
------------------------------------------------------------------------------*/
    //  aw
    always_ff @(posedge clk) begin
            s_axi_awvalid   <= 1;
    end
    
    // w
    logic [C_AXI_DATA_WIDTH-1 : 0]  data = '0;

     always_ff @(posedge clk) begin
        if (axi_rstn) begin
            data        <=  data + 1;
            case (data)
                32'd10 : begin s_axi_wdata <= 32'h5555_5555; s_axi_wvalid <= 1; s_axi_wlast <= 0;end 
                32'd11 : begin s_axi_wdata <= 32'h4444_4444; s_axi_wvalid <= 1; s_axi_wlast <= 0;end 
                32'd12 : begin s_axi_wdata <= 32'h3333_3333; s_axi_wvalid <= 1; s_axi_wlast <= 0;end 
                32'd13 : begin s_axi_wdata <= 32'h2222_2222; s_axi_wvalid <= 1; s_axi_wlast <= 0;end 
                32'd14 : begin s_axi_wdata <= 32'h1111_1111; s_axi_wvalid <= 1; s_axi_wlast <= 1;end 
                32'd15 : begin s_axi_wdata <= 32'h5555_5556; s_axi_wvalid <= 0; s_axi_wlast <= 0;end 
                32'd16 : begin s_axi_wdata <= 32'h5555_5556; s_axi_wvalid <= 0; s_axi_wlast <= 0;end 
                32'd117 : begin s_axi_wdata <= 32'h5555_5556; s_axi_wvalid <= 1; s_axi_wlast <= 0;end
                32'd118 : begin s_axi_wdata <= 32'h4444_4444; s_axi_wvalid <= 1; s_axi_wlast <= 0;end 
                32'd119 : begin s_axi_wdata <= 32'h3333_3333; s_axi_wvalid <= 1; s_axi_wlast <= 0;end 
                32'd120 : begin s_axi_wdata <= 32'h2222_2222; s_axi_wvalid <= 1; s_axi_wlast <= 0;end 
                32'd121 : begin s_axi_wdata <= 32'h1111_1111; s_axi_wvalid <= 1; s_axi_wlast <= 1;end
            
                default : begin s_axi_wdata <= 32'h1111_1111; s_axi_wvalid <= 0; s_axi_wlast <= 0;end
            endcase
        end
    end

/*------------------------------------------------------------------------------
--  rgmii rx
------------------------------------------------------------------------------*/
parameter   PREAMBLE_REG    =   64'h5555_5555_5555_55d5,    //  前导码
            PREAMBLE_WORD   =   5'd8,
            //------------以太网首部-----------------
            ETH_DA_MAC      =   48'h00D0_0800_0002,         //  目的MAC地址，FPGA板的MAC
            ETH_SA_MAC      =   48'h0024_7EDF_CA5E,         //  源MAC地址，上位机MAC
            ETH_TYPE        =   16'h0800,                   //  帧类型
            ARP_TYPE        =   16'h0806, 
            //-------------IP首部----------------------
            IP_VS_LEN_TOS   =   16'h4500,                   //  IP版本(4)+首部长度(20)+服务类型
            IP_FLAG_OFFSET  =   16'h4000,                   //  IP标志+帧偏移
            IP_TTL_PROTO    =   16'h8011,                   //  IP帧生存时间+协议
            IP_SUM          =   16'h0000,
            IP_DA           =   {8'd192,8'd168,8'd0,8'd110},              //  目的IP地址
            IP_SA           =   {8'd192,8'd168,8'd0,8'd119},              //  源IP地址

            //-------------UDP首部---------------------
            UDP_DP          =   16'd8080,
            UDP_SP          =   16'd8080,
            UDP_LEN         =   16'd0028,                   //  UDP长度8字节 28
            UDP_SUM         =   16'h0000,                   //  UDP校验和

            //-------------数据---------------------
            DATA_FLAG       =   32'hEEBA_EEBA,              //  固定字节，用于数据标识
            DATA_RX         =   128'h1234_5611_1134_5678_1234_5678_AABB_CCDD,
            DATA_WORD       =   5'd20,
            //-------------ARP---------------------
            ARP_DA_MAC      =   48'hFFFF_FFFF_FFFF,
            ARP_SA_MAC      =   48'h0024_7EDF_CA5E, 
 
            ARP_HEAD        =   64'h0001_0800_0604_0001,
            ARP_Z           =   144'h0,
            ARP_CRC         =   32'h59FB_0258,
            //-------------ICMP---------------------
            ICMP_DATA       =   256'h6162_6364_6566_6768_696a_6b6c_6d6e_6f70_7172_7374_7576_7761_6263_6465_6667_6869,
            ICMP_TYPECODE   =   16'h0800,
            ICMP_CKS        =   16'h4d56,
            ICMP_IDF        =   16'h0001,
            ICMP_SEQ        =   16'h0005,
            ICMP_CRC        =   32'hC034_2A1A,
            //-------------CRC---------------------
            CRC_WORD        =   5'd4,
            CRC_RX          =   32'hCFD9_3530;

    parameter UDPBIT        =   (495); 

    reg [UDPBIT:0] data_out   =   0,
                data_out_D  =   0;
    reg [511:0] arp_out     =   0,
                arp_out_D   =   0;
    reg [623:0] icmp_out    =   0,
                icmp_out_D  =   0;
    reg [15:0]  data_cnt    =   0;
    
    reg [7:0]   frame_arp_cnt   =   0,
                frame_icmp_cnt  =   0,
                frame_udp_cnt   =   0;

    reg is_arp  =   0,
        is_icmp =   0,
        is_udp  =   0;
    reg [3:0]   rgmii_tx_cnt=   0;


//-----------ETH FARME ------------------- 
always  @ (posedge rgmii_rxc) begin
    if (!axi_rstn) begin      
        data_out    <=  {ETH_DA_MAC,ETH_SA_MAC,ETH_TYPE,IP_VS_LEN_TOS,(UDP_LEN+16'd20),16'h0012,IP_FLAG_OFFSET,IP_TTL_PROTO,IP_SUM,IP_SA,IP_DA,UDP_SP,UDP_DP,UDP_LEN,UDP_SUM,DATA_FLAG,DATA_RX};
        arp_out     <=  {ARP_DA_MAC,ARP_SA_MAC,ARP_TYPE,ARP_HEAD,ARP_SA_MAC,IP_SA,48'h0,IP_DA,ARP_Z,ARP_CRC};
        icmp_out    <=  {ETH_DA_MAC,ETH_SA_MAC,ETH_TYPE,IP_VS_LEN_TOS,16'h003c,16'h71A0,16'h0000,16'h8001,16'h0000,IP_SA,IP_DA,ICMP_TYPECODE,ICMP_CKS,ICMP_IDF,ICMP_SEQ,ICMP_DATA,ICMP_CRC};
    end
    else begin
        if (frame_udp_cnt == 0 && !is_arp && !is_icmp && !is_udp) begin // GO ICMP
            is_arp  <=  1;
            is_icmp <=  0;
            is_udp  <=  0;          
        end     
        else if (frame_arp_cnt == 5) begin  // GO ICMP
            frame_arp_cnt   <=  0;
            is_arp  <=  0;
            is_icmp <=  1;
            is_udp  <=  0;          
        end
        else if (frame_icmp_cnt == 5) begin // GO UDP
            frame_icmp_cnt  <=  0;
            is_arp  <=  0;
            is_icmp <=  0;
            is_udp  <=  1;  
        end 
        else if (frame_udp_cnt == 5) begin  //  GO ARP
            frame_udp_cnt   <=  0;
            is_arp  <=  1;
            is_icmp <=  0;
            is_udp  <=  0;  
        end
        else begin
            is_arp  <=  is_arp;
            is_icmp <=  is_icmp;
            is_udp  <=  is_udp; 
        end         
//----------------------ARP------------------------ 
        if (is_arp) begin
            if (data_cnt == 200) begin
                data_cnt      <= 0;
                rgmii_rlast   <= 0;
                arp_out_D     <=  arp_out;
                frame_arp_cnt <=  frame_arp_cnt + 1;
            end
            else if (data_cnt >= 63) begin
                data_cnt      <=   data_cnt + 1;
                rgmii_rlast   <=  1;
                rgmii_rvalid  <=   !rgmii_rlast;
            end
            else begin      
                
                rgmii_rvalid  <=  1;
                
                
                if (rgmii_rvalid && rgmii_rready) begin   
                    data_cnt        <= data_cnt + 1;
                    if (data_cnt == 1) begin 
                        arp_out_D   <= arp_out_D << 16;
                        rgmii_rdata <= arp_out_D[503:496];                        
                    end
                    else begin 
                        arp_out_D   <= arp_out_D << 8;
                        rgmii_rdata <= arp_out_D[511:504];
                    end
                end         
                else if (data_cnt == 0) begin 
                    data_cnt        <= 1;
                    rgmii_rdata     <= arp_out_D[511:504];
                end
                else begin
                    data_cnt        <= data_cnt;
                    arp_out_D       <= arp_out_D;
                    rgmii_rdata     <= rgmii_rdata;
                end
            end  
        end 
//----------------------ICMP------------------------ 
        else if (is_icmp) begin
            if (data_cnt == 200) begin
                data_cnt       <= 0;
                rgmii_rlast    <= 0;
                icmp_out_D     <=  icmp_out;
                frame_icmp_cnt <=  frame_icmp_cnt + 1;
            end
            else if (data_cnt >= 77) begin
                data_cnt       <=   data_cnt + 1;
                rgmii_rlast    <=  1;
                rgmii_rvalid   <=   !rgmii_rlast;
            end
            else begin
                
                rgmii_rvalid <=  1;
                
                   
                if (rgmii_rvalid && rgmii_rready) begin   
                    data_cnt        <= data_cnt + 1;
                    if (data_cnt == 1) begin 
                        icmp_out_D  <= icmp_out_D << 16;
                        rgmii_rdata <=  icmp_out_D[615:608];
                    end                     
                    else begin 
                        icmp_out_D  <= icmp_out_D << 8;
                        rgmii_rdata <=  icmp_out_D[623:616];                     
                    end
                end
                else if (data_cnt == 0) begin 
                    data_cnt        <= 1;
                    rgmii_rdata     <= icmp_out_D[623:616];
                end             
                else begin
                    data_cnt        <= data_cnt;
                    icmp_out_D      <= icmp_out_D;
                    rgmii_rdata     <= rgmii_rdata;
                end
            end 
        end 
//----------------------UDP------------------------ 
        else if (is_udp) begin
             if (data_cnt == 200) begin
                data_cnt      <= 0;
                rgmii_rlast   <= 0;
                data_out_D    <=  data_out;               
                frame_udp_cnt <=  frame_udp_cnt + 1;                
            end
            else if (data_cnt >= (UDPBIT+1)/8-1 ) begin
                rgmii_rlast   <=  1;
                rgmii_rvalid  <=   !rgmii_rlast; 
                rgmii_rdata   <= data_out_D[UDPBIT-:8];
                data_cnt      <=   data_cnt + 1;
            end
            else begin
            
                    rgmii_rvalid <=  1;
                                 

                if (rgmii_rvalid && rgmii_rready) begin   
                    data_cnt        <= data_cnt + 1;
                    if (data_cnt == 1) begin 
                        data_out_D  <= data_out_D << 16;
                        rgmii_rdata <=  data_out_D[(UDPBIT-8)-:8];
                    end                     
                    else begin 
                        data_out_D  <= data_out_D << 8;
                        rgmii_rdata <=  data_out_D[UDPBIT-:8];                 
                    end
                end
                else if (data_cnt == 0) begin 
                    data_cnt        <= 1;
                    rgmii_rdata     <= data_out_D[UDPBIT-:8];
                end             
                else begin
                    data_cnt        <= data_cnt;
                    data_out_D      <= data_out_D;
                    rgmii_rdata     <= rgmii_rdata;
                end             
            end
        end     
    end
end




endmodule
