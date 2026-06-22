// Include Guard
`ifndef TIMER_DEFINES_V
`define TIMER_DEFINES_V

// APB Bus Configuration
`define APB_ADDR_WIDTH 12
`define APB_DATA_WIDTH 32

// Registers's Address Definition
`define ADDR_TCR       12'h000        // Timer Control Register
`define ADDR_TDR0      12'h004        // Timer Data Register 0 (Lower 32-bit of Counter)
`define ADDR_TDR1      12'h008        // Timer Data Register 1 (Upper 32-bit of Counter)
`define ADDR_TCMP0     12'h00C        // Timer Compare Register 0 (Lower 32-bit)
`define ADDR_TCMP1     12'h010        // Timer Compare Register 1 (Upper 32-bit)
`define ADDR_TIER      12'h014        // Timer Interrupt Enable Register
`define ADDR_TISR      12'h018        // Timer Interrupt Status Register
`define ADDR_THCSR     12'h01C        // Timer Halt Control Status Register

// Reset/Default Value Definition
`define RST_VAL_TCR    32'h0000_0100
`define RST_VAL_TDR0   32'h0000_0000
`define RST_VAL_TDR1   32'h0000_0000
`define RST_VAL_TCMP0  32'hFFFF_FFFF
`define RST_VAL_TCMP1  32'hFFFF_FFFF
`define RST_VAL_TIER   32'h0000_0000
`define RST_VAL_TISR   32'h0000_0000
`define RST_VAL_THCSR  32'h0000_0000

// Highest div_val definition
`define MAX_VALID_DIV_VAL 4'd8

`endif // TIMER_DEFINES_V