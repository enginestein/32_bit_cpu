// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vcpu_top.h for the primary calling header

#include "Vcpu_top.h"
#include "Vcpu_top__Syms.h"

//==========

void Vcpu_top::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vcpu_top::eval\n"); );
    Vcpu_top__Syms* __restrict vlSymsp = this->__VlSymsp;  // Setup global symbol table
    Vcpu_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
#ifdef VL_DEBUG
    // Debug assertions
    _eval_debug_assertions();
#endif  // VL_DEBUG
    // Initialize
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) _eval_initial_loop(vlSymsp);
    // Evaluate till stable
    int __VclockLoop = 0;
    QData __Vchange = 1;
    do {
        VL_DEBUG_IF(VL_DBG_MSGF("+ Clock loop\n"););
        vlSymsp->__Vm_activity = true;
        _eval(vlSymsp);
        if (VL_UNLIKELY(++__VclockLoop > 100)) {
            // About to fail, so enable debug to see what's not settling.
            // Note you must run make with OPT=-DVL_DEBUG for debug prints.
            int __Vsaved_debug = Verilated::debug();
            Verilated::debug(1);
            __Vchange = _change_request(vlSymsp);
            Verilated::debug(__Vsaved_debug);
            VL_FATAL_MT("rtl/cpu_top.sv", 1, "",
                "Verilated model didn't converge\n"
                "- See DIDNOTCONVERGE in the Verilator manual");
        } else {
            __Vchange = _change_request(vlSymsp);
        }
    } while (VL_UNLIKELY(__Vchange));
}

void Vcpu_top::_eval_initial_loop(Vcpu_top__Syms* __restrict vlSymsp) {
    vlSymsp->__Vm_didInit = true;
    _eval_initial(vlSymsp);
    vlSymsp->__Vm_activity = true;
    // Evaluate till stable
    int __VclockLoop = 0;
    QData __Vchange = 1;
    do {
        _eval_settle(vlSymsp);
        _eval(vlSymsp);
        if (VL_UNLIKELY(++__VclockLoop > 100)) {
            // About to fail, so enable debug to see what's not settling.
            // Note you must run make with OPT=-DVL_DEBUG for debug prints.
            int __Vsaved_debug = Verilated::debug();
            Verilated::debug(1);
            __Vchange = _change_request(vlSymsp);
            Verilated::debug(__Vsaved_debug);
            VL_FATAL_MT("rtl/cpu_top.sv", 1, "",
                "Verilated model didn't DC converge\n"
                "- See DIDNOTCONVERGE in the Verilator manual");
        } else {
            __Vchange = _change_request(vlSymsp);
        }
    } while (VL_UNLIKELY(__Vchange));
}

VL_INLINE_OPT void Vcpu_top::_sequent__TOP__2(Vcpu_top__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcpu_top::_sequent__TOP__2\n"); );
    Vcpu_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Variables
    CData/*4:0*/ __Vdlyvdim0__cpu_top__DOT__rf_u__DOT__regs__v0;
    CData/*0:0*/ __Vdlyvset__cpu_top__DOT__rf_u__DOT__regs__v0;
    IData/*31:0*/ __Vdlyvval__cpu_top__DOT__rf_u__DOT__regs__v0;
    // Body
    __Vdlyvset__cpu_top__DOT__rf_u__DOT__regs__v0 = 0U;
    vlTOPp->cpu_top__DOT__pc = ((IData)(vlTOPp->reset)
                                 ? 0U : ((IData)(4U) 
                                         + vlTOPp->cpu_top__DOT__pc));
    if (((IData)(vlTOPp->cpu_top__DOT__reg_we) & (0U 
                                                  != 
                                                  (0x1fU 
                                                   & (vlTOPp->cpu_top__DOT__instr 
                                                      >> 7U))))) {
        __Vdlyvval__cpu_top__DOT__rf_u__DOT__regs__v0 
            = vlTOPp->cpu_top__DOT__alu_out;
        __Vdlyvset__cpu_top__DOT__rf_u__DOT__regs__v0 = 1U;
        __Vdlyvdim0__cpu_top__DOT__rf_u__DOT__regs__v0 
            = (0x1fU & (vlTOPp->cpu_top__DOT__instr 
                        >> 7U));
    }
    if (__Vdlyvset__cpu_top__DOT__rf_u__DOT__regs__v0) {
        vlTOPp->cpu_top__DOT__rf_u__DOT__regs[__Vdlyvdim0__cpu_top__DOT__rf_u__DOT__regs__v0] 
            = __Vdlyvval__cpu_top__DOT__rf_u__DOT__regs__v0;
    }
    vlTOPp->pc_dbg = vlTOPp->cpu_top__DOT__pc;
    vlTOPp->cpu_top__DOT__instr = vlTOPp->cpu_top__DOT__imem_u__DOT__mem
        [(0xffU & (vlTOPp->cpu_top__DOT__pc >> 2U))];
    vlTOPp->dbg_x1 = vlTOPp->cpu_top__DOT__rf_u__DOT__regs
        [1U];
    vlTOPp->dbg_x2 = vlTOPp->cpu_top__DOT__rf_u__DOT__regs
        [2U];
    vlTOPp->dbg_x3 = vlTOPp->cpu_top__DOT__rf_u__DOT__regs
        [3U];
    vlTOPp->cpu_top__DOT__reg_we = 0U;
    if ((0x13U == (0x7fU & vlTOPp->cpu_top__DOT__instr))) {
        vlTOPp->cpu_top__DOT__reg_we = 1U;
    }
    vlTOPp->cpu_top__DOT__alu_out = (((0U == (0x1fU 
                                              & (vlTOPp->cpu_top__DOT__instr 
                                                 >> 0xfU)))
                                       ? 0U : vlTOPp->cpu_top__DOT__rf_u__DOT__regs
                                      [(0x1fU & (vlTOPp->cpu_top__DOT__instr 
                                                 >> 0xfU))]) 
                                     + ((0xfffff000U 
                                         & ((- (IData)(
                                                       (1U 
                                                        & (vlTOPp->cpu_top__DOT__instr 
                                                           >> 0x1fU)))) 
                                            << 0xcU)) 
                                        | (0xfffU & 
                                           (vlTOPp->cpu_top__DOT__instr 
                                            >> 0x14U))));
}

void Vcpu_top::_eval(Vcpu_top__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcpu_top::_eval\n"); );
    Vcpu_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    if (((IData)(vlTOPp->clk) & (~ (IData)(vlTOPp->__Vclklast__TOP__clk)))) {
        vlTOPp->_sequent__TOP__2(vlSymsp);
        vlTOPp->__Vm_traceActivity[1U] = 1U;
    }
    // Final
    vlTOPp->__Vclklast__TOP__clk = vlTOPp->clk;
}

VL_INLINE_OPT QData Vcpu_top::_change_request(Vcpu_top__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcpu_top::_change_request\n"); );
    Vcpu_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    return (vlTOPp->_change_request_1(vlSymsp));
}

VL_INLINE_OPT QData Vcpu_top::_change_request_1(Vcpu_top__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcpu_top::_change_request_1\n"); );
    Vcpu_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    // Change detection
    QData __req = false;  // Logically a bool
    return __req;
}

#ifdef VL_DEBUG
void Vcpu_top::_eval_debug_assertions() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcpu_top::_eval_debug_assertions\n"); );
    // Body
    if (VL_UNLIKELY((clk & 0xfeU))) {
        Verilated::overWidthError("clk");}
    if (VL_UNLIKELY((reset & 0xfeU))) {
        Verilated::overWidthError("reset");}
}
#endif  // VL_DEBUG
