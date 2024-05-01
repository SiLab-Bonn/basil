// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "Vtop__Syms.h"
#include "Vtop.h"
#include "Vtop___024root.h"

// FUNCTIONS
Vtop__Syms::~Vtop__Syms()
{

    // Tear down scope hierarchy
    __Vhier.remove(0, &__Vscope_tb);
    __Vhier.remove(&__Vscope_tb, &__Vscope_tb__i_gpio);
    __Vhier.remove(&__Vscope_tb, &__Vscope_tb__i_gpio2);
    __Vhier.remove(&__Vscope_tb__i_gpio, &__Vscope_tb__i_gpio__bus_to_ip);
    __Vhier.remove(&__Vscope_tb__i_gpio, &__Vscope_tb__i_gpio__core);
    __Vhier.remove(&__Vscope_tb__i_gpio2, &__Vscope_tb__i_gpio2__bus_to_ip);
    __Vhier.remove(&__Vscope_tb__i_gpio2, &__Vscope_tb__i_gpio2__core);

}

Vtop__Syms::Vtop__Syms(VerilatedContext* contextp, const char* namep, Vtop* modelp)
    : VerilatedSyms{contextp}
    // Setup internal state of the Syms class
    , __Vm_modelp{modelp}
    // Setup module instances
    , TOP{this, namep}
{
    // Configure time unit / time precision
    _vm_contextp__->timeunit(-12);
    _vm_contextp__->timeprecision(-12);
    // Setup each module's pointers to their submodules
    // Setup each module's pointer back to symbol table (for public functions)
    TOP.__Vconfigure(true);
    // Setup scopes
    __Vscope_TOP.configure(this, name(), "TOP", "TOP", 0, VerilatedScope::SCOPE_OTHER);
    __Vscope_tb.configure(this, name(), "tb", "tb", -12, VerilatedScope::SCOPE_MODULE);
    __Vscope_tb__i_gpio.configure(this, name(), "tb.i_gpio", "i_gpio", -12, VerilatedScope::SCOPE_MODULE);
    __Vscope_tb__i_gpio2.configure(this, name(), "tb.i_gpio2", "i_gpio2", -12, VerilatedScope::SCOPE_MODULE);
    __Vscope_tb__i_gpio2__bus_to_ip.configure(this, name(), "tb.i_gpio2.bus_to_ip", "bus_to_ip", -12, VerilatedScope::SCOPE_MODULE);
    __Vscope_tb__i_gpio2__core.configure(this, name(), "tb.i_gpio2.core", "core", -12, VerilatedScope::SCOPE_MODULE);
    __Vscope_tb__i_gpio__bus_to_ip.configure(this, name(), "tb.i_gpio.bus_to_ip", "bus_to_ip", -12, VerilatedScope::SCOPE_MODULE);
    __Vscope_tb__i_gpio__core.configure(this, name(), "tb.i_gpio.core", "core", -12, VerilatedScope::SCOPE_MODULE);

    // Set up scope hierarchy
    __Vhier.add(0, &__Vscope_tb);
    __Vhier.add(&__Vscope_tb, &__Vscope_tb__i_gpio);
    __Vhier.add(&__Vscope_tb, &__Vscope_tb__i_gpio2);
    __Vhier.add(&__Vscope_tb__i_gpio, &__Vscope_tb__i_gpio__bus_to_ip);
    __Vhier.add(&__Vscope_tb__i_gpio, &__Vscope_tb__i_gpio__core);
    __Vhier.add(&__Vscope_tb__i_gpio2, &__Vscope_tb__i_gpio2__bus_to_ip);
    __Vhier.add(&__Vscope_tb__i_gpio2, &__Vscope_tb__i_gpio2__core);

    // Setup export functions
    for (int __Vfinal=0; __Vfinal<2; __Vfinal++) {
        __Vscope_TOP.varInsert(__Vfinal,"BUS_ADD", &(TOP.BUS_ADD), false, VLVT_UINT16,VLVD_IN|VLVF_PUB_RW,1 ,15,0);
        __Vscope_TOP.varInsert(__Vfinal,"BUS_CLK", &(TOP.BUS_CLK), false, VLVT_UINT8,VLVD_IN|VLVF_PUB_RW,0);
        __Vscope_TOP.varInsert(__Vfinal,"BUS_DATA_IN", &(TOP.BUS_DATA_IN), false, VLVT_UINT8,VLVD_IN|VLVF_PUB_RW,1 ,7,0);
        __Vscope_TOP.varInsert(__Vfinal,"BUS_DATA_OUT", &(TOP.BUS_DATA_OUT), false, VLVT_UINT8,VLVD_OUT|VLVF_PUB_RW,1 ,7,0);
        __Vscope_TOP.varInsert(__Vfinal,"BUS_RD", &(TOP.BUS_RD), false, VLVT_UINT8,VLVD_IN|VLVF_PUB_RW,0);
        __Vscope_TOP.varInsert(__Vfinal,"BUS_RST", &(TOP.BUS_RST), false, VLVT_UINT8,VLVD_IN|VLVF_PUB_RW,0);
        __Vscope_TOP.varInsert(__Vfinal,"BUS_WR", &(TOP.BUS_WR), false, VLVT_UINT8,VLVD_IN|VLVF_PUB_RW,0);
        __Vscope_tb.varInsert(__Vfinal,"BUS_ADD", &(TOP.tb__DOT__BUS_ADD), false, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb.varInsert(__Vfinal,"BUS_CLK", &(TOP.tb__DOT__BUS_CLK), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb.varInsert(__Vfinal,"BUS_DATA", &(TOP.tb__DOT__BUS_DATA), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_tb.varInsert(__Vfinal,"BUS_DATA_IN", &(TOP.tb__DOT__BUS_DATA_IN), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_tb.varInsert(__Vfinal,"BUS_DATA_OUT", &(TOP.tb__DOT__BUS_DATA_OUT), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_tb.varInsert(__Vfinal,"BUS_RD", &(TOP.tb__DOT__BUS_RD), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb.varInsert(__Vfinal,"BUS_RST", &(TOP.tb__DOT__BUS_RST), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb.varInsert(__Vfinal,"BUS_WR", &(TOP.tb__DOT__BUS_WR), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb.varInsert(__Vfinal,"GPIO2_BASEADDR", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__GPIO2_BASEADDR))), true, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb.varInsert(__Vfinal,"GPIO2_HIGHADDR", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__GPIO2_HIGHADDR))), true, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb.varInsert(__Vfinal,"GPIO_BASEADDR", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__GPIO_BASEADDR))), true, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb.varInsert(__Vfinal,"GPIO_HIGHADDR", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__GPIO_HIGHADDR))), true, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb.varInsert(__Vfinal,"IO", &(TOP.tb__DOT__IO), false, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,23,0);
        __Vscope_tb.varInsert(__Vfinal,"IO_2", &(TOP.tb__DOT__IO_2), false, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb__i_gpio.varInsert(__Vfinal,"ABUSWIDTH", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio__DOT__ABUSWIDTH))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,31,0);
        __Vscope_tb__i_gpio.varInsert(__Vfinal,"BASEADDR", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio__DOT__BASEADDR))), true, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb__i_gpio.varInsert(__Vfinal,"BUS_ADD", &(TOP.tb__DOT__i_gpio__DOT__BUS_ADD), false, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb__i_gpio.varInsert(__Vfinal,"BUS_CLK", &(TOP.tb__DOT__i_gpio__DOT__BUS_CLK), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio.varInsert(__Vfinal,"BUS_DATA", &(TOP.tb__DOT__i_gpio__DOT__BUS_DATA), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_tb__i_gpio.varInsert(__Vfinal,"BUS_RD", &(TOP.tb__DOT__i_gpio__DOT__BUS_RD), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio.varInsert(__Vfinal,"BUS_RST", &(TOP.tb__DOT__i_gpio__DOT__BUS_RST), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio.varInsert(__Vfinal,"BUS_WR", &(TOP.tb__DOT__i_gpio__DOT__BUS_WR), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio.varInsert(__Vfinal,"HIGHADDR", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio__DOT__HIGHADDR))), true, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb__i_gpio.varInsert(__Vfinal,"IO", &(TOP.tb__DOT__i_gpio__DOT__IO), false, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,23,0);
        __Vscope_tb__i_gpio.varInsert(__Vfinal,"IO_DIRECTION", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio__DOT__IO_DIRECTION))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,23,0);
        __Vscope_tb__i_gpio.varInsert(__Vfinal,"IO_TRI", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio__DOT__IO_TRI))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,23,0);
        __Vscope_tb__i_gpio.varInsert(__Vfinal,"IO_WIDTH", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio__DOT__IO_WIDTH))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,31,0);
        __Vscope_tb__i_gpio.varInsert(__Vfinal,"IP_ADD", &(TOP.tb__DOT__i_gpio__DOT__IP_ADD), false, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb__i_gpio.varInsert(__Vfinal,"IP_DATA_IN", &(TOP.tb__DOT__i_gpio__DOT__IP_DATA_IN), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_tb__i_gpio.varInsert(__Vfinal,"IP_DATA_OUT", &(TOP.tb__DOT__i_gpio__DOT__IP_DATA_OUT), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_tb__i_gpio.varInsert(__Vfinal,"IP_RD", &(TOP.tb__DOT__i_gpio__DOT__IP_RD), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio.varInsert(__Vfinal,"IP_WR", &(TOP.tb__DOT__i_gpio__DOT__IP_WR), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio2.varInsert(__Vfinal,"ABUSWIDTH", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio2__DOT__ABUSWIDTH))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,31,0);
        __Vscope_tb__i_gpio2.varInsert(__Vfinal,"BASEADDR", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio2__DOT__BASEADDR))), true, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb__i_gpio2.varInsert(__Vfinal,"BUS_ADD", &(TOP.tb__DOT__i_gpio2__DOT__BUS_ADD), false, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb__i_gpio2.varInsert(__Vfinal,"BUS_CLK", &(TOP.tb__DOT__i_gpio2__DOT__BUS_CLK), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio2.varInsert(__Vfinal,"BUS_DATA", &(TOP.tb__DOT__i_gpio2__DOT__BUS_DATA), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_tb__i_gpio2.varInsert(__Vfinal,"BUS_RD", &(TOP.tb__DOT__i_gpio2__DOT__BUS_RD), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio2.varInsert(__Vfinal,"BUS_RST", &(TOP.tb__DOT__i_gpio2__DOT__BUS_RST), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio2.varInsert(__Vfinal,"BUS_WR", &(TOP.tb__DOT__i_gpio2__DOT__BUS_WR), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio2.varInsert(__Vfinal,"HIGHADDR", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio2__DOT__HIGHADDR))), true, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb__i_gpio2.varInsert(__Vfinal,"IO", &(TOP.tb__DOT__i_gpio2__DOT__IO), false, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb__i_gpio2.varInsert(__Vfinal,"IO_DIRECTION", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio2__DOT__IO_DIRECTION))), true, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb__i_gpio2.varInsert(__Vfinal,"IO_TRI", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio2__DOT__IO_TRI))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,31,0);
        __Vscope_tb__i_gpio2.varInsert(__Vfinal,"IO_WIDTH", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio2__DOT__IO_WIDTH))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,31,0);
        __Vscope_tb__i_gpio2.varInsert(__Vfinal,"IP_ADD", &(TOP.tb__DOT__i_gpio2__DOT__IP_ADD), false, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb__i_gpio2.varInsert(__Vfinal,"IP_DATA_IN", &(TOP.tb__DOT__i_gpio2__DOT__IP_DATA_IN), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_tb__i_gpio2.varInsert(__Vfinal,"IP_DATA_OUT", &(TOP.tb__DOT__i_gpio2__DOT__IP_DATA_OUT), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_tb__i_gpio2.varInsert(__Vfinal,"IP_RD", &(TOP.tb__DOT__i_gpio2__DOT__IP_RD), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio2.varInsert(__Vfinal,"IP_WR", &(TOP.tb__DOT__i_gpio2__DOT__IP_WR), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio2__bus_to_ip.varInsert(__Vfinal,"ABUSWIDTH", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__ABUSWIDTH))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,31,0);
        __Vscope_tb__i_gpio2__bus_to_ip.varInsert(__Vfinal,"BASEADDR", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BASEADDR))), true, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb__i_gpio2__bus_to_ip.varInsert(__Vfinal,"BUS_ADD", &(TOP.tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BUS_ADD), false, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb__i_gpio2__bus_to_ip.varInsert(__Vfinal,"BUS_DATA", &(TOP.tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BUS_DATA), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_tb__i_gpio2__bus_to_ip.varInsert(__Vfinal,"BUS_RD", &(TOP.tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BUS_RD), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio2__bus_to_ip.varInsert(__Vfinal,"BUS_WR", &(TOP.tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__BUS_WR), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio2__bus_to_ip.varInsert(__Vfinal,"CS", &(TOP.tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__CS), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio2__bus_to_ip.varInsert(__Vfinal,"DBUSWIDTH", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__DBUSWIDTH))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,31,0);
        __Vscope_tb__i_gpio2__bus_to_ip.varInsert(__Vfinal,"HIGHADDR", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__HIGHADDR))), true, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb__i_gpio2__bus_to_ip.varInsert(__Vfinal,"IP_ADD", &(TOP.tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_ADD), false, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb__i_gpio2__bus_to_ip.varInsert(__Vfinal,"IP_DATA_IN", &(TOP.tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_DATA_IN), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_tb__i_gpio2__bus_to_ip.varInsert(__Vfinal,"IP_DATA_OUT", &(TOP.tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_DATA_OUT), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_tb__i_gpio2__bus_to_ip.varInsert(__Vfinal,"IP_RD", &(TOP.tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_RD), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio2__bus_to_ip.varInsert(__Vfinal,"IP_WR", &(TOP.tb__DOT__i_gpio2__DOT__bus_to_ip__DOT__IP_WR), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio2__core.varInsert(__Vfinal,"ABUSWIDTH", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio2__DOT__core__DOT__ABUSWIDTH))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,31,0);
        __Vscope_tb__i_gpio2__core.varInsert(__Vfinal,"BUS_ADD", &(TOP.tb__DOT__i_gpio2__DOT__core__DOT__BUS_ADD), false, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb__i_gpio2__core.varInsert(__Vfinal,"BUS_CLK", &(TOP.tb__DOT__i_gpio2__DOT__core__DOT__BUS_CLK), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio2__core.varInsert(__Vfinal,"BUS_DATA_IN", &(TOP.tb__DOT__i_gpio2__DOT__core__DOT__BUS_DATA_IN), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_tb__i_gpio2__core.varInsert(__Vfinal,"BUS_DATA_OUT", &(TOP.tb__DOT__i_gpio2__DOT__core__DOT__BUS_DATA_OUT), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_tb__i_gpio2__core.varInsert(__Vfinal,"BUS_RD", &(TOP.tb__DOT__i_gpio2__DOT__core__DOT__BUS_RD), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio2__core.varInsert(__Vfinal,"BUS_RST", &(TOP.tb__DOT__i_gpio2__DOT__core__DOT__BUS_RST), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio2__core.varInsert(__Vfinal,"BUS_WR", &(TOP.tb__DOT__i_gpio2__DOT__core__DOT__BUS_WR), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio2__core.varInsert(__Vfinal,"DIRECTION_DATA", &(TOP.tb__DOT__i_gpio2__DOT__core__DOT__DIRECTION_DATA), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,2 ,7,0 ,1,0);
        __Vscope_tb__i_gpio2__core.varInsert(__Vfinal,"INPUT_DATA", &(TOP.tb__DOT__i_gpio2__DOT__core__DOT__INPUT_DATA), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,2 ,7,0 ,1,0);
        __Vscope_tb__i_gpio2__core.varInsert(__Vfinal,"IO", &(TOP.tb__DOT__i_gpio2__DOT__core__DOT__IO), false, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb__i_gpio2__core.varInsert(__Vfinal,"IO_BYTES", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio2__DOT__core__DOT__IO_BYTES))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,31,0);
        __Vscope_tb__i_gpio2__core.varInsert(__Vfinal,"IO_DIRECTION", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio2__DOT__core__DOT__IO_DIRECTION))), true, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb__i_gpio2__core.varInsert(__Vfinal,"IO_TRI", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio2__DOT__core__DOT__IO_TRI))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,31,0);
        __Vscope_tb__i_gpio2__core.varInsert(__Vfinal,"IO_WIDTH", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio2__DOT__core__DOT__IO_WIDTH))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,31,0);
        __Vscope_tb__i_gpio2__core.varInsert(__Vfinal,"OUTPUT_DATA", &(TOP.tb__DOT__i_gpio2__DOT__core__DOT__OUTPUT_DATA), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,2 ,7,0 ,1,0);
        __Vscope_tb__i_gpio2__core.varInsert(__Vfinal,"RST", &(TOP.tb__DOT__i_gpio2__DOT__core__DOT__RST), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio2__core.varInsert(__Vfinal,"SOFT_RST", &(TOP.tb__DOT__i_gpio2__DOT__core__DOT__SOFT_RST), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio2__core.varInsert(__Vfinal,"VERSION", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio2__DOT__core__DOT__VERSION))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,31,0);
        __Vscope_tb__i_gpio2__core.varInsert(__Vfinal,"bi", &(TOP.tb__DOT__i_gpio2__DOT__core__DOT__bi), false, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,31,0);
        __Vscope_tb__i_gpio__bus_to_ip.varInsert(__Vfinal,"ABUSWIDTH", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio__DOT__bus_to_ip__DOT__ABUSWIDTH))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,31,0);
        __Vscope_tb__i_gpio__bus_to_ip.varInsert(__Vfinal,"BASEADDR", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BASEADDR))), true, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb__i_gpio__bus_to_ip.varInsert(__Vfinal,"BUS_ADD", &(TOP.tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BUS_ADD), false, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb__i_gpio__bus_to_ip.varInsert(__Vfinal,"BUS_DATA", &(TOP.tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BUS_DATA), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_tb__i_gpio__bus_to_ip.varInsert(__Vfinal,"BUS_RD", &(TOP.tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BUS_RD), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio__bus_to_ip.varInsert(__Vfinal,"BUS_WR", &(TOP.tb__DOT__i_gpio__DOT__bus_to_ip__DOT__BUS_WR), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio__bus_to_ip.varInsert(__Vfinal,"CS", &(TOP.tb__DOT__i_gpio__DOT__bus_to_ip__DOT__CS), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio__bus_to_ip.varInsert(__Vfinal,"DBUSWIDTH", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio__DOT__bus_to_ip__DOT__DBUSWIDTH))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,31,0);
        __Vscope_tb__i_gpio__bus_to_ip.varInsert(__Vfinal,"HIGHADDR", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio__DOT__bus_to_ip__DOT__HIGHADDR))), true, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb__i_gpio__bus_to_ip.varInsert(__Vfinal,"IP_ADD", &(TOP.tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_ADD), false, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb__i_gpio__bus_to_ip.varInsert(__Vfinal,"IP_DATA_IN", &(TOP.tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_DATA_IN), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_tb__i_gpio__bus_to_ip.varInsert(__Vfinal,"IP_DATA_OUT", &(TOP.tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_DATA_OUT), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_tb__i_gpio__bus_to_ip.varInsert(__Vfinal,"IP_RD", &(TOP.tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_RD), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio__bus_to_ip.varInsert(__Vfinal,"IP_WR", &(TOP.tb__DOT__i_gpio__DOT__bus_to_ip__DOT__IP_WR), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio__core.varInsert(__Vfinal,"ABUSWIDTH", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio__DOT__core__DOT__ABUSWIDTH))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,31,0);
        __Vscope_tb__i_gpio__core.varInsert(__Vfinal,"BUS_ADD", &(TOP.tb__DOT__i_gpio__DOT__core__DOT__BUS_ADD), false, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_tb__i_gpio__core.varInsert(__Vfinal,"BUS_CLK", &(TOP.tb__DOT__i_gpio__DOT__core__DOT__BUS_CLK), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio__core.varInsert(__Vfinal,"BUS_DATA_IN", &(TOP.tb__DOT__i_gpio__DOT__core__DOT__BUS_DATA_IN), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_tb__i_gpio__core.varInsert(__Vfinal,"BUS_DATA_OUT", &(TOP.tb__DOT__i_gpio__DOT__core__DOT__BUS_DATA_OUT), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_tb__i_gpio__core.varInsert(__Vfinal,"BUS_RD", &(TOP.tb__DOT__i_gpio__DOT__core__DOT__BUS_RD), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio__core.varInsert(__Vfinal,"BUS_RST", &(TOP.tb__DOT__i_gpio__DOT__core__DOT__BUS_RST), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio__core.varInsert(__Vfinal,"BUS_WR", &(TOP.tb__DOT__i_gpio__DOT__core__DOT__BUS_WR), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio__core.varInsert(__Vfinal,"DIRECTION_DATA", &(TOP.tb__DOT__i_gpio__DOT__core__DOT__DIRECTION_DATA), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,2 ,7,0 ,2,0);
        __Vscope_tb__i_gpio__core.varInsert(__Vfinal,"INPUT_DATA", &(TOP.tb__DOT__i_gpio__DOT__core__DOT__INPUT_DATA), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,2 ,7,0 ,2,0);
        __Vscope_tb__i_gpio__core.varInsert(__Vfinal,"IO", &(TOP.tb__DOT__i_gpio__DOT__core__DOT__IO), false, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,23,0);
        __Vscope_tb__i_gpio__core.varInsert(__Vfinal,"IO_BYTES", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio__DOT__core__DOT__IO_BYTES))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,31,0);
        __Vscope_tb__i_gpio__core.varInsert(__Vfinal,"IO_DIRECTION", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio__DOT__core__DOT__IO_DIRECTION))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,23,0);
        __Vscope_tb__i_gpio__core.varInsert(__Vfinal,"IO_TRI", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio__DOT__core__DOT__IO_TRI))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,23,0);
        __Vscope_tb__i_gpio__core.varInsert(__Vfinal,"IO_WIDTH", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio__DOT__core__DOT__IO_WIDTH))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,31,0);
        __Vscope_tb__i_gpio__core.varInsert(__Vfinal,"OUTPUT_DATA", &(TOP.tb__DOT__i_gpio__DOT__core__DOT__OUTPUT_DATA), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,2 ,7,0 ,2,0);
        __Vscope_tb__i_gpio__core.varInsert(__Vfinal,"RST", &(TOP.tb__DOT__i_gpio__DOT__core__DOT__RST), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio__core.varInsert(__Vfinal,"SOFT_RST", &(TOP.tb__DOT__i_gpio__DOT__core__DOT__SOFT_RST), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_tb__i_gpio__core.varInsert(__Vfinal,"VERSION", const_cast<void*>(static_cast<const void*>(&(TOP.tb__DOT__i_gpio__DOT__core__DOT__VERSION))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,31,0);
        __Vscope_tb__i_gpio__core.varInsert(__Vfinal,"bi", &(TOP.tb__DOT__i_gpio__DOT__core__DOT__bi), false, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,31,0);
    }
}
