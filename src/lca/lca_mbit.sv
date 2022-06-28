`timescale 1ns / 1ps
/* -----------------------------------------------------------------------------
 Copyright (c) 2014-2021 All rights reserved
 -----------------------------------------------------------------------------
 Author     : lwings    https://github.com/Lvwings
 File       : lca_mbit.sv
 Create     : 2022-06-22 16:41:02
 Revise     : 2022-06-22 16:41:02
 Language   : Verilog 2001
 -----------------------------------------------------------------------------*/

 module lca_mbit #(
        parameter DATA_WIDTH = 32  
    )
    (
        input   [DATA_WIDTH-1 : 0]  a,
        input   [DATA_WIDTH-1 : 0]  b,
        input                       cin,
        output  [DATA_WIDTH-1 : 0]  sum,
        output                      cout   
 );
 
/*------------------------------------------------------------------------------
--  For large data width adders, to avoid large fan-in and fan-out of the circuit,
    a compromise solution is to cascade multiple 4-bit LCA.
------------------------------------------------------------------------------*/
    logic [DATA_WIDTH>>2 : 0] c;    //  A 4-bit LCA with one cout -> c = DATA_WIDTH/4 + 1 
    assign  c[0]    =   cin;
    assign  cout    =   c[DATA_WIDTH>>2];

    genvar  i;
    generate
        for (i = 0; i < DATA_WIDTH>>2; i = i+1) begin
            lca_4bit inst_lca_4bit (
                .a      (a[4*i +: 4]), 
                .b      (b[4*i +: 4]), 
                .cin    (c[i]), 
                .sum    (sum[4*i +: 4]), 
                .cout   (c[i+1])
            );
        end
    endgenerate

 endmodule : lca_mbit