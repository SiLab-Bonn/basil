// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtop.h for the primary calling header

#include "verilated.h"
#include "verilated_dpi.h"

#include "Vtop___024root.h"

VL_ATTR_COLD void Vtop___024root___settle__TOP__0(Vtop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___settle__TOP__0\n"); );
    // Init
    IData/*23:0*/ tb__DOT__i_gpio__DOT__IO__out__out2;
    CData/*0:0*/ tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0;
    // Body
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = 1U;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = 2U;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = 3U;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = 4U;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = 5U;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = 6U;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = 7U;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = 8U;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = 9U;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = 0xaU;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = 0xbU;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = 0xcU;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = 0xdU;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = 0xeU;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = 0xfU;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = 0x10U;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = 0x11U;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = 0x12U;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = 0x13U;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = 0x14U;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = 0x15U;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = 0x16U;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = 0x17U;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = 0x18U;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__bi = 1U;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__bi = 2U;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__bi = 3U;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__bi = 4U;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__bi = 5U;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__bi = 6U;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__bi = 7U;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__bi = 8U;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__bi = 9U;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__bi = 0xaU;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__bi = 0xbU;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__bi = 0xcU;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__bi = 0xdU;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__bi = 0xeU;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__bi = 0xfU;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__bi = 0x10U;
    vlSelf->tb__DOT__IO__out7 = ((0xff00ffU & vlSelf->tb__DOT__IO__out7) 
                                 | (0xff00U & (vlSelf->tb__DOT__IO 
                                               << 8U)));
    vlSelf->tb__DOT__IO__out8 = ((0xfffffU & vlSelf->tb__DOT__IO__out8) 
                                 | (0xf00000U & (vlSelf->tb__DOT__IO 
                                                 << 4U)));
    vlSelf->tb__DOT__i_gpio__DOT__IO = vlSelf->tb__DOT__IO;
    vlSelf->tb__DOT__IO_2 = 0xa5cdU;
    vlSelf->tb__DOT__BUS_DATA_IN = vlSelf->BUS_DATA_IN;
    vlSelf->tb__DOT__BUS_CLK = vlSelf->BUS_CLK;
    vlSelf->tb__DOT__BUS_RST = vlSelf->BUS_RST;
    vlSelf->tb__DOT__BUS_ADD = vlSelf->BUS_ADD;
    vlSelf->tb__DOT__BUS_RD = vlSelf->BUS_RD;
    vlSelf->tb__DOT__BUS_WR = vlSelf->BUS_WR;
    vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__CS 
        = (0xfU >= (IData)(vlSelf->BUS_ADD));
    vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__CS 
        = ((0x10U <= (IData)(vlSelf->BUS_ADD)) & (0x1fU 
                                                  >= (IData)(vlSelf->BUS_ADD)));
    tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0 
        = (1U & vlSelf->tb__DOT__IO);
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[0U] 
        = ((0xfeU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA
            [0U]) | (IData)(tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0));
    tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0 
        = (1U & (vlSelf->tb__DOT__IO >> 1U));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[0U] 
        = ((0xfdU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA
            [0U]) | ((IData)(tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0) 
                     << 1U));
    tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0 
        = (1U & (vlSelf->tb__DOT__IO >> 2U));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[0U] 
        = ((0xfbU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA
            [0U]) | ((IData)(tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0) 
                     << 2U));
    tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0 
        = (1U & (vlSelf->tb__DOT__IO >> 3U));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[0U] 
        = ((0xf7U & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA
            [0U]) | ((IData)(tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0) 
                     << 3U));
    tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0 
        = (1U & (vlSelf->tb__DOT__IO >> 4U));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[0U] 
        = ((0xefU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA
            [0U]) | ((IData)(tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0) 
                     << 4U));
    tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0 
        = (1U & (vlSelf->tb__DOT__IO >> 5U));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[0U] 
        = ((0xdfU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA
            [0U]) | ((IData)(tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0) 
                     << 5U));
    tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0 
        = (1U & (vlSelf->tb__DOT__IO >> 6U));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[0U] 
        = ((0xbfU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA
            [0U]) | ((IData)(tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0) 
                     << 6U));
    tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0 
        = (1U & (vlSelf->tb__DOT__IO >> 7U));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[0U] 
        = ((0x7fU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA
            [0U]) | ((IData)(tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0) 
                     << 7U));
    tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0 
        = (1U & (vlSelf->tb__DOT__IO >> 8U));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[1U] 
        = ((0xfeU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA
            [1U]) | (IData)(tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0));
    tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0 
        = (1U & (vlSelf->tb__DOT__IO >> 9U));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[1U] 
        = ((0xfdU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA
            [1U]) | ((IData)(tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0) 
                     << 1U));
    tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0 
        = (1U & (vlSelf->tb__DOT__IO >> 0xaU));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[1U] 
        = ((0xfbU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA
            [1U]) | ((IData)(tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0) 
                     << 2U));
    tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0 
        = (1U & (vlSelf->tb__DOT__IO >> 0xbU));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[1U] 
        = ((0xf7U & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA
            [1U]) | ((IData)(tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0) 
                     << 3U));
    tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0 
        = (1U & (vlSelf->tb__DOT__IO >> 0xcU));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[1U] 
        = ((0xefU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA
            [1U]) | ((IData)(tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0) 
                     << 4U));
    tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0 
        = (1U & (vlSelf->tb__DOT__IO >> 0xdU));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[1U] 
        = ((0xdfU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA
            [1U]) | ((IData)(tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0) 
                     << 5U));
    tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0 
        = (1U & (vlSelf->tb__DOT__IO >> 0xeU));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[1U] 
        = ((0xbfU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA
            [1U]) | ((IData)(tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0) 
                     << 6U));
    tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0 
        = (1U & (vlSelf->tb__DOT__IO >> 0xfU));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[1U] 
        = ((0x7fU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA
            [1U]) | ((IData)(tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0) 
                     << 7U));
    tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0 
        = (1U & (vlSelf->tb__DOT__IO >> 0x10U));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[2U] 
        = ((0xfeU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA
            [2U]) | (IData)(tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0));
    tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0 
        = (1U & (vlSelf->tb__DOT__IO >> 0x11U));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[2U] 
        = ((0xfdU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA
            [2U]) | ((IData)(tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0) 
                     << 1U));
    tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0 
        = (1U & (vlSelf->tb__DOT__IO >> 0x12U));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[2U] 
        = ((0xfbU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA
            [2U]) | ((IData)(tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0) 
                     << 2U));
    tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0 
        = (1U & (vlSelf->tb__DOT__IO >> 0x13U));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[2U] 
        = ((0xf7U & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA
            [2U]) | ((IData)(tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0) 
                     << 3U));
    tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0 
        = (1U & (vlSelf->tb__DOT__IO >> 0x14U));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[2U] 
        = ((0xefU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA
            [2U]) | ((IData)(tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0) 
                     << 4U));
    tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0 
        = (1U & (vlSelf->tb__DOT__IO >> 0x15U));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[2U] 
        = ((0xdfU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA
            [2U]) | ((IData)(tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0) 
                     << 5U));
    tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0 
        = (1U & (vlSelf->tb__DOT__IO >> 0x16U));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[2U] 
        = ((0xbfU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA
            [2U]) | ((IData)(tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0) 
                     << 6U));
    tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0 
        = (1U & (vlSelf->tb__DOT__IO >> 0x17U));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[2U] 
        = ((0x7fU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA
            [2U]) | ((IData)(tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h0a81f968__0) 
                     << 7U));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out0 
        = ((0xfffffeU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out0) 
           | (1U & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__OUTPUT_DATA
              [0U]));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out1 
        = ((0xfffffdU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out1) 
           | (2U & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__OUTPUT_DATA
              [0U]));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out2 
        = ((0xfffffbU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out2) 
           | (4U & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__OUTPUT_DATA
              [0U]));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out3 
        = ((0xfffff7U & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out3) 
           | (8U & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__OUTPUT_DATA
              [0U]));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out4 
        = ((0xffffefU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out4) 
           | (0x10U & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__OUTPUT_DATA
              [0U]));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out5 
        = ((0xffffdfU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out5) 
           | (0x20U & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__OUTPUT_DATA
              [0U]));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out6 
        = ((0xffffbfU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out6) 
           | (0x40U & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__OUTPUT_DATA
              [0U]));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out7 
        = ((0xffff7fU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out7) 
           | (0x80U & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__OUTPUT_DATA
              [0U]));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out8 
        = ((0xfeffffU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out8) 
           | (0x10000U & ((vlSelf->tb__DOT__i_gpio__DOT__core__DOT__DIRECTION_DATA
                           [2U] & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__OUTPUT_DATA
                           [2U]) << 0x10U)));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out9 
        = ((0xfdffffU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out9) 
           | (0x20000U & ((vlSelf->tb__DOT__i_gpio__DOT__core__DOT__DIRECTION_DATA
                           [2U] & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__OUTPUT_DATA
                           [2U]) << 0x10U)));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out10 
        = ((0xfbffffU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out10) 
           | (0x40000U & ((vlSelf->tb__DOT__i_gpio__DOT__core__DOT__DIRECTION_DATA
                           [2U] & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__OUTPUT_DATA
                           [2U]) << 0x10U)));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out11 
        = ((0xf7ffffU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out11) 
           | (0x80000U & ((vlSelf->tb__DOT__i_gpio__DOT__core__DOT__DIRECTION_DATA
                           [2U] & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__OUTPUT_DATA
                           [2U]) << 0x10U)));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out12 
        = ((0xefffffU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out12) 
           | (0x100000U & ((vlSelf->tb__DOT__i_gpio__DOT__core__DOT__DIRECTION_DATA
                            [2U] & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__OUTPUT_DATA
                            [2U]) << 0x10U)));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out13 
        = ((0xdfffffU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out13) 
           | (0x200000U & ((vlSelf->tb__DOT__i_gpio__DOT__core__DOT__DIRECTION_DATA
                            [2U] & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__OUTPUT_DATA
                            [2U]) << 0x10U)));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out14 
        = ((0xbfffffU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out14) 
           | (0x400000U & ((vlSelf->tb__DOT__i_gpio__DOT__core__DOT__DIRECTION_DATA
                            [2U] & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__OUTPUT_DATA
                            [2U]) << 0x10U)));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out15 
        = ((0x7fffffU & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out15) 
           | (0x800000U & ((vlSelf->tb__DOT__i_gpio__DOT__core__DOT__DIRECTION_DATA
                            [2U] & vlSelf->tb__DOT__i_gpio__DOT__core__DOT__OUTPUT_DATA
                            [2U]) << 0x10U)));
    vlSelf->tb__DOT__i_gpio__DOT__IP_DATA_OUT = vlSelf->tb__DOT__i_gpio__DOT__core__DOT__BUS_DATA_OUT;
    vlSelf->tb__DOT__i_gpio2__DOT__IP_DATA_OUT = vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__BUS_DATA_OUT;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO = vlSelf->tb__DOT__i_gpio__DOT__IO;
    vlSelf->tb__DOT__i_gpio2__DOT__IO = vlSelf->tb__DOT__IO_2;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA[0U] 
        = ((0xfeU & vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA
            [0U]) | (1U & (IData)(vlSelf->tb__DOT__IO_2)));
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA[0U] 
        = ((0xfdU & vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA
            [0U]) | (2U & (IData)(vlSelf->tb__DOT__IO_2)));
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA[0U] 
        = ((0xfbU & vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA
            [0U]) | (4U & (IData)(vlSelf->tb__DOT__IO_2)));
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA[0U] 
        = ((0xf7U & vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA
            [0U]) | (8U & (IData)(vlSelf->tb__DOT__IO_2)));
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA[0U] 
        = ((0xefU & vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA
            [0U]) | (0x10U & (IData)(vlSelf->tb__DOT__IO_2)));
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA[0U] 
        = ((0xdfU & vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA
            [0U]) | (0x20U & (IData)(vlSelf->tb__DOT__IO_2)));
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA[0U] 
        = ((0xbfU & vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA
            [0U]) | (0x40U & (IData)(vlSelf->tb__DOT__IO_2)));
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA[0U] 
        = ((0x7fU & vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA
            [0U]) | (0x80U & (IData)(vlSelf->tb__DOT__IO_2)));
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA[1U] 
        = ((0xfeU & vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA
            [1U]) | (1U & ((IData)(vlSelf->tb__DOT__IO_2) 
                           >> 8U)));
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA[1U] 
        = ((0xfdU & vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA
            [1U]) | (2U & ((IData)(vlSelf->tb__DOT__IO_2) 
                           >> 8U)));
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA[1U] 
        = ((0xfbU & vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA
            [1U]) | (4U & ((IData)(vlSelf->tb__DOT__IO_2) 
                           >> 8U)));
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA[1U] 
        = ((0xf7U & vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA
            [1U]) | (8U & ((IData)(vlSelf->tb__DOT__IO_2) 
                           >> 8U)));
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA[1U] 
        = ((0xefU & vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA
            [1U]) | (0x10U & ((IData)(vlSelf->tb__DOT__IO_2) 
                              >> 8U)));
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA[1U] 
        = ((0xdfU & vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA
            [1U]) | (0x20U & ((IData)(vlSelf->tb__DOT__IO_2) 
                              >> 8U)));
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA[1U] 
        = ((0xbfU & vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA
            [1U]) | (0x40U & ((IData)(vlSelf->tb__DOT__IO_2) 
                              >> 8U)));
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA[1U] 
        = ((0x7fU & vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA
            [1U]) | (0x80U & ((IData)(vlSelf->tb__DOT__IO_2) 
                              >> 8U)));
    vlSelf->tb__DOT__i_gpio__DOT__BUS_CLK = vlSelf->tb__DOT__BUS_CLK;
    vlSelf->tb__DOT__i_gpio2__DOT__BUS_CLK = vlSelf->tb__DOT__BUS_CLK;
    vlSelf->tb__DOT__i_gpio__DOT__BUS_RST = vlSelf->tb__DOT__BUS_RST;
    vlSelf->tb__DOT__i_gpio2__DOT__BUS_RST = vlSelf->tb__DOT__BUS_RST;
    vlSelf->tb__DOT__i_gpio__DOT__BUS_ADD = vlSelf->tb__DOT__BUS_ADD;
    vlSelf->tb__DOT__i_gpio2__DOT__BUS_ADD = vlSelf->tb__DOT__BUS_ADD;
    vlSelf->tb__DOT__i_gpio__DOT__BUS_RD = vlSelf->tb__DOT__BUS_RD;
    vlSelf->tb__DOT__i_gpio2__DOT__BUS_RD = vlSelf->tb__DOT__BUS_RD;
    vlSelf->tb__DOT__i_gpio__DOT__BUS_WR = vlSelf->tb__DOT__BUS_WR;
    vlSelf->tb__DOT__i_gpio2__DOT__BUS_WR = vlSelf->tb__DOT__BUS_WR;
    if (vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__CS) {
        vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_RD 
            = vlSelf->BUS_RD;
        vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_ADD 
            = vlSelf->BUS_ADD;
        vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_WR 
            = vlSelf->BUS_WR;
    } else {
        vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_RD = 0U;
        vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_ADD = 0U;
        vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_WR = 0U;
    }
    vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BUS_DATA__out__en0 
        = (((IData)(vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__CS) 
            & (IData)(vlSelf->BUS_WR)) ? 0U : ((IData)(vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__CS)
                                                ? 0xffU
                                                : 0U));
    if (vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__CS) {
        vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_RD 
            = vlSelf->BUS_RD;
        vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_ADD 
            = (0xffffU & ((IData)(vlSelf->BUS_ADD) 
                          - (IData)(0x10U)));
        vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_WR 
            = vlSelf->BUS_WR;
    } else {
        vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_RD = 0U;
        vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_ADD = 0U;
        vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_WR = 0U;
    }
    vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BUS_DATA__out__en0 
        = (((IData)(vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__CS) 
            & (IData)(vlSelf->BUS_WR)) ? 0U : ((IData)(vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__CS)
                                                ? 0xffU
                                                : 0U));
    tb__DOT__i_gpio__DOT__IO__out__out2 = (((((((((
                                                   ((((((vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out0 
                                                         | vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out1) 
                                                        | vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out2) 
                                                       | vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out3) 
                                                      | vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out4) 
                                                     | vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out5) 
                                                    | vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out6) 
                                                   | vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out7) 
                                                  | (0x10000U 
                                                     & (vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out8 
                                                        & (vlSelf->tb__DOT__i_gpio__DOT__core__DOT__DIRECTION_DATA
                                                           [2U] 
                                                           << 0x10U)))) 
                                                 | (0x20000U 
                                                    & (vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out9 
                                                       & (vlSelf->tb__DOT__i_gpio__DOT__core__DOT__DIRECTION_DATA
                                                          [2U] 
                                                          << 0x10U)))) 
                                                | (0x40000U 
                                                   & (vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out10 
                                                      & (vlSelf->tb__DOT__i_gpio__DOT__core__DOT__DIRECTION_DATA
                                                         [2U] 
                                                         << 0x10U)))) 
                                               | (0x80000U 
                                                  & (vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out11 
                                                     & (vlSelf->tb__DOT__i_gpio__DOT__core__DOT__DIRECTION_DATA
                                                        [2U] 
                                                        << 0x10U)))) 
                                              | (0x100000U 
                                                 & (vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out12 
                                                    & (vlSelf->tb__DOT__i_gpio__DOT__core__DOT__DIRECTION_DATA
                                                       [2U] 
                                                       << 0x10U)))) 
                                             | (0x200000U 
                                                & (vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out13 
                                                   & (vlSelf->tb__DOT__i_gpio__DOT__core__DOT__DIRECTION_DATA
                                                      [2U] 
                                                      << 0x10U)))) 
                                            | (0x400000U 
                                               & (vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out14 
                                                  & (vlSelf->tb__DOT__i_gpio__DOT__core__DOT__DIRECTION_DATA
                                                     [2U] 
                                                     << 0x10U)))) 
                                           | (0x800000U 
                                              & (vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out15 
                                                 & (vlSelf->tb__DOT__i_gpio__DOT__core__DOT__DIRECTION_DATA
                                                    [2U] 
                                                    << 0x10U))));
    vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_DATA_OUT 
        = vlSelf->tb__DOT__i_gpio__DOT__IP_DATA_OUT;
    vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_DATA_OUT 
        = vlSelf->tb__DOT__i_gpio2__DOT__IP_DATA_OUT;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__IO = vlSelf->tb__DOT__i_gpio2__DOT__IO;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__BUS_CLK 
        = vlSelf->tb__DOT__i_gpio__DOT__BUS_CLK;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__BUS_CLK 
        = vlSelf->tb__DOT__i_gpio2__DOT__BUS_CLK;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__BUS_RST 
        = vlSelf->tb__DOT__i_gpio__DOT__BUS_RST;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__BUS_RST 
        = vlSelf->tb__DOT__i_gpio2__DOT__BUS_RST;
    vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BUS_ADD 
        = vlSelf->tb__DOT__i_gpio__DOT__BUS_ADD;
    vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BUS_ADD 
        = vlSelf->tb__DOT__i_gpio2__DOT__BUS_ADD;
    vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BUS_RD 
        = vlSelf->tb__DOT__i_gpio__DOT__BUS_RD;
    vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BUS_RD 
        = vlSelf->tb__DOT__i_gpio2__DOT__BUS_RD;
    vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BUS_WR 
        = vlSelf->tb__DOT__i_gpio__DOT__BUS_WR;
    vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BUS_WR 
        = vlSelf->tb__DOT__i_gpio2__DOT__BUS_WR;
    vlSelf->tb__DOT__i_gpio__DOT__IP_RD = vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_RD;
    vlSelf->tb__DOT__i_gpio__DOT__IP_ADD = vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_ADD;
    vlSelf->tb__DOT__i_gpio__DOT__IP_WR = vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_WR;
    vlSelf->tb__DOT__i_gpio2__DOT__IP_RD = vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_RD;
    vlSelf->tb__DOT__i_gpio2__DOT__IP_ADD = vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_ADD;
    vlSelf->tb__DOT__i_gpio2__DOT__IP_WR = vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_WR;
    vlSelf->tb__DOT__BUS_DATA = ((((((((IData)(vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__CS) 
                                       & (IData)(vlSelf->BUS_WR))
                                       ? 0U : ((IData)(vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__CS)
                                                ? (IData)(vlSelf->tb__DOT__i_gpio__DOT__IP_DATA_OUT)
                                                : 0U)) 
                                     & (IData)(vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BUS_DATA__out__en0)) 
                                    & (IData)(vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BUS_DATA__out__en0)) 
                                   & (IData)(vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BUS_DATA__out__en0)) 
                                  | ((((((IData)(vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__CS) 
                                         & (IData)(vlSelf->BUS_WR))
                                         ? 0U : ((IData)(vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__CS)
                                                  ? (IData)(vlSelf->tb__DOT__i_gpio2__DOT__IP_DATA_OUT)
                                                  : 0U)) 
                                       & (IData)(vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BUS_DATA__out__en0)) 
                                      & (IData)(vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BUS_DATA__out__en0)) 
                                     & (IData)(vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BUS_DATA__out__en0))) 
                                 | (IData)(vlSelf->BUS_DATA_IN));
    vlSelf->tb__DOT__IO = ((tb__DOT__i_gpio__DOT__IO__out__out2 
                            | (0xff00U & vlSelf->tb__DOT__IO__out7)) 
                           | (0xf00000U & vlSelf->tb__DOT__IO__out8));
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__BUS_RD 
        = vlSelf->tb__DOT__i_gpio__DOT__IP_RD;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__BUS_ADD 
        = vlSelf->tb__DOT__i_gpio__DOT__IP_ADD;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__BUS_WR 
        = vlSelf->tb__DOT__i_gpio__DOT__IP_WR;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__SOFT_RST 
        = ((0U == (IData)(vlSelf->tb__DOT__i_gpio__DOT__IP_ADD)) 
           & (IData)(vlSelf->tb__DOT__i_gpio__DOT__IP_WR));
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__BUS_RD 
        = vlSelf->tb__DOT__i_gpio2__DOT__IP_RD;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__BUS_ADD 
        = vlSelf->tb__DOT__i_gpio2__DOT__IP_ADD;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__BUS_WR 
        = vlSelf->tb__DOT__i_gpio2__DOT__IP_WR;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__SOFT_RST 
        = ((0U == (IData)(vlSelf->tb__DOT__i_gpio2__DOT__IP_ADD)) 
           & (IData)(vlSelf->tb__DOT__i_gpio2__DOT__IP_WR));
    vlSelf->tb__DOT__BUS_DATA_OUT = vlSelf->tb__DOT__BUS_DATA;
    vlSelf->tb__DOT__i_gpio__DOT__BUS_DATA = vlSelf->tb__DOT__BUS_DATA;
    vlSelf->tb__DOT__i_gpio2__DOT__BUS_DATA = vlSelf->tb__DOT__BUS_DATA;
    vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_DATA_IN 
        = vlSelf->tb__DOT__BUS_DATA;
    vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_DATA_IN 
        = vlSelf->tb__DOT__BUS_DATA;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__RST = 
        ((IData)(vlSelf->BUS_RST) | (IData)(vlSelf->tb__DOT__i_gpio__DOT__core__DOT__SOFT_RST));
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__RST = 
        ((IData)(vlSelf->BUS_RST) | (IData)(vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__SOFT_RST));
    vlSelf->BUS_DATA_OUT = vlSelf->tb__DOT__BUS_DATA_OUT;
    vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BUS_DATA 
        = vlSelf->tb__DOT__i_gpio__DOT__BUS_DATA;
    vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BUS_DATA 
        = vlSelf->tb__DOT__i_gpio2__DOT__BUS_DATA;
    vlSelf->tb__DOT__i_gpio__DOT__IP_DATA_IN = vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_DATA_IN;
    vlSelf->tb__DOT__i_gpio2__DOT__IP_DATA_IN = vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_DATA_IN;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__BUS_DATA_IN 
        = vlSelf->tb__DOT__i_gpio__DOT__IP_DATA_IN;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__BUS_DATA_IN 
        = vlSelf->tb__DOT__i_gpio2__DOT__IP_DATA_IN;
}

VL_ATTR_COLD void Vtop___024root___eval_initial(Vtop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_initial\n"); );
    // Body
    vlSelf->__Vclklast__TOP__BUS_CLK = vlSelf->BUS_CLK;
}

VL_ATTR_COLD void Vtop___024root___eval_settle(Vtop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_settle\n"); );
    // Body
    Vtop___024root___settle__TOP__0(vlSelf);
}

VL_ATTR_COLD void Vtop___024root___final(Vtop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___final\n"); );
}

VL_ATTR_COLD void Vtop___024root___ctor_var_reset(Vtop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___ctor_var_reset\n"); );
    // Body
    vlSelf->BUS_CLK = VL_RAND_RESET_I(1);
    vlSelf->BUS_RST = VL_RAND_RESET_I(1);
    vlSelf->BUS_ADD = VL_RAND_RESET_I(16);
    vlSelf->BUS_DATA_IN = VL_RAND_RESET_I(8);
    vlSelf->BUS_DATA_OUT = VL_RAND_RESET_I(8);
    vlSelf->BUS_RD = VL_RAND_RESET_I(1);
    vlSelf->BUS_WR = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__BUS_CLK = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__BUS_RST = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__BUS_ADD = VL_RAND_RESET_I(16);
    vlSelf->tb__DOT__BUS_DATA_IN = VL_RAND_RESET_I(8);
    vlSelf->tb__DOT__BUS_DATA_OUT = VL_RAND_RESET_I(8);
    vlSelf->tb__DOT__BUS_RD = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__BUS_WR = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__BUS_DATA = VL_RAND_RESET_I(8);
    vlSelf->tb__DOT__IO = VL_RAND_RESET_I(24);
    vlSelf->tb__DOT__IO_2 = VL_RAND_RESET_I(16);
    vlSelf->tb__DOT__IO__out7 = 0;
    vlSelf->tb__DOT__IO__out8 = 0;
    vlSelf->tb__DOT__i_gpio__DOT__BUS_CLK = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio__DOT__BUS_RST = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio__DOT__BUS_ADD = VL_RAND_RESET_I(16);
    vlSelf->tb__DOT__i_gpio__DOT__BUS_DATA = VL_RAND_RESET_I(8);
    vlSelf->tb__DOT__i_gpio__DOT__BUS_RD = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio__DOT__BUS_WR = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio__DOT__IO = VL_RAND_RESET_I(24);
    vlSelf->tb__DOT__i_gpio__DOT__IP_RD = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio__DOT__IP_WR = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio__DOT__IP_ADD = VL_RAND_RESET_I(16);
    vlSelf->tb__DOT__i_gpio__DOT__IP_DATA_IN = VL_RAND_RESET_I(8);
    vlSelf->tb__DOT__i_gpio__DOT__IP_DATA_OUT = VL_RAND_RESET_I(8);
    vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BUS_RD = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BUS_WR = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BUS_ADD = VL_RAND_RESET_I(16);
    vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BUS_DATA = VL_RAND_RESET_I(8);
    vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_RD = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_WR = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_ADD = VL_RAND_RESET_I(16);
    vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_DATA_IN = VL_RAND_RESET_I(8);
    vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_DATA_OUT = VL_RAND_RESET_I(8);
    vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__CS = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BUS_DATA__out__en0 = 0;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__BUS_CLK = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__BUS_RST = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__BUS_ADD = VL_RAND_RESET_I(16);
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__BUS_DATA_IN = VL_RAND_RESET_I(8);
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__BUS_DATA_OUT = VL_RAND_RESET_I(8);
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__BUS_RD = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__BUS_WR = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO = VL_RAND_RESET_I(24);
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__SOFT_RST = VL_RAND_RESET_I(1);
    for (int __Vi0=0; __Vi0<3; ++__Vi0) {
        vlSelf->tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA[__Vi0] = VL_RAND_RESET_I(8);
    }
    for (int __Vi0=0; __Vi0<3; ++__Vi0) {
        vlSelf->tb__DOT__i_gpio__DOT__core__DOT__OUTPUT_DATA[__Vi0] = VL_RAND_RESET_I(8);
    }
    for (int __Vi0=0; __Vi0<3; ++__Vi0) {
        vlSelf->tb__DOT__i_gpio__DOT__core__DOT__DIRECTION_DATA[__Vi0] = VL_RAND_RESET_I(8);
    }
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__RST = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__bi = VL_RAND_RESET_I(32);
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out0 = 0;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out1 = 0;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out2 = 0;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out3 = 0;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out4 = 0;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out5 = 0;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out6 = 0;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out7 = 0;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out8 = 0;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out9 = 0;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out10 = 0;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out11 = 0;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out12 = 0;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out13 = 0;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out14 = 0;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT__IO__out__out15 = 0;
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h6bb4edf4__0 = VL_RAND_RESET_I(8);
    vlSelf->tb__DOT__i_gpio__DOT__core__DOT____Vlvbound_h535782b1__0 = VL_RAND_RESET_I(8);
    vlSelf->tb__DOT__i_gpio2__DOT__BUS_CLK = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio2__DOT__BUS_RST = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio2__DOT__BUS_ADD = VL_RAND_RESET_I(16);
    vlSelf->tb__DOT__i_gpio2__DOT__BUS_DATA = VL_RAND_RESET_I(8);
    vlSelf->tb__DOT__i_gpio2__DOT__BUS_RD = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio2__DOT__BUS_WR = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio2__DOT__IO = VL_RAND_RESET_I(16);
    vlSelf->tb__DOT__i_gpio2__DOT__IP_RD = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio2__DOT__IP_WR = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio2__DOT__IP_ADD = VL_RAND_RESET_I(16);
    vlSelf->tb__DOT__i_gpio2__DOT__IP_DATA_IN = VL_RAND_RESET_I(8);
    vlSelf->tb__DOT__i_gpio2__DOT__IP_DATA_OUT = VL_RAND_RESET_I(8);
    vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BUS_RD = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BUS_WR = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BUS_ADD = VL_RAND_RESET_I(16);
    vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BUS_DATA = VL_RAND_RESET_I(8);
    vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_RD = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_WR = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_ADD = VL_RAND_RESET_I(16);
    vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_DATA_IN = VL_RAND_RESET_I(8);
    vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_DATA_OUT = VL_RAND_RESET_I(8);
    vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__CS = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BUS_DATA__out__en0 = 0;
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__BUS_CLK = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__BUS_RST = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__BUS_ADD = VL_RAND_RESET_I(16);
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__BUS_DATA_IN = VL_RAND_RESET_I(8);
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__BUS_DATA_OUT = VL_RAND_RESET_I(8);
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__BUS_RD = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__BUS_WR = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__IO = VL_RAND_RESET_I(16);
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__SOFT_RST = VL_RAND_RESET_I(1);
    for (int __Vi0=0; __Vi0<2; ++__Vi0) {
        vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA[__Vi0] = VL_RAND_RESET_I(8);
    }
    for (int __Vi0=0; __Vi0<2; ++__Vi0) {
        vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__OUTPUT_DATA[__Vi0] = VL_RAND_RESET_I(8);
    }
    for (int __Vi0=0; __Vi0<2; ++__Vi0) {
        vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__DIRECTION_DATA[__Vi0] = VL_RAND_RESET_I(8);
    }
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__RST = VL_RAND_RESET_I(1);
    vlSelf->tb__DOT__i_gpio2__DOT__core__DOT__bi = VL_RAND_RESET_I(32);
    vlSelf->__Vchglast__TOP__tb__DOT__IO = VL_RAND_RESET_I(24);
}
