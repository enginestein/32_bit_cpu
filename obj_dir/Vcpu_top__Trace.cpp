// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_vcd_c.h"
#include "Vcpu_top__Syms.h"


void Vcpu_top::traceChgTop0(void* userp, VerilatedVcd* tracep) {
    Vcpu_top__Syms* __restrict vlSymsp = static_cast<Vcpu_top__Syms*>(userp);
    Vcpu_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Variables
    if (VL_UNLIKELY(!vlSymsp->__Vm_activity)) return;
    // Body
    {
        vlTOPp->traceChgSub0(userp, tracep);
    }
}

void Vcpu_top::traceChgSub0(void* userp, VerilatedVcd* tracep) {
    Vcpu_top__Syms* __restrict vlSymsp = static_cast<Vcpu_top__Syms*>(userp);
    Vcpu_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    vluint32_t* const oldp = tracep->oldp(vlSymsp->__Vm_baseCode + 1);
    if (false && oldp) {}  // Prevent unused
    // Body
    {
        if (VL_UNLIKELY(vlTOPp->__Vm_traceActivity[1U])) {
            tracep->chgIData(oldp+0,(vlTOPp->cpu_top__DOT__pc),32);
            tracep->chgIData(oldp+1,(vlTOPp->cpu_top__DOT__instr),32);
            tracep->chgCData(oldp+2,((0x7fU & vlTOPp->cpu_top__DOT__instr)),7);
            tracep->chgCData(oldp+3,((0x1fU & (vlTOPp->cpu_top__DOT__instr 
                                               >> 7U))),5);
            tracep->chgCData(oldp+4,((0x1fU & (vlTOPp->cpu_top__DOT__instr 
                                               >> 0xfU))),5);
            tracep->chgCData(oldp+5,((0x1fU & (vlTOPp->cpu_top__DOT__instr 
                                               >> 0x14U))),5);
            tracep->chgCData(oldp+6,((7U & (vlTOPp->cpu_top__DOT__instr 
                                            >> 0xcU))),3);
            tracep->chgCData(oldp+7,((0x7fU & (vlTOPp->cpu_top__DOT__instr 
                                               >> 0x19U))),7);
            tracep->chgIData(oldp+8,(((0xfffff000U 
                                       & ((- (IData)(
                                                     (1U 
                                                      & (vlTOPp->cpu_top__DOT__instr 
                                                         >> 0x1fU)))) 
                                          << 0xcU)) 
                                      | (0xfffU & (vlTOPp->cpu_top__DOT__instr 
                                                   >> 0x14U)))),32);
            tracep->chgIData(oldp+9,((((0U == (0x1fU 
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
                                         | (0xfffU 
                                            & (vlTOPp->cpu_top__DOT__instr 
                                               >> 0x14U))))),32);
            tracep->chgIData(oldp+10,(((0U == (0x1fU 
                                               & (vlTOPp->cpu_top__DOT__instr 
                                                  >> 0xfU)))
                                        ? 0U : vlTOPp->cpu_top__DOT__rf_u__DOT__regs
                                       [(0x1fU & (vlTOPp->cpu_top__DOT__instr 
                                                  >> 0xfU))])),32);
            tracep->chgIData(oldp+11,(((0U == (0x1fU 
                                               & (vlTOPp->cpu_top__DOT__instr 
                                                  >> 0x14U)))
                                        ? 0U : vlTOPp->cpu_top__DOT__rf_u__DOT__regs
                                       [(0x1fU & (vlTOPp->cpu_top__DOT__instr 
                                                  >> 0x14U))])),32);
            tracep->chgBit(oldp+12,(vlTOPp->cpu_top__DOT__reg_we));
            tracep->chgIData(oldp+13,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[0]),32);
            tracep->chgIData(oldp+14,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[1]),32);
            tracep->chgIData(oldp+15,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[2]),32);
            tracep->chgIData(oldp+16,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[3]),32);
            tracep->chgIData(oldp+17,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[4]),32);
            tracep->chgIData(oldp+18,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[5]),32);
            tracep->chgIData(oldp+19,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[6]),32);
            tracep->chgIData(oldp+20,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[7]),32);
            tracep->chgIData(oldp+21,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[8]),32);
            tracep->chgIData(oldp+22,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[9]),32);
            tracep->chgIData(oldp+23,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[10]),32);
            tracep->chgIData(oldp+24,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[11]),32);
            tracep->chgIData(oldp+25,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[12]),32);
            tracep->chgIData(oldp+26,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[13]),32);
            tracep->chgIData(oldp+27,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[14]),32);
            tracep->chgIData(oldp+28,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[15]),32);
            tracep->chgIData(oldp+29,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[16]),32);
            tracep->chgIData(oldp+30,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[17]),32);
            tracep->chgIData(oldp+31,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[18]),32);
            tracep->chgIData(oldp+32,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[19]),32);
            tracep->chgIData(oldp+33,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[20]),32);
            tracep->chgIData(oldp+34,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[21]),32);
            tracep->chgIData(oldp+35,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[22]),32);
            tracep->chgIData(oldp+36,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[23]),32);
            tracep->chgIData(oldp+37,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[24]),32);
            tracep->chgIData(oldp+38,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[25]),32);
            tracep->chgIData(oldp+39,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[26]),32);
            tracep->chgIData(oldp+40,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[27]),32);
            tracep->chgIData(oldp+41,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[28]),32);
            tracep->chgIData(oldp+42,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[29]),32);
            tracep->chgIData(oldp+43,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[30]),32);
            tracep->chgIData(oldp+44,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[31]),32);
        }
        tracep->chgBit(oldp+45,(vlTOPp->clk));
        tracep->chgBit(oldp+46,(vlTOPp->reset));
        tracep->chgIData(oldp+47,(vlTOPp->pc_dbg),32);
        tracep->chgIData(oldp+48,(vlTOPp->dbg_x1),32);
        tracep->chgIData(oldp+49,(vlTOPp->dbg_x2),32);
        tracep->chgIData(oldp+50,(vlTOPp->dbg_x3),32);
    }
}

void Vcpu_top::traceCleanup(void* userp, VerilatedVcd* /*unused*/) {
    Vcpu_top__Syms* __restrict vlSymsp = static_cast<Vcpu_top__Syms*>(userp);
    Vcpu_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    {
        vlSymsp->__Vm_activity = false;
        vlTOPp->__Vm_traceActivity[0U] = 0U;
        vlTOPp->__Vm_traceActivity[1U] = 0U;
    }
}
