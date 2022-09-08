/**************************************************************************/
/*                                                                        */
/*       Copyright (c) Microsoft Corporation. All rights reserved.        */
/*                                                                        */
/*       This software is licensed under the Microsoft Software License   */
/*       Terms for Microsoft Azure RTOS. Full text of the license can be  */
/*       found in the LICENSE file at https://aka.ms/AzureRTOS_EULA       */
/*       and in the root directory of this software.                      */
/*                                                                        */
/**************************************************************************/


/**************************************************************************/
/**************************************************************************/
/**                                                                       */
/** ThreadX Component                                                     */
/**                                                                       */
/**   Initialize                                                          */
/**                                                                       */
/**************************************************************************/
/**************************************************************************/


    .text
    .align 3
/**************************************************************************/
/*                                                                        */
/*  FUNCTION                                               RELEASE        */
/*                                                                        */
/*    _tx_initialize_low_level                             ARMv8-A        */
/*                                                           6.1.10       */
/*  AUTHOR                                                                */
/*                                                                        */
/*    William E. Lamie, Microsoft Corporation                             */
/*                                                                        */
/*  DESCRIPTION                                                           */
/*                                                                        */
/*    This function is responsible for any low-level processor            */
/*    initialization, including setting up interrupt vectors, setting     */
/*    up a periodic timer interrupt source, saving the system stack       */
/*    pointer for use in ISR processing later, and finding the first      */
/*    available RAM memory address for tx_application_define.             */
/*                                                                        */
/*  INPUT                                                                 */
/*                                                                        */
/*    None                                                                */
/*                                                                        */
/*  OUTPUT                                                                */
/*                                                                        */
/*    None                                                                */
/*                                                                        */
/*  CALLS                                                                 */
/*                                                                        */
/*    None                                                                */
/*                                                                        */
/*  CALLED BY                                                             */
/*                                                                        */
/*    _tx_initialize_kernel_enter           ThreadX entry function        */
/*                                                                        */
/*  RELEASE HISTORY                                                       */
/*                                                                        */
/*    DATE              NAME                      DESCRIPTION             */
/*                                                                        */
/*  09-30-2020     William E. Lamie         Initial Version 6.1           */
/*  01-31-2022     Andres Mlinar            Updated comments,             */
/*                                            resulting in version 6.1.10 */
/*                                                                        */
/**************************************************************************/
// VOID   _tx_initialize_low_level(VOID)
// {
    .global  _tx_initialize_low_level
    .type    _tx_initialize_low_level, @function
_tx_initialize_low_level:

    // Mquestion 为什么要关闭
    //1 Mstep 作用:关闭当前核的IRQ和FIQ中断，
    MSR     DAIFSet, 0x3                        // Lockout interrupts 


    /* Save the system stack pointer.  */
    // _tx_thread_system_stack_ptr = (VOID_PTR) (sp);
    // 
    //2 Mstep 把SP地址保存到_tx_thread_system_stack_ptr中
    LDR     x0, =_tx_thread_system_stack_ptr    // Pickup address of system stack ptr
    MOV     x1, sp                              // Pickup SP
    // x1 - 15
    // Mquestion 没搞懂，需要再搞明白
    SUB     x1, x1, #15                         //
    // 是x1值为16位对齐的地址
    BIC     x1, x1, #0xF                        // Get 16-bit alignment
    STR     x1, [x0]                            // Store system stack

    /* Save the first available memory address.  */
    // Image$$ZI$$Limit 表示的是ZI区在RAM里面的结束地址后面的一个地址。
    // _tx_initialize_unused_memory =  (VOID_PTR) Image$$ZI$$Limit;
    // 
    LDR     x0, =_tx_initialize_unused_memory   // Pickup address of unused memory ptr
    LDR     x1, =__top_of_ram                   // Pickup unused memory address
    LDR     x1, [x1]                            //
    STR     x1, [x0]                            // Store unused memory address

    /* Done, return to caller.  */

    RET                                         // Return to caller
// } 
