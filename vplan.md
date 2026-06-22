# Detailed Verification Plan (VPlan)

This document details the test scenarios designed to verify the 64-bit Timer IP Core. The test plan is structured into four main functional categories.

---

## 1. APB Protocol & Error Handling
| ID | Feature Description | Test Scenario | Expected Result | Testcase |
| :--- | :--- | :--- | :--- | :--- |
| **APB_01** | Basic APB Read/Write Protocol.  | Perform a basic Write and subsequent Read to the TCR register.  | `tim_pready` asserts with a 1-cycle delay.  Read data exactly matches the written data.  | `apb_protocol_chk`  |
| **APB_02** | Back-to-back Access.  | Perform 3 consecutive Writes and Reads to 3 different registers without any idle cycles.  | Bus does not hang; `tim_pready` responds correctly for each access phase.  | `apb_multiple_access`  |
| **APB_03** | Byte-Strobe Access.  | Write to TCMP0 asserting `tim_pstrb` bits individually (4'b0001, 4'b0010, etc.).  | Only the corresponding single byte in the register is updated; other bytes remain unchanged.  | `byte_access_chk`  |
| **APB_04** | Invalid Divider Value Error.  | Write an invalid value `div_val` = 4'b1001 (9) to the TCR address.  | `tim_pslverr` asserts to 1 simultaneously with `tim_pready`.  The register data is not overwritten.  | `error_logic_chk`  |
| **APB_05** | Config Change While Running Error.  | Set `timer_en` = 1, then send a Write command attempting to change `div_en` or `div_val`.  | The Write transaction is blocked, `tim_pslverr` asserts to 1.  | `error_logic_chk`  |
| **APB_06** | Error Recovery & Safe Ignore.  | 1. Trigger APB_04 error, immediately followed by a valid Write. 2. Send a Write command to an unmapped (reserved) address.  | 1. The subsequent valid transaction succeeds, `tim_pslverr` de-asserts. 2. Unmapped access is safely ignored (RAZ/WI) without asserting `tim_pslverr` or hanging the bus.  | `error_logic_chk`  |

---

## 2. Register Access Checks
| ID | Feature Description | Test Scenario | Expected Result | Testcase |
| :--- | :--- | :--- | :--- | :--- |
| **REG_01** | Register Reset Values.  | Assert system reset (`sys_rst_n` = 0) and perform APB Read to all mapped registers.  | All returned data (`tim_prdata`) must match their specified default values (e.g., TCR = 0x0100, TCMPx = 0xFFFFFFFF).  | `reg_init_chk`  |
| **REG_02** | Read/Write (RW) Full Access.  | Write 0x5555_5555 then 0xAAAA_AAAA to all RW registers and read back immediately.  | Read data must perfectly match the written values for the RW bits.  | `reg_rw_chk`  |
| **REG_03** | Read-Only & Reserved Bits.  | Write 32'hFFFF_FFFF to all registers and read back.  | Reserved bits and RO bits must remain 0 and not be overwritten.  | `reg_reserved_chk`  |
| **REG_04** | One-Hot Data Check.  | Write a walking-1 pattern (e.g., 0x01, 0x02, 0x04...) to registers.  | Data read back matches exactly, ensuring no adjacent bits are short-circuited.  | `reg_1hot_chk`  |
| **REG_05** | Write-1-to-Clear (W1C).  | Wait for `tisr_int_st` = 1, then Write 0 to TISR, followed by Write 1 to TISR.  | Status is 1, remains 1 after Write 0, and clears to 0 after Write 1.  | `interrupt_chk`  |

---

## 3. Timer Core Logic
| ID | Feature Description | Test Scenario | Expected Result | Testcase |
| :--- | :--- | :--- | :--- | :--- |
| **CNT_01** | Basic Counting & Overflow.  | Write `timer_en` = 1, `div_en` = 0, preload TDR0/1 to near max, and wait.  | Counter increments by exactly 1 on every system clock edge.  Upon reaching max 64-bit value, it seamlessly wraps around to 0.  | `cnt_counting_chk`  |
| **CNT_02** | Prescaler / Control Mode (`div_val`).  | Set `timer_en` = 1, `div_en` = 1, configure `div_val` to different valid values (e.g., div-2, div-256) and observe.  | For `div_val` = N, counter increments by 1 exactly every 2^N clock cycles.  `real_count_tick` asserts accordingly.  | `cnt_ctrl_chk`  |
| **CNT_03** | Hardware Clear on Disable Edge.  | Set `timer_en` = 1, let counter run, then clear `timer_en` = 0 (falling edge) and read TDR.  | Upon detecting H->L transition, the 64-bit counter is immediately cleared to 0 by hardware.  | `cnt_ctrl_chk`  |
| **CNT_04** | Halt Mode in Debug.  | Assert `dbg_mode` = 1, start timer, write `halt_req` = 1, wait, then write `halt_req` = 0.  | Counter freezes exactly at current value, `halt_ack` asserts to 1.  Counter resumes from exact frozen value without skipping division beats.  | `debug_halt_chk`  |
| **CNT_05** | Priority: Halt vs HW Clear.  | Enter Halt mode (`dbg_mode` = 1, `halt_req` = 1), then clear `timer_en` = 0 (falling edge).  | Halt has highest priority.  Counter remains frozen and is NOT cleared to 0 despite the falling edge.  | `debug_halt_chk`  |
| **CNT_06** | Prescaler Sweep & Max Div Rate.  | Sequentially write valid values to `div_val`. Configure max rate (div-256), wait 600 clock cycles.  | All values successfully written/read.  Counter increments by exactly 2 (since 512 <= 600 < 768 cycles).  | `cnt_divider_chk`  |

---

## 4. Interrupt Management
| ID | Feature Description | Test Scenario | Expected Result | Testcase |
| :--- | :--- | :--- | :--- | :--- |
| **INT_01** | Hardware Interrupt Generation.  | Write target to TCMP, start timer, and wait until count equals compare value.  | `match_event` pulse is generated for exactly 1 clock cycle.  `TISR.int_st` is set to 1 by hardware.  Counter continues normally.  | `interrupt_chk`  |
| **INT_02** | Interrupt Enable & Masking.  | Ensure `int_st` = 1. Write `int_en` = 1 and check `tim_int`. Then write `int_en` = 0 and check again.  | `tim_int` asserts to High.  Then `tim_int` de-asserts to Low (masked), but `TISR.int_st` remains 1 inside register.  | `interrupt_chk`  |
| **INT_03** | Interrupt Status Clear (W1C).  | While `int_st` = 1: Write 0 to TISR, then Write 1 to TISR.  | `TISR.int_st` remains 1 (Write 0 is ignored).  `TISR.int_st` drops to 0 and `tim_int` output also drops.  | `interrupt_chk`  |
| **INT_04** | Set vs. Clear Priority.  | Time stimulus so software W1C command occurs on exact same clock cycle as hardware `match_event` pulse.  | Software Clear has higher priority.  `TISR.int_st` is successfully cleared to 0 and does not get stuck at 1.  | `interrupt_chk`  |