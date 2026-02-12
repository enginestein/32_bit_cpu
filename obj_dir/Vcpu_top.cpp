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
    VL_WRITEF("==== LOGS ====\n");
    VL_WRITEF("pc: %0#\n",32,vlTOPp->cpu_top__DOT__pc);
    VL_WRITEF("instr: %x\n",32,vlTOPp->cpu_top__DOT__instr);
    VL_WRITEF("opcode: %b\n",7,(0x7fU & vlTOPp->cpu_top__DOT__instr));
    VL_WRITEF("rd: %0#\n",5,(0x1fU & (vlTOPp->cpu_top__DOT__instr 
                                      >> 7U)));
    VL_WRITEF("rs1_val: %0#\n",32,vlTOPp->cpu_top__DOT__rs1_val);
    VL_WRITEF("rs2_val: %0#\n",32,((0U == (0x1fU & 
                                           (vlTOPp->cpu_top__DOT__instr 
                                            >> 0x14U)))
                                    ? 0U : vlTOPp->cpu_top__DOT__rf_u__DOT__regs
                                   [(0x1fU & (vlTOPp->cpu_top__DOT__instr 
                                              >> 0x14U))]));
    VL_WRITEF("imm: %0#\n",32,((0xfffff000U & ((- (IData)(
                                                          (1U 
                                                           & (vlTOPp->cpu_top__DOT__instr 
                                                              >> 0x1fU)))) 
                                               << 0xcU)) 
                               | (0xfffU & (vlTOPp->cpu_top__DOT__instr 
                                            >> 0x14U))));
    VL_WRITEF("alu_out: %0#\n",32,vlTOPp->cpu_top__DOT__alu_out);
    VL_WRITEF("reg_we: %b\n",1,vlTOPp->cpu_top__DOT__reg_we);
    VL_WRITEF("dbg_x1: %0#\n",32,vlTOPp->dbg_x1);
    VL_WRITEF("dbg_x2: %0#\n",32,vlTOPp->dbg_x2);
    VL_WRITEF("dbg_x3: %0#\n",32,vlTOPp->dbg_x3);
    VL_WRITEF("==============\n");
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
    vlTOPp->cpu_top__DOT__pc = ((IData)(vlTOPp->reset)
                                 ? 0U : ((IData)(4U) 
                                         + vlTOPp->cpu_top__DOT__pc));
    if (__Vdlyvset__cpu_top__DOT__rf_u__DOT__regs__v0) {
        vlTOPp->cpu_top__DOT__rf_u__DOT__regs[__Vdlyvdim0__cpu_top__DOT__rf_u__DOT__regs__v0] 
            = __Vdlyvval__cpu_top__DOT__rf_u__DOT__regs__v0;
    }
    vlTOPp->dbg_x1 = vlTOPp->cpu_top__DOT__rf_u__DOT__regs
        [1U];
    vlTOPp->dbg_x2 = vlTOPp->cpu_top__DOT__rf_u__DOT__regs
        [2U];
    vlTOPp->dbg_x3 = vlTOPp->cpu_top__DOT__rf_u__DOT__regs
        [3U];
    vlTOPp->pc_dbg = vlTOPp->cpu_top__DOT__pc;
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
