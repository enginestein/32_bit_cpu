// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_vcd_c.h"
#include "Vcpu_top__Syms.h"


//======================

void Vcpu_top::trace(VerilatedVcdC* tfp, int, int) {
    tfp->spTrace()->addInitCb(&traceInit, __VlSymsp);
    traceRegister(tfp->spTrace());
}

void Vcpu_top::traceInit(void* userp, VerilatedVcd* tracep, uint32_t code) {
    // Callback from tracep->open()
    Vcpu_top__Syms* __restrict vlSymsp = static_cast<Vcpu_top__Syms*>(userp);
    if (!Verilated::calcUnusedSigs()) {
        VL_FATAL_MT(__FILE__, __LINE__, __FILE__,
                        "Turning on wave traces requires Verilated::traceEverOn(true) call before time 0.");
    }
    vlSymsp->__Vm_baseCode = code;
    tracep->module(vlSymsp->name());
    tracep->scopeEscape(' ');
    Vcpu_top::traceInitTop(vlSymsp, tracep);
    tracep->scopeEscape('.');
}

//======================


void Vcpu_top::traceInitTop(void* userp, VerilatedVcd* tracep) {
    Vcpu_top__Syms* __restrict vlSymsp = static_cast<Vcpu_top__Syms*>(userp);
    Vcpu_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    {
        vlTOPp->traceInitSub0(userp, tracep);
    }
}

void Vcpu_top::traceInitSub0(void* userp, VerilatedVcd* tracep) {
    Vcpu_top__Syms* __restrict vlSymsp = static_cast<Vcpu_top__Syms*>(userp);
    Vcpu_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    const int c = vlSymsp->__Vm_baseCode;
    if (false && tracep && c) {}  // Prevent unused
    // Body
    {
        tracep->declBit(c+46,"clk", false,-1);
        tracep->declBit(c+47,"reset", false,-1);
        tracep->declBus(c+48,"pc_dbg", false,-1, 31,0);
        tracep->declBus(c+49,"dbg_x1", false,-1, 31,0);
        tracep->declBus(c+50,"dbg_x2", false,-1, 31,0);
        tracep->declBus(c+51,"dbg_x3", false,-1, 31,0);
        tracep->declBit(c+46,"cpu_top clk", false,-1);
        tracep->declBit(c+47,"cpu_top reset", false,-1);
        tracep->declBus(c+48,"cpu_top pc_dbg", false,-1, 31,0);
        tracep->declBus(c+49,"cpu_top dbg_x1", false,-1, 31,0);
        tracep->declBus(c+50,"cpu_top dbg_x2", false,-1, 31,0);
        tracep->declBus(c+51,"cpu_top dbg_x3", false,-1, 31,0);
        tracep->declBus(c+1,"cpu_top pc", false,-1, 31,0);
        tracep->declBus(c+2,"cpu_top instr", false,-1, 31,0);
        tracep->declBus(c+3,"cpu_top opcode", false,-1, 6,0);
        tracep->declBus(c+4,"cpu_top rd", false,-1, 4,0);
        tracep->declBus(c+5,"cpu_top rs1", false,-1, 4,0);
        tracep->declBus(c+6,"cpu_top rs2", false,-1, 4,0);
        tracep->declBus(c+7,"cpu_top funct3", false,-1, 2,0);
        tracep->declBus(c+8,"cpu_top funct7", false,-1, 6,0);
        tracep->declBus(c+9,"cpu_top imm", false,-1, 31,0);
        tracep->declBus(c+10,"cpu_top alu_out", false,-1, 31,0);
        tracep->declBus(c+11,"cpu_top rs1_val", false,-1, 31,0);
        tracep->declBus(c+12,"cpu_top rs2_val", false,-1, 31,0);
        tracep->declBit(c+13,"cpu_top reg_we", false,-1);
        tracep->declBit(c+46,"cpu_top pc_u clk", false,-1);
        tracep->declBit(c+47,"cpu_top pc_u reset", false,-1);
        tracep->declBus(c+1,"cpu_top pc_u pc_out", false,-1, 31,0);
        tracep->declBus(c+1,"cpu_top imem_u addr", false,-1, 31,0);
        tracep->declBus(c+2,"cpu_top imem_u instr", false,-1, 31,0);
        tracep->declBus(c+2,"cpu_top dec_u instr", false,-1, 31,0);
        tracep->declBus(c+3,"cpu_top dec_u opcode", false,-1, 6,0);
        tracep->declBus(c+4,"cpu_top dec_u rd", false,-1, 4,0);
        tracep->declBus(c+5,"cpu_top dec_u rs1", false,-1, 4,0);
        tracep->declBus(c+6,"cpu_top dec_u rs2", false,-1, 4,0);
        tracep->declBus(c+7,"cpu_top dec_u funct3", false,-1, 2,0);
        tracep->declBus(c+8,"cpu_top dec_u funct7", false,-1, 6,0);
        tracep->declBus(c+2,"cpu_top imm_u instr", false,-1, 31,0);
        tracep->declBus(c+9,"cpu_top imm_u imm", false,-1, 31,0);
        tracep->declBus(c+11,"cpu_top alu_u a", false,-1, 31,0);
        tracep->declBus(c+9,"cpu_top alu_u b", false,-1, 31,0);
        tracep->declBus(c+10,"cpu_top alu_u y", false,-1, 31,0);
        tracep->declBit(c+46,"cpu_top rf_u clk", false,-1);
        tracep->declBit(c+13,"cpu_top rf_u we", false,-1);
        tracep->declBus(c+5,"cpu_top rf_u rs1", false,-1, 4,0);
        tracep->declBus(c+6,"cpu_top rf_u rs2", false,-1, 4,0);
        tracep->declBus(c+4,"cpu_top rf_u rd", false,-1, 4,0);
        tracep->declBus(c+10,"cpu_top rf_u wd", false,-1, 31,0);
        tracep->declBus(c+11,"cpu_top rf_u rd1", false,-1, 31,0);
        tracep->declBus(c+12,"cpu_top rf_u rd2", false,-1, 31,0);
        tracep->declBus(c+49,"cpu_top rf_u dbg_x1", false,-1, 31,0);
        tracep->declBus(c+50,"cpu_top rf_u dbg_x2", false,-1, 31,0);
        tracep->declBus(c+51,"cpu_top rf_u dbg_x3", false,-1, 31,0);
        {int i; for (i=0; i<32; i++) {
                tracep->declBus(c+14+i*1,"cpu_top rf_u regs", true,(i+0), 31,0);}}
    }
}

void Vcpu_top::traceRegister(VerilatedVcd* tracep) {
    // Body
    {
        tracep->addFullCb(&traceFullTop0, __VlSymsp);
        tracep->addChgCb(&traceChgTop0, __VlSymsp);
        tracep->addCleanupCb(&traceCleanup, __VlSymsp);
    }
}

void Vcpu_top::traceFullTop0(void* userp, VerilatedVcd* tracep) {
    Vcpu_top__Syms* __restrict vlSymsp = static_cast<Vcpu_top__Syms*>(userp);
    Vcpu_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    {
        vlTOPp->traceFullSub0(userp, tracep);
    }
}

void Vcpu_top::traceFullSub0(void* userp, VerilatedVcd* tracep) {
    Vcpu_top__Syms* __restrict vlSymsp = static_cast<Vcpu_top__Syms*>(userp);
    Vcpu_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    vluint32_t* const oldp = tracep->oldp(vlSymsp->__Vm_baseCode);
    if (false && oldp) {}  // Prevent unused
    // Body
    {
        tracep->fullIData(oldp+1,(vlTOPp->cpu_top__DOT__pc),32);
        tracep->fullIData(oldp+2,(vlTOPp->cpu_top__DOT__instr),32);
        tracep->fullCData(oldp+3,((0x7fU & vlTOPp->cpu_top__DOT__instr)),7);
        tracep->fullCData(oldp+4,((0x1fU & (vlTOPp->cpu_top__DOT__instr 
                                            >> 7U))),5);
        tracep->fullCData(oldp+5,((0x1fU & (vlTOPp->cpu_top__DOT__instr 
                                            >> 0xfU))),5);
        tracep->fullCData(oldp+6,((0x1fU & (vlTOPp->cpu_top__DOT__instr 
                                            >> 0x14U))),5);
        tracep->fullCData(oldp+7,((7U & (vlTOPp->cpu_top__DOT__instr 
                                         >> 0xcU))),3);
        tracep->fullCData(oldp+8,((0x7fU & (vlTOPp->cpu_top__DOT__instr 
                                            >> 0x19U))),7);
        tracep->fullIData(oldp+9,(((0xfffff000U & (
                                                   (- (IData)(
                                                              (1U 
                                                               & (vlTOPp->cpu_top__DOT__instr 
                                                                  >> 0x1fU)))) 
                                                   << 0xcU)) 
                                   | (0xfffU & (vlTOPp->cpu_top__DOT__instr 
                                                >> 0x14U)))),32);
        tracep->fullIData(oldp+10,((((0U == (0x1fU 
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
                                           >> 0x14U))))),32);
        tracep->fullIData(oldp+11,(((0U == (0x1fU & 
                                            (vlTOPp->cpu_top__DOT__instr 
                                             >> 0xfU)))
                                     ? 0U : vlTOPp->cpu_top__DOT__rf_u__DOT__regs
                                    [(0x1fU & (vlTOPp->cpu_top__DOT__instr 
                                               >> 0xfU))])),32);
        tracep->fullIData(oldp+12,(((0U == (0x1fU & 
                                            (vlTOPp->cpu_top__DOT__instr 
                                             >> 0x14U)))
                                     ? 0U : vlTOPp->cpu_top__DOT__rf_u__DOT__regs
                                    [(0x1fU & (vlTOPp->cpu_top__DOT__instr 
                                               >> 0x14U))])),32);
        tracep->fullBit(oldp+13,(vlTOPp->cpu_top__DOT__reg_we));
        tracep->fullIData(oldp+14,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[0]),32);
        tracep->fullIData(oldp+15,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[1]),32);
        tracep->fullIData(oldp+16,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[2]),32);
        tracep->fullIData(oldp+17,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[3]),32);
        tracep->fullIData(oldp+18,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[4]),32);
        tracep->fullIData(oldp+19,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[5]),32);
        tracep->fullIData(oldp+20,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[6]),32);
        tracep->fullIData(oldp+21,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[7]),32);
        tracep->fullIData(oldp+22,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[8]),32);
        tracep->fullIData(oldp+23,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[9]),32);
        tracep->fullIData(oldp+24,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[10]),32);
        tracep->fullIData(oldp+25,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[11]),32);
        tracep->fullIData(oldp+26,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[12]),32);
        tracep->fullIData(oldp+27,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[13]),32);
        tracep->fullIData(oldp+28,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[14]),32);
        tracep->fullIData(oldp+29,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[15]),32);
        tracep->fullIData(oldp+30,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[16]),32);
        tracep->fullIData(oldp+31,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[17]),32);
        tracep->fullIData(oldp+32,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[18]),32);
        tracep->fullIData(oldp+33,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[19]),32);
        tracep->fullIData(oldp+34,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[20]),32);
        tracep->fullIData(oldp+35,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[21]),32);
        tracep->fullIData(oldp+36,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[22]),32);
        tracep->fullIData(oldp+37,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[23]),32);
        tracep->fullIData(oldp+38,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[24]),32);
        tracep->fullIData(oldp+39,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[25]),32);
        tracep->fullIData(oldp+40,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[26]),32);
        tracep->fullIData(oldp+41,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[27]),32);
        tracep->fullIData(oldp+42,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[28]),32);
        tracep->fullIData(oldp+43,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[29]),32);
        tracep->fullIData(oldp+44,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[30]),32);
        tracep->fullIData(oldp+45,(vlTOPp->cpu_top__DOT__rf_u__DOT__regs[31]),32);
        tracep->fullBit(oldp+46,(vlTOPp->clk));
        tracep->fullBit(oldp+47,(vlTOPp->reset));
        tracep->fullIData(oldp+48,(vlTOPp->pc_dbg),32);
        tracep->fullIData(oldp+49,(vlTOPp->dbg_x1),32);
        tracep->fullIData(oldp+50,(vlTOPp->dbg_x2),32);
        tracep->fullIData(oldp+51,(vlTOPp->dbg_x3),32);
    }
}
