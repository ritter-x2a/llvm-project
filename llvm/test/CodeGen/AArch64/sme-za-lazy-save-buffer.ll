; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py UTC_ARGS: --version 4
; RUN: llc -mtriple=aarch64-linux-gnu -mattr=+sme2 < %s | FileCheck %s

define i32 @no_tpidr2_save_required() "aarch64_inout_za" {
; CHECK-LABEL: no_tpidr2_save_required:
; CHECK:       // %bb.0: // %entry
; CHECK-NEXT:    mov w0, #42 // =0x2a
; CHECK-NEXT:    ret
entry:
  ret i32 42
}

define float @multi_bb_stpidr2_save_required(i32 %a, float %b, float %c) "aarch64_inout_za" {
; CHECK-LABEL: multi_bb_stpidr2_save_required:
; CHECK:       // %bb.0:
; CHECK-NEXT:    stp x29, x30, [sp, #-16]! // 16-byte Folded Spill
; CHECK-NEXT:    mov x29, sp
; CHECK-NEXT:    sub sp, sp, #16
; CHECK-NEXT:    .cfi_def_cfa w29, 16
; CHECK-NEXT:    .cfi_offset w30, -8
; CHECK-NEXT:    .cfi_offset w29, -16
; CHECK-NEXT:    rdsvl x8, #1
; CHECK-NEXT:    mov x9, sp
; CHECK-NEXT:    msub x8, x8, x8, x9
; CHECK-NEXT:    mov sp, x8
; CHECK-NEXT:    stur x8, [x29, #-16]
; CHECK-NEXT:    sturh wzr, [x29, #-6]
; CHECK-NEXT:    stur wzr, [x29, #-4]
; CHECK-NEXT:    cbz w0, .LBB1_2
; CHECK-NEXT:  // %bb.1: // %use_b
; CHECK-NEXT:    fmov s1, #4.00000000
; CHECK-NEXT:    fadd s0, s0, s1
; CHECK-NEXT:    b .LBB1_5
; CHECK-NEXT:  .LBB1_2: // %use_c
; CHECK-NEXT:    fmov s0, s1
; CHECK-NEXT:    rdsvl x8, #1
; CHECK-NEXT:    sub x9, x29, #16
; CHECK-NEXT:    sturh w8, [x29, #-8]
; CHECK-NEXT:    msr TPIDR2_EL0, x9
; CHECK-NEXT:    bl cosf
; CHECK-NEXT:    smstart za
; CHECK-NEXT:    mrs x8, TPIDR2_EL0
; CHECK-NEXT:    sub x0, x29, #16
; CHECK-NEXT:    cbnz x8, .LBB1_4
; CHECK-NEXT:  // %bb.3: // %use_c
; CHECK-NEXT:    bl __arm_tpidr2_restore
; CHECK-NEXT:  .LBB1_4: // %use_c
; CHECK-NEXT:    msr TPIDR2_EL0, xzr
; CHECK-NEXT:  .LBB1_5: // %exit
; CHECK-NEXT:    mov sp, x29
; CHECK-NEXT:    ldp x29, x30, [sp], #16 // 16-byte Folded Reload
; CHECK-NEXT:    ret
  %cmp = icmp ne i32 %a, 0
  br i1 %cmp, label %use_b, label %use_c

use_b:
  %faddr = fadd float %b, 4.0
  br label %exit

use_c:
  %res2 = call float @llvm.cos.f32(float %c)
  br label %exit

exit:
  %ret = phi float [%faddr, %use_b], [%res2, %use_c]
  ret float %ret
}

define float @multi_bb_stpidr2_save_required_stackprobe(i32 %a, float %b, float %c) "aarch64_inout_za" "probe-stack"="inline-asm" "stack-probe-size"="65536" {
; CHECK-LABEL: multi_bb_stpidr2_save_required_stackprobe:
; CHECK:       // %bb.0:
; CHECK-NEXT:    stp x29, x30, [sp, #-16]! // 16-byte Folded Spill
; CHECK-NEXT:    mov x29, sp
; CHECK-NEXT:    str xzr, [sp, #-16]!
; CHECK-NEXT:    .cfi_def_cfa w29, 16
; CHECK-NEXT:    .cfi_offset w30, -8
; CHECK-NEXT:    .cfi_offset w29, -16
; CHECK-NEXT:    rdsvl x8, #1
; CHECK-NEXT:    mov x9, sp
; CHECK-NEXT:    msub x8, x8, x8, x9
; CHECK-NEXT:  .LBB2_1: // =>This Inner Loop Header: Depth=1
; CHECK-NEXT:    sub sp, sp, #16, lsl #12 // =65536
; CHECK-NEXT:    cmp sp, x8
; CHECK-NEXT:    b.le .LBB2_3
; CHECK-NEXT:  // %bb.2: // in Loop: Header=BB2_1 Depth=1
; CHECK-NEXT:    str xzr, [sp]
; CHECK-NEXT:    b .LBB2_1
; CHECK-NEXT:  .LBB2_3:
; CHECK-NEXT:    mov sp, x8
; CHECK-NEXT:    ldr xzr, [sp]
; CHECK-NEXT:    stur x8, [x29, #-16]
; CHECK-NEXT:    sturh wzr, [x29, #-6]
; CHECK-NEXT:    stur wzr, [x29, #-4]
; CHECK-NEXT:    cbz w0, .LBB2_5
; CHECK-NEXT:  // %bb.4: // %use_b
; CHECK-NEXT:    fmov s1, #4.00000000
; CHECK-NEXT:    fadd s0, s0, s1
; CHECK-NEXT:    b .LBB2_8
; CHECK-NEXT:  .LBB2_5: // %use_c
; CHECK-NEXT:    fmov s0, s1
; CHECK-NEXT:    rdsvl x8, #1
; CHECK-NEXT:    sub x9, x29, #16
; CHECK-NEXT:    sturh w8, [x29, #-8]
; CHECK-NEXT:    msr TPIDR2_EL0, x9
; CHECK-NEXT:    bl cosf
; CHECK-NEXT:    smstart za
; CHECK-NEXT:    mrs x8, TPIDR2_EL0
; CHECK-NEXT:    sub x0, x29, #16
; CHECK-NEXT:    cbnz x8, .LBB2_7
; CHECK-NEXT:  // %bb.6: // %use_c
; CHECK-NEXT:    bl __arm_tpidr2_restore
; CHECK-NEXT:  .LBB2_7: // %use_c
; CHECK-NEXT:    msr TPIDR2_EL0, xzr
; CHECK-NEXT:  .LBB2_8: // %exit
; CHECK-NEXT:    mov sp, x29
; CHECK-NEXT:    ldp x29, x30, [sp], #16 // 16-byte Folded Reload
; CHECK-NEXT:    ret
  %cmp = icmp ne i32 %a, 0
  br i1 %cmp, label %use_b, label %use_c

use_b:
  %faddr = fadd float %b, 4.0
  br label %exit

use_c:
  %res2 = call float @llvm.cos.f32(float %c)
  br label %exit

exit:
  %ret = phi float [%faddr, %use_b], [%res2, %use_c]
  ret float %ret
}

declare float @llvm.cos.f32(float)
