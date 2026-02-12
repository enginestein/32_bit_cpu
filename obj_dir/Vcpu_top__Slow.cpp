// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vcpu_top.h for the primary calling header

#include "Vcpu_top.h"
#include "Vcpu_top__Syms.h"

//==========

VL_CTOR_IMP(Vcpu_top) {
    Vcpu_top__Syms* __restrict vlSymsp = __VlSymsp = new Vcpu_top__Syms(this, name());
    Vcpu_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Reset internal values
    
    // Reset structure values
    _ctor_var_reset();
}

void Vcpu_top::__Vconfigure(Vcpu_top__Syms* vlSymsp, bool first) {
    if (false && first) {}  // Prevent unused
    this->__VlSymsp = vlSymsp;
    if (false && this->__VlSymsp) {}  // Prevent unused
    Verilated::timeunit(-12);
    Verilated::timeprecision(-12);
}

Vcpu_top::~Vcpu_top() {
    VL_DO_CLEAR(delete __VlSymsp, __VlSymsp = NULL);
}

void Vcpu_top::_initial__TOP__1(Vcpu_top__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcpu_top::_initial__TOP__1\n"); );
    Vcpu_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->cpu_top__DOT__imem_u__DOT__mem[0U] = 0x500093U;
    vlTOPp->cpu_top__DOT__imem_u__DOT__mem[1U] = 0x308113U;
    vlTOPp->cpu_top__DOT__imem_u__DOT__mem[2U] = 0x210193U;
}

void Vcpu_top::_settle__TOP__3(Vcpu_top__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcpu_top::_settle__TOP__3\n"); );
    Vcpu_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->pc_dbg = vlTOPp->cpu_top__DOT__pc;
    vlTOPp->dbg_x1 = vlTOPp->cpu_top__DOT__rf_u__DOT__regs
        [1U];
    vlTOPp->dbg_x2 = vlTOPp->cpu_top__DOT__rf_u__DOT__regs
        [2U];
    vlTOPp->dbg_x3 = vlTOPp->cpu_top__DOT__rf_u__DOT__regs
        [3U];
    vlTOPp->cpu_top__DOT__instr = vlTOPp->cpu_top__DOT__imem_u__DOT__mem
        [(0xffU & (vlTOPp->cpu_top__DOT__pc >> 2U))];
    vlTOPp->cpu_top__DOT__reg_we = 0U;
    if ((0x33U == (0x7fU & vlTOPp->cpu_top__DOT__instr))) {
        vlTOPp->cpu_top__DOT__reg_we = 1U;
    } else {
        if ((0x13U == (0x7fU & vlTOPp->cpu_top__DOT__instr))) {
            vlTOPp->cpu_top__DOT__reg_we = 1U;
        }
    }
    vlTOPp->cpu_top__DOT__rs1_val = ((0U == (0x1fU 
                                             & (vlTOPp->cpu_top__DOT__instr 
                                                >> 0xfU)))
                                      ? 0U : vlTOPp->cpu_top__DOT__rf_u__DOT__regs
                                     [(0x1fU & (vlTOPp->cpu_top__DOT__instr 
                                                >> 0xfU))]);
    vlTOPp->cpu_top__DOT__alu_op = 0U;
    if ((0x33U == (0x7fU & vlTOPp->cpu_top__DOT__instr))) {
        vlTOPp->cpu_top__DOT__alu_op = 2U;
    } else {
        if ((0x13U == (0x7fU & vlTOPp->cpu_top__DOT__instr))) {
            vlTOPp->cpu_top__DOT__alu_op = 2U;
        }
    }
    vlTOPp->cpu_top__DOT__alu_src = 0U;
    if ((0x33U == (0x7fU & vlTOPp->cpu_top__DOT__instr))) {
        vlTOPp->cpu_top__DOT__alu_src = 0U;
    } else {
        if ((0x13U == (0x7fU & vlTOPp->cpu_top__DOT__instr))) {
            vlTOPp->cpu_top__DOT__alu_src = 1U;
        }
    }
    vlTOPp->cpu_top__DOT__alu_control = ((0U == (IData)(vlTOPp->cpu_top__DOT__alu_op))
                                          ? 0U : ((1U 
                                                   == (IData)(vlTOPp->cpu_top__DOT__alu_op))
                                                   ? 1U
                                                   : 
                                                  ((2U 
                                                    == (IData)(vlTOPp->cpu_top__DOT__alu_op))
                                                    ? 
                                                   ((0x4000U 
                                                     & vlTOPp->cpu_top__DOT__instr)
                                                     ? 
                                                    ((0x2000U 
                                                      & vlTOPp->cpu_top__DOT__instr)
                                                      ? 
                                                     ((0x1000U 
                                                       & vlTOPp->cpu_top__DOT__instr)
                                                       ? 2U
                                                       : 3U)
                                                      : 
                                                     ((0x1000U 
                                                       & vlTOPp->cpu_top__DOT__instr)
                                                       ? 
                                                      ((0x20U 
                                                        == 
                                                        (0x7fU 
                                                         & (vlTOPp->cpu_top__DOT__instr 
                                                            >> 0x19U)))
                                                        ? 7U
                                                        : 6U)
                                                       : 4U))
                                                     : 
                                                    ((0x2000U 
                                                      & vlTOPp->cpu_top__DOT__instr)
                                                      ? 0U
                                                      : 
                                                     ((0x1000U 
                                                       & vlTOPp->cpu_top__DOT__instr)
                                                       ? 5U
                                                       : 
                                                      ((0x20U 
                                                        == 
                                                        (0x7fU 
                                                         & (vlTOPp->cpu_top__DOT__instr 
                                                            >> 0x19U)))
                                                        ? 1U
                                                        : 0U))))
                                                    : 0U)));
    vlTOPp->cpu_top__DOT__alu_b = ((IData)(vlTOPp->cpu_top__DOT__alu_src)
                                    ? ((0xfffff000U 
                                        & ((- (IData)(
                                                      (1U 
                                                       & (vlTOPp->cpu_top__DOT__instr 
                                                          >> 0x1fU)))) 
                                           << 0xcU)) 
                                       | (0xfffU & 
                                          (vlTOPp->cpu_top__DOT__instr 
                                           >> 0x14U)))
                                    : ((0U == (0x1fU 
                                               & (vlTOPp->cpu_top__DOT__instr 
                                                  >> 0x14U)))
                                        ? 0U : vlTOPp->cpu_top__DOT__rf_u__DOT__regs
                                       [(0x1fU & (vlTOPp->cpu_top__DOT__instr 
                                                  >> 0x14U))]));
    vlTOPp->cpu_top__DOT__alu_out = ((8U & (IData)(vlTOPp->cpu_top__DOT__alu_control))
                                      ? ((4U & (IData)(vlTOPp->cpu_top__DOT__alu_control))
                                          ? ((2U & (IData)(vlTOPp->cpu_top__DOT__alu_control))
                                              ? 0U : 
                                             ((1U & (IData)(vlTOPp->cpu_top__DOT__alu_control))
                                               ? ((vlTOPp->cpu_top__DOT__rs1_val 
                                                   > vlTOPp->cpu_top__DOT__alu_b)
                                                   ? 1U
                                                   : 0U)
                                               : ((vlTOPp->cpu_top__DOT__rs1_val 
                                                   >= vlTOPp->cpu_top__DOT__alu_b)
                                                   ? 1U
                                                   : 0U)))
                                          : ((2U & (IData)(vlTOPp->cpu_top__DOT__alu_control))
                                              ? ((1U 
                                                  & (IData)(vlTOPp->cpu_top__DOT__alu_control))
                                                  ? 
                                                 ((vlTOPp->cpu_top__DOT__rs1_val 
                                                   != vlTOPp->cpu_top__DOT__alu_b)
                                                   ? 1U
                                                   : 0U)
                                                  : 
                                                 ((vlTOPp->cpu_top__DOT__rs1_val 
                                                   == vlTOPp->cpu_top__DOT__alu_b)
                                                   ? 1U
                                                   : 0U))
                                              : ((1U 
                                                  & (IData)(vlTOPp->cpu_top__DOT__alu_control))
                                                  ? 
                                                 ((vlTOPp->cpu_top__DOT__rs1_val 
                                                   <= vlTOPp->cpu_top__DOT__alu_b)
                                                   ? 1U
                                                   : 0U)
                                                  : 
                                                 ((vlTOPp->cpu_top__DOT__rs1_val 
                                                   < vlTOPp->cpu_top__DOT__alu_b)
                                                   ? 1U
                                                   : 0U))))
                                      : ((4U & (IData)(vlTOPp->cpu_top__DOT__alu_control))
                                          ? ((2U & (IData)(vlTOPp->cpu_top__DOT__alu_control))
                                              ? ((1U 
                                                  & (IData)(vlTOPp->cpu_top__DOT__alu_control))
                                                  ? 
                                                 ((0x1fU 
                                                   >= vlTOPp->cpu_top__DOT__alu_b)
                                                   ? 
                                                  (vlTOPp->cpu_top__DOT__rs1_val 
                                                   >> vlTOPp->cpu_top__DOT__alu_b)
                                                   : 0U)
                                                  : 
                                                 ((0x1fU 
                                                   >= vlTOPp->cpu_top__DOT__alu_b)
                                                   ? 
                                                  (vlTOPp->cpu_top__DOT__rs1_val 
                                                   >> vlTOPp->cpu_top__DOT__alu_b)
                                                   : 0U))
                                              : ((1U 
                                                  & (IData)(vlTOPp->cpu_top__DOT__alu_control))
                                                  ? 
                                                 ((0x1fU 
                                                   >= vlTOPp->cpu_top__DOT__alu_b)
                                                   ? 
                                                  (vlTOPp->cpu_top__DOT__rs1_val 
                                                   << vlTOPp->cpu_top__DOT__alu_b)
                                                   : 0U)
                                                  : 
                                                 (vlTOPp->cpu_top__DOT__rs1_val 
                                                  ^ vlTOPp->cpu_top__DOT__alu_b)))
                                          : ((2U & (IData)(vlTOPp->cpu_top__DOT__alu_control))
                                              ? ((1U 
                                                  & (IData)(vlTOPp->cpu_top__DOT__alu_control))
                                                  ? 
                                                 (vlTOPp->cpu_top__DOT__rs1_val 
                                                  | vlTOPp->cpu_top__DOT__alu_b)
                                                  : 
                                                 (vlTOPp->cpu_top__DOT__rs1_val 
                                                  & vlTOPp->cpu_top__DOT__alu_b))
                                              : ((1U 
                                                  & (IData)(vlTOPp->cpu_top__DOT__alu_control))
                                                  ? 
                                                 (vlTOPp->cpu_top__DOT__rs1_val 
                                                  - vlTOPp->cpu_top__DOT__alu_b)
                                                  : 
                                                 (vlTOPp->cpu_top__DOT__rs1_val 
                                                  + vlTOPp->cpu_top__DOT__alu_b)))));
}

void Vcpu_top::_eval_initial(Vcpu_top__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcpu_top::_eval_initial\n"); );
    Vcpu_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->_initial__TOP__1(vlSymsp);
    vlTOPp->__Vclklast__TOP__clk = vlTOPp->clk;
}

void Vcpu_top::final() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcpu_top::final\n"); );
    // Variables
    Vcpu_top__Syms* __restrict vlSymsp = this->__VlSymsp;
    Vcpu_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
}

void Vcpu_top::_eval_settle(Vcpu_top__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcpu_top::_eval_settle\n"); );
    Vcpu_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->_settle__TOP__3(vlSymsp);
    vlTOPp->__Vm_traceActivity[1U] = 1U;
    vlTOPp->__Vm_traceActivity[0U] = 1U;
}

void Vcpu_top::_ctor_var_reset() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcpu_top::_ctor_var_reset\n"); );
    // Body
    clk = VL_RAND_RESET_I(1);
    reset = VL_RAND_RESET_I(1);
    pc_dbg = VL_RAND_RESET_I(32);
    dbg_x1 = VL_RAND_RESET_I(32);
    dbg_x2 = VL_RAND_RESET_I(32);
    dbg_x3 = VL_RAND_RESET_I(32);
    cpu_top__DOT__alu_src = VL_RAND_RESET_I(1);
    cpu_top__DOT__alu_op = VL_RAND_RESET_I(2);
    cpu_top__DOT__alu_b = VL_RAND_RESET_I(32);
    cpu_top__DOT__alu_control = VL_RAND_RESET_I(4);
    cpu_top__DOT__pc = VL_RAND_RESET_I(32);
    cpu_top__DOT__instr = VL_RAND_RESET_I(32);
    cpu_top__DOT__alu_out = VL_RAND_RESET_I(32);
    cpu_top__DOT__rs1_val = VL_RAND_RESET_I(32);
    cpu_top__DOT__reg_we = VL_RAND_RESET_I(1);
    { int __Vi0=0; for (; __Vi0<256; ++__Vi0) {
            cpu_top__DOT__imem_u__DOT__mem[__Vi0] = VL_RAND_RESET_I(32);
    }}
    { int __Vi0=0; for (; __Vi0<32; ++__Vi0) {
            cpu_top__DOT__rf_u__DOT__regs[__Vi0] = VL_RAND_RESET_I(32);
    }}
    { int __Vi0=0; for (; __Vi0<2; ++__Vi0) {
            __Vm_traceActivity[__Vi0] = VL_RAND_RESET_I(1);
    }}
}
