//////////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2023 Christopher R. Bowman
// All rights reserved
//
// Company: ChrisBowman.com
// Engineer: Christopher R. Bowman
// Contact: <my initials>@ChrisBowman.com
//
// Creation Date: 01/028/2023 15:28:11 PM
// Design Name: 
// Module Name: mm_axi_ssd
// Project Name: ssd
// Target Devices: xc7z020clg400-1
// Tool Versions: 2022.2
//
// Dependencies: 
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps

module mm_axi_ssd #
(
    // Parameters of Axi Slave Bus Interface axi_S0
    parameter integer C_S0_axi_DATA_WIDTH	= 32,
    parameter integer C_S0_axi_ADDR_WIDTH	= 4
)
(
    //(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME clk, ASSOCIATED_BUSIF none, CLK_DOMAIN my_clk" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME clk, ASSOCIATED_BUSIF none" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)

    input  wire       clk,
    output wire [4:1] ja_p,
    output wire [4:1] ja_n,
    output wire [4:1] jb_p,
    output wire [4:1] jb_n,
    output wire [3:0] led,

    // Ports of Axi Slave Bus Interface axi_S0
  //(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME axi_interface_CLK , ASSOCIATED_BUSIF axi_interface, ASSOCIATED_RESET S0_axi_aresetn, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN design_1_processing_system7_0_0_FCLK_CLK0, INSERT_VIP 0" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME axi_interface_CLK , ASSOCIATED_BUSIF axi_interface, ASSOCIATED_RESET S0_axi_aresetn, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, INSERT_VIP 0" *)
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 axi_interface_CLK CLK" *)
    input  wire                              S0_axi_aclk,
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME axi_interface_RST, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 axi_interface_RST RST" *)
    input  wire                              S0_axi_aresetn,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_interface AWADDR" *)
    input  wire     [C_S0_axi_ADDR_WIDTH-1:0]S0_axi_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_interface AWPROT" *)
    input  wire                         [2:0]S0_axi_awprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_interface AWVALID" *)
    input  wire                              S0_axi_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_interface AWREADY" *)
    output wire                              S0_axi_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_interface WDATA" *)
    input  wire     [C_S0_axi_DATA_WIDTH-1:0]S0_axi_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_interface WSTRB" *)
    input  wire [(C_S0_axi_DATA_WIDTH/8)-1:0]S0_axi_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_interface WVALID" *)
    input  wire                              S0_axi_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_interface WREADY" *)
    output wire                              S0_axi_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_interface BRESP" *)
    output wire                         [1:0]S0_axi_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_interface BVALID" *)
    output wire                              S0_axi_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_interface BREADY" *)
    input  wire                              S0_axi_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_interface ARADDR" *)
    input  wire     [C_S0_axi_ADDR_WIDTH-1:0]S0_axi_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_interface ARPROT" *)
    input  wire                         [2:0]S0_axi_arprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_interface ARVALID" *)
    input  wire                              S0_axi_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_interface ARREADY" *)
    output wire                              S0_axi_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_interface RDATA" *)
    output wire     [C_S0_axi_DATA_WIDTH-1:0]S0_axi_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_interface RRESP" *)
    output wire                         [1:0]S0_axi_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_interface RVALID" *)
    output wire                              S0_axi_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 axi_interface RREADY" *)
    input  wire                              S0_axi_rready
);

// Instantiation of Axi Bus Interface axi_S0
mm_axi_ssd_core # ( 
    .C_S_AXI_DATA_WIDTH(C_S0_axi_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH(C_S0_axi_ADDR_WIDTH)
) mm_ssd_axi_core_inst (
    .clk(clk),
    .ja_p(ja_p),
    .ja_n(ja_n),
    .jb_p(jb_p),
    .jb_n(jb_n),
    .led(led),
    .S_AXI_ACLK(S0_axi_aclk),
    .S_AXI_ARESETN(S0_axi_aresetn),
    .S_AXI_AWADDR(S0_axi_awaddr),
    .S_AXI_AWPROT(S0_axi_awprot),
    .S_AXI_AWVALID(S0_axi_awvalid),
    .S_AXI_AWREADY(S0_axi_awready),
    .S_AXI_WDATA(S0_axi_wdata),
    .S_AXI_WSTRB(S0_axi_wstrb),
    .S_AXI_WVALID(S0_axi_wvalid),
    .S_AXI_WREADY(S0_axi_wready),
    .S_AXI_BRESP(S0_axi_bresp),
    .S_AXI_BVALID(S0_axi_bvalid),
    .S_AXI_BREADY(S0_axi_bready),
    .S_AXI_ARADDR(S0_axi_araddr),
    .S_AXI_ARPROT(S0_axi_arprot),
    .S_AXI_ARVALID(S0_axi_arvalid),
    .S_AXI_ARREADY(S0_axi_arready),
    .S_AXI_RDATA(S0_axi_rdata),
    .S_AXI_RRESP(S0_axi_rresp),
    .S_AXI_RVALID(S0_axi_rvalid),
    .S_AXI_RREADY(S0_axi_rready)
);

endmodule
