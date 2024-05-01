// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtop.h for the primary calling header

#include "verilated.h"
#include "verilated_dpi.h"

#include "Vtop__Syms.h"
#include "Vtop___024root.h"

// Parameter definitions for Vtop___024root
constexpr SData/*15:0*/ Vtop___024root::tb__DOT__GPIO_BASEADDR;
constexpr SData/*15:0*/ Vtop___024root::tb__DOT__GPIO_HIGHADDR;
constexpr SData/*15:0*/ Vtop___024root::tb__DOT__GPIO2_BASEADDR;
constexpr SData/*15:0*/ Vtop___024root::tb__DOT__GPIO2_HIGHADDR;
constexpr SData/*15:0*/ Vtop___024root::tb__DOT__i_gpio__DOT__BASEADDR;
constexpr SData/*15:0*/ Vtop___024root::tb__DOT__i_gpio__DOT__HIGHADDR;
constexpr SData/*15:0*/ Vtop___024root::tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BASEADDR;
constexpr SData/*15:0*/ Vtop___024root::tb__DOT__i_gpio__DOT__bus_to_ip__DOT__HIGHADDR;
constexpr SData/*15:0*/ Vtop___024root::tb__DOT__i_gpio2__DOT__BASEADDR;
constexpr SData/*15:0*/ Vtop___024root::tb__DOT__i_gpio2__DOT__HIGHADDR;
constexpr SData/*15:0*/ Vtop___024root::tb__DOT__i_gpio2__DOT__IO_DIRECTION;
constexpr SData/*15:0*/ Vtop___024root::tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BASEADDR;
constexpr SData/*15:0*/ Vtop___024root::tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__HIGHADDR;
constexpr SData/*15:0*/ Vtop___024root::tb__DOT__i_gpio2__DOT__core__DOT__IO_DIRECTION;
constexpr IData/*31:0*/ Vtop___024root::tb__DOT__i_gpio__DOT__ABUSWIDTH;
constexpr IData/*31:0*/ Vtop___024root::tb__DOT__i_gpio__DOT__IO_WIDTH;
constexpr IData/*23:0*/ Vtop___024root::tb__DOT__i_gpio__DOT__IO_DIRECTION;
constexpr IData/*23:0*/ Vtop___024root::tb__DOT__i_gpio__DOT__IO_TRI;
constexpr IData/*31:0*/ Vtop___024root::tb__DOT__i_gpio__DOT__bus_to_ip__DOT__ABUSWIDTH;
constexpr IData/*31:0*/ Vtop___024root::tb__DOT__i_gpio__DOT__bus_to_ip__DOT__DBUSWIDTH;
constexpr IData/*31:0*/ Vtop___024root::tb__DOT__i_gpio__DOT__core__DOT__ABUSWIDTH;
constexpr IData/*31:0*/ Vtop___024root::tb__DOT__i_gpio__DOT__core__DOT__IO_WIDTH;
constexpr IData/*23:0*/ Vtop___024root::tb__DOT__i_gpio__DOT__core__DOT__IO_DIRECTION;
constexpr IData/*23:0*/ Vtop___024root::tb__DOT__i_gpio__DOT__core__DOT__IO_TRI;
constexpr IData/*31:0*/ Vtop___024root::tb__DOT__i_gpio__DOT__core__DOT__VERSION;
constexpr IData/*31:0*/ Vtop___024root::tb__DOT__i_gpio__DOT__core__DOT__IO_BYTES;
constexpr IData/*31:0*/ Vtop___024root::tb__DOT__i_gpio2__DOT__ABUSWIDTH;
constexpr IData/*31:0*/ Vtop___024root::tb__DOT__i_gpio2__DOT__IO_WIDTH;
constexpr IData/*31:0*/ Vtop___024root::tb__DOT__i_gpio2__DOT__IO_TRI;
constexpr IData/*31:0*/ Vtop___024root::tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__ABUSWIDTH;
constexpr IData/*31:0*/ Vtop___024root::tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__DBUSWIDTH;
constexpr IData/*31:0*/ Vtop___024root::tb__DOT__i_gpio2__DOT__core__DOT__ABUSWIDTH;
constexpr IData/*31:0*/ Vtop___024root::tb__DOT__i_gpio2__DOT__core__DOT__IO_WIDTH;
constexpr IData/*31:0*/ Vtop___024root::tb__DOT__i_gpio2__DOT__core__DOT__IO_TRI;
constexpr IData/*31:0*/ Vtop___024root::tb__DOT__i_gpio2__DOT__core__DOT__VERSION;
constexpr IData/*31:0*/ Vtop___024root::tb__DOT__i_gpio2__DOT__core__DOT__IO_BYTES;


void Vtop___024root___ctor_var_reset(Vtop___024root* vlSelf);

Vtop___024root::Vtop___024root(Vtop__Syms* symsp, const char* name)
    : VerilatedModule{name}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vtop___024root___ctor_var_reset(this);
}

void Vtop___024root::__Vconfigure(bool first) {
    if (false && first) {}  // Prevent unused
}

Vtop___024root::~Vtop___024root() {
}
