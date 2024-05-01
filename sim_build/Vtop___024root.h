// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtop.h for the primary calling header

#ifndef VERILATED_VTOP___024ROOT_H_
#define VERILATED_VTOP___024ROOT_H_  // guard

#include "verilated.h"

class Vtop__Syms;

class Vtop___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    // Anonymous structures to workaround compiler member-count bugs
    struct {
        VL_IN8(BUS_CLK,0,0);
        VL_IN8(BUS_RST,0,0);
        VL_IN8(BUS_DATA_IN,7,0);
        VL_OUT8(BUS_DATA_OUT,7,0);
        VL_IN8(BUS_RD,0,0);
        VL_IN8(BUS_WR,0,0);
        CData/*0:0*/ tb__DOT__BUS_CLK;
        CData/*0:0*/ tb__DOT__BUS_RST;
        CData/*7:0*/ tb__DOT__BUS_DATA_IN;
        CData/*7:0*/ tb__DOT__BUS_DATA_OUT;
        CData/*0:0*/ tb__DOT__BUS_RD;
        CData/*0:0*/ tb__DOT__BUS_WR;
        CData/*7:0*/ tb__DOT__BUS_DATA;
        CData/*0:0*/ tb__DOT__i_gpio__DOT__BUS_CLK;
        CData/*0:0*/ tb__DOT__i_gpio__DOT__BUS_RST;
        CData/*7:0*/ tb__DOT__i_gpio__DOT__BUS_DATA;
        CData/*0:0*/ tb__DOT__i_gpio__DOT__BUS_RD;
        CData/*0:0*/ tb__DOT__i_gpio__DOT__BUS_WR;
        CData/*0:0*/ tb__DOT__i_gpio__DOT__IP_RD;
        CData/*0:0*/ tb__DOT__i_gpio__DOT__IP_WR;
        CData/*7:0*/ tb__DOT__i_gpio__DOT__IP_DATA_IN;
        CData/*7:0*/ tb__DOT__i_gpio__DOT__IP_DATA_OUT;
        CData/*0:0*/ tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BUS_RD;
        CData/*0:0*/ tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BUS_WR;
        CData/*7:0*/ tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BUS_DATA;
        CData/*0:0*/ tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_RD;
        CData/*0:0*/ tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_WR;
        CData/*7:0*/ tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_DATA_IN;
        CData/*7:0*/ tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_DATA_OUT;
        CData/*0:0*/ tb__DOT__i_gpio__DOT__bus_to_ip__DOT__CS;
        CData/*7:0*/ tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BUS_DATA__out__en0;
        CData/*0:0*/ tb__DOT__i_gpio__DOT__core__DOT__BUS_CLK;
        CData/*0:0*/ tb__DOT__i_gpio__DOT__core__DOT__BUS_RST;
        CData/*7:0*/ tb__DOT__i_gpio__DOT__core__DOT__BUS_DATA_IN;
        CData/*7:0*/ tb__DOT__i_gpio__DOT__core__DOT__BUS_DATA_OUT;
        CData/*0:0*/ tb__DOT__i_gpio__DOT__core__DOT__BUS_RD;
        CData/*0:0*/ tb__DOT__i_gpio__DOT__core__DOT__BUS_WR;
        CData/*0:0*/ tb__DOT__i_gpio__DOT__core__DOT__SOFT_RST;
        CData/*0:0*/ tb__DOT__i_gpio__DOT__core__DOT__RST;
        CData/*7:0*/ tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h6bb4edf4__0;
        CData/*7:0*/ tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h535782b1__0;
        CData/*0:0*/ tb__DOT__i_gpio2__DOT__BUS_CLK;
        CData/*0:0*/ tb__DOT__i_gpio2__DOT__BUS_RST;
        CData/*7:0*/ tb__DOT__i_gpio2__DOT__BUS_DATA;
        CData/*0:0*/ tb__DOT__i_gpio2__DOT__BUS_RD;
        CData/*0:0*/ tb__DOT__i_gpio2__DOT__BUS_WR;
        CData/*0:0*/ tb__DOT__i_gpio2__DOT__IP_RD;
        CData/*0:0*/ tb__DOT__i_gpio2__DOT__IP_WR;
        CData/*7:0*/ tb__DOT__i_gpio2__DOT__IP_DATA_IN;
        CData/*7:0*/ tb__DOT__i_gpio2__DOT__IP_DATA_OUT;
        CData/*0:0*/ tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BUS_RD;
        CData/*0:0*/ tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BUS_WR;
        CData/*7:0*/ tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BUS_DATA;
        CData/*0:0*/ tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_RD;
        CData/*0:0*/ tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_WR;
        CData/*7:0*/ tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_DATA_IN;
        CData/*7:0*/ tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_DATA_OUT;
        CData/*0:0*/ tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__CS;
        CData/*7:0*/ tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BUS_DATA__out__en0;
        CData/*0:0*/ tb__DOT__i_gpio2__DOT__core__DOT__BUS_CLK;
        CData/*0:0*/ tb__DOT__i_gpio2__DOT__core__DOT__BUS_RST;
        CData/*7:0*/ tb__DOT__i_gpio2__DOT__core__DOT__BUS_DATA_IN;
        CData/*7:0*/ tb__DOT__i_gpio2__DOT__core__DOT__BUS_DATA_OUT;
        CData/*0:0*/ tb__DOT__i_gpio2__DOT__core__DOT__BUS_RD;
    };
    struct {
        CData/*0:0*/ tb__DOT__i_gpio2__DOT__core__DOT__BUS_WR;
        CData/*0:0*/ tb__DOT__i_gpio2__DOT__core__DOT__SOFT_RST;
        CData/*0:0*/ tb__DOT__i_gpio2__DOT__core__DOT__RST;
        CData/*0:0*/ __Vclklast__TOP__BUS_CLK;
        VL_IN16(BUS_ADD,15,0);
        SData/*15:0*/ tb__DOT__BUS_ADD;
        SData/*15:0*/ tb__DOT__IO_2;
        SData/*15:0*/ tb__DOT__i_gpio__DOT__BUS_ADD;
        SData/*15:0*/ tb__DOT__i_gpio__DOT__IP_ADD;
        SData/*15:0*/ tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BUS_ADD;
        SData/*15:0*/ tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_ADD;
        SData/*15:0*/ tb__DOT__i_gpio__DOT__core__DOT__BUS_ADD;
        SData/*15:0*/ tb__DOT__i_gpio2__DOT__BUS_ADD;
        SData/*15:0*/ tb__DOT__i_gpio2__DOT__IO;
        SData/*15:0*/ tb__DOT__i_gpio2__DOT__IP_ADD;
        SData/*15:0*/ tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BUS_ADD;
        SData/*15:0*/ tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_ADD;
        SData/*15:0*/ tb__DOT__i_gpio2__DOT__core__DOT__BUS_ADD;
        SData/*15:0*/ tb__DOT__i_gpio2__DOT__core__DOT__IO;
        IData/*23:0*/ tb__DOT__IO;
        IData/*23:0*/ tb__DOT__IO__out7;
        IData/*23:0*/ tb__DOT__IO__out8;
        IData/*23:0*/ tb__DOT__i_gpio__DOT__IO;
        IData/*23:0*/ tb__DOT__i_gpio__DOT__core__DOT__IO;
        IData/*31:0*/ tb__DOT__i_gpio__DOT__core__DOT__bi;
        IData/*23:0*/ tb__DOT__i_gpio__DOT__core__DOT__IO__out__out0;
        IData/*23:0*/ tb__DOT__i_gpio__DOT__core__DOT__IO__out__out1;
        IData/*23:0*/ tb__DOT__i_gpio__DOT__core__DOT__IO__out__out2;
        IData/*23:0*/ tb__DOT__i_gpio__DOT__core__DOT__IO__out__out3;
        IData/*23:0*/ tb__DOT__i_gpio__DOT__core__DOT__IO__out__out4;
        IData/*23:0*/ tb__DOT__i_gpio__DOT__core__DOT__IO__out__out5;
        IData/*23:0*/ tb__DOT__i_gpio__DOT__core__DOT__IO__out__out6;
        IData/*23:0*/ tb__DOT__i_gpio__DOT__core__DOT__IO__out__out7;
        IData/*23:0*/ tb__DOT__i_gpio__DOT__core__DOT__IO__out__out8;
        IData/*23:0*/ tb__DOT__i_gpio__DOT__core__DOT__IO__out__out9;
        IData/*23:0*/ tb__DOT__i_gpio__DOT__core__DOT__IO__out__out10;
        IData/*23:0*/ tb__DOT__i_gpio__DOT__core__DOT__IO__out__out11;
        IData/*23:0*/ tb__DOT__i_gpio__DOT__core__DOT__IO__out__out12;
        IData/*23:0*/ tb__DOT__i_gpio__DOT__core__DOT__IO__out__out13;
        IData/*23:0*/ tb__DOT__i_gpio__DOT__core__DOT__IO__out__out14;
        IData/*23:0*/ tb__DOT__i_gpio__DOT__core__DOT__IO__out__out15;
        IData/*31:0*/ tb__DOT__i_gpio2__DOT__core__DOT__bi;
        IData/*23:0*/ __Vchglast__TOP__tb__DOT__IO;
        VlUnpacked<CData/*7:0*/, 3> tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA;
        VlUnpacked<CData/*7:0*/, 3> tb__DOT__i_gpio__DOT__core__DOT__OUTPUT_DATA;
        VlUnpacked<CData/*7:0*/, 3> tb__DOT__i_gpio__DOT__core__DOT__DIRECTION_DATA;
        VlUnpacked<CData/*7:0*/, 2> tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA;
        VlUnpacked<CData/*7:0*/, 2> tb__DOT__i_gpio2__DOT__core__DOT__OUTPUT_DATA;
        VlUnpacked<CData/*7:0*/, 2> tb__DOT__i_gpio2__DOT__core__DOT__DIRECTION_DATA;
    };

    // INTERNAL VARIABLES
    Vtop__Syms* const vlSymsp;

    // PARAMETERS
    static constexpr SData/*15:0*/ tb__DOT__GPIO_BASEADDR = 0U;
    static constexpr SData/*15:0*/ tb__DOT__GPIO_HIGHADDR = 0x000fU;
    static constexpr SData/*15:0*/ tb__DOT__GPIO2_BASEADDR = 0x0010U;
    static constexpr SData/*15:0*/ tb__DOT__GPIO2_HIGHADDR = 0x001fU;
    static constexpr SData/*15:0*/ tb__DOT__i_gpio__DOT__BASEADDR = 0U;
    static constexpr SData/*15:0*/ tb__DOT__i_gpio__DOT__HIGHADDR = 0x000fU;
    static constexpr SData/*15:0*/ tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BASEADDR = 0U;
    static constexpr SData/*15:0*/ tb__DOT__i_gpio__DOT__bus_to_ip__DOT__HIGHADDR = 0x000fU;
    static constexpr SData/*15:0*/ tb__DOT__i_gpio2__DOT__BASEADDR = 0x0010U;
    static constexpr SData/*15:0*/ tb__DOT__i_gpio2__DOT__HIGHADDR = 0x001fU;
    static constexpr SData/*15:0*/ tb__DOT__i_gpio2__DOT__IO_DIRECTION = 0U;
    static constexpr SData/*15:0*/ tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BASEADDR = 0x0010U;
    static constexpr SData/*15:0*/ tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__HIGHADDR = 0x001fU;
    static constexpr SData/*15:0*/ tb__DOT__i_gpio2__DOT__core__DOT__IO_DIRECTION = 0U;
    static constexpr IData/*31:0*/ tb__DOT__i_gpio__DOT__ABUSWIDTH = 0x00000010U;
    static constexpr IData/*31:0*/ tb__DOT__i_gpio__DOT__IO_WIDTH = 0x00000018U;
    static constexpr IData/*23:0*/ tb__DOT__i_gpio__DOT__IO_DIRECTION = 0x000000ffU;
    static constexpr IData/*23:0*/ tb__DOT__i_gpio__DOT__IO_TRI = 0x00ff0000U;
    static constexpr IData/*31:0*/ tb__DOT__i_gpio__DOT__bus_to_ip__DOT__ABUSWIDTH = 0x00000010U;
    static constexpr IData/*31:0*/ tb__DOT__i_gpio__DOT__bus_to_ip__DOT__DBUSWIDTH = 8U;
    static constexpr IData/*31:0*/ tb__DOT__i_gpio__DOT__core__DOT__ABUSWIDTH = 0x00000010U;
    static constexpr IData/*31:0*/ tb__DOT__i_gpio__DOT__core__DOT__IO_WIDTH = 0x00000018U;
    static constexpr IData/*23:0*/ tb__DOT__i_gpio__DOT__core__DOT__IO_DIRECTION = 0x000000ffU;
    static constexpr IData/*23:0*/ tb__DOT__i_gpio__DOT__core__DOT__IO_TRI = 0x00ff0000U;
    static constexpr IData/*31:0*/ tb__DOT__i_gpio__DOT__core__DOT__VERSION = 0U;
    static constexpr IData/*31:0*/ tb__DOT__i_gpio__DOT__core__DOT__IO_BYTES = 3U;
    static constexpr IData/*31:0*/ tb__DOT__i_gpio2__DOT__ABUSWIDTH = 0x00000010U;
    static constexpr IData/*31:0*/ tb__DOT__i_gpio2__DOT__IO_WIDTH = 0x00000010U;
    static constexpr IData/*31:0*/ tb__DOT__i_gpio2__DOT__IO_TRI = 0U;
    static constexpr IData/*31:0*/ tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__ABUSWIDTH = 0x00000010U;
    static constexpr IData/*31:0*/ tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__DBUSWIDTH = 8U;
    static constexpr IData/*31:0*/ tb__DOT__i_gpio2__DOT__core__DOT__ABUSWIDTH = 0x00000010U;
    static constexpr IData/*31:0*/ tb__DOT__i_gpio2__DOT__core__DOT__IO_WIDTH = 0x00000010U;
    static constexpr IData/*31:0*/ tb__DOT__i_gpio2__DOT__core__DOT__IO_TRI = 0U;
    static constexpr IData/*31:0*/ tb__DOT__i_gpio2__DOT__core__DOT__VERSION = 0U;
    static constexpr IData/*31:0*/ tb__DOT__i_gpio2__DOT__core__DOT__IO_BYTES = 2U;

    // CONSTRUCTORS
    Vtop___024root(Vtop__Syms* symsp, const char* name);
    ~Vtop___024root();
    VL_UNCOPYABLE(Vtop___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);


#endif  // guard
