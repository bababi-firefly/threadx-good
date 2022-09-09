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
/**   Timer                                                               */
/**                                                                       */
/**************************************************************************/
/**************************************************************************/


    .text
    .align 3
/**************************************************************************/
/*                                                                        */
/*  FUNCTION                                               RELEASE        */
/*                                                                        */
/*    _tx_timer_interrupt                                  ARMv8-A        */
/*                                                           6.1.10       */
/*  AUTHOR                                                                */
/*                                                                        */
/*    William E. Lamie, Microsoft Corporation                             */
/*                                                                        */
/*  DESCRIPTION                                                           */
/*                                                                        */
/*    This function processes the hardware timer interrupt.  This         */
/*    processing includes incrementing the system clock and checking for  */
/*    time slice and/or timer expiration.  If either is found, the        */
/*    interrupt context save/restore functions are called along with the  */
/*    expiration functions.                                               */
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
/*    _tx_timer_expiration_process          Timer expiration processing   */
/*    _tx_thread_time_slice                 Time slice interrupted thread */
/*                                                                        */
/*  CALLED BY                                                             */
/*                                                                        */
/*    interrupt vector                                                    */
/*                                                                        */
/*  RELEASE HISTORY                                                       */
/*                                                                        */
/*    DATE              NAME                      DESCRIPTION             */
/*                                                                        */
/*  09-30-2020     William E. Lamie         Initial Version 6.1           */
/*                                                                        */
/**************************************************************************/
// VOID   _tx_timer_interrupt(VOID)
// {
    .global _tx_timer_interrupt
    .type   _tx_timer_interrupt, @function
_tx_timer_interrupt:

    /* Upon entry to this routine, it is assumed that context save has already
       been called, and therefore the compiler scratch registers are available
       for use.  */

    /* Increment the system clock.  */
    //1 Mstep 系统滴答时间++ _tx_timer_system_clock++; // 

    LDR     x1, =_tx_timer_system_clock         // Pickup address of system clock
    LDR     w0, [x1, #0]                        // Pickup system clock
    ADD     w0, w0, #1                          // Increment system clock
    STR     w0, [x1, #0]                        // Store new system clock

    /* Test for time-slice expiration.  */
    /* if (_tx_timer_time_slice)
    { */
    //2 Mstep 判断是否还有剩余的时间片
    LDR     x3, =_tx_timer_time_slice           // Pickup address of time-slice
    LDR     w2, [x3, #0]                        // Pickup time-slice
    CMP     w2, #0                              // Is it non-active? 
    //3 Mstep 判断_tx_timer_time_slice是否激活，如果不为0表明线程使用了时间片，需要在中断中进行--处理。
    BEQ     __tx_timer_no_time_slice            // Yes, skip time-slice processing

       /* Decrement the time_slice.  */
       /* _tx_timer_time_slice--;  */
    //4 Mstep 时间片有剩余的话 --
    SUB     w2, w2, #1                          // Decrement the time-slice
    STR     w2, [x3, #0]                        // Store new time-slice value // 更新 _tx_timer_time_slice

       /* Check for expiration.  */
       /* if (__tx_timer_time_slice == 0)  */
    //5 Msetp --之后判断是否还有剩余的时间片
    CMP     w2, #0                              // Has it expired?
    //6 Msetp 时间片未用完，直接跳转
    BNE     __tx_timer_no_time_slice            // No, skip expiration processing

       /* Set the time-slice expired flag.  */
       /* _tx_timer_expired_time_slice =  TX_TRUE;  */

    //7 Mstep 时间片耗尽了，设置耗尽状态为TRUE
    LDR     x3, =_tx_timer_expired_time_slice   // Pickup address of expired flag
    MOV     w0, #1                              // Build expired value
    STR     w0, [x3, #0]                        // Set time-slice expiration flag

    /* } */

// 未耗尽 或者 没启用时间片的会到这里。
__tx_timer_no_time_slice:

    /* Test for timer expiration.  */
    // if (*_tx_timer_current_ptr)
    // {
    // 检查_tx_timer_current_ptr下是否有定时器
    LDR     x1, =_tx_timer_current_ptr          // Pickup current timer pointer addr
    LDR     x0, [x1, #0]                        // Pickup current timer
    LDR     x2, [x0, #0]                        // Pickup timer list entry
    CMP     x2, #0                              // Is there anything in the list?
    BEQ     __tx_timer_no_timer                 // No, just increment the timer   // 如果没有定时器，直接跳转。

        /* Set expiration flag.  */
        // _tx_timer_expired =  TX_TRUE;
    
    // 设置 _tx_timer_expired 为True
    // 如果有，设置定时器超时。
    LDR     x3, =_tx_timer_expired              // Pickup expiration flag address
    MOV     w2, #1                              // Build expired value
    STR     w2, [x3, #0]                        // Set expired flag
    B       __tx_timer_done                     // Finished timer processing

    // }
    // else
    // {

// 没有定时器超时就跳转到下一个timer，当然也会循环跳到start位置
__tx_timer_no_timer:

        /* No timer expired, increment the timer pointer.  */
        // _tx_timer_current_ptr++;

    ADD     x0, x0, #8                          // Move to next timer

        /* Check for wrap-around.  */
        // if (_tx_timer_current_ptr == _tx_timer_list_end)

    LDR     x3, =_tx_timer_list_end             // Pickup addr of timer list end
    LDR     x2, [x3, #0]                        // Pickup list end
    CMP     x0, x2                              // Are we at list end?
    BNE     __tx_timer_skip_wrap                // No, skip wrap-around logic

            /* Wrap to beginning of list.  */
            // _tx_timer_current_ptr =  _tx_timer_list_start;

    LDR     x3, =_tx_timer_list_start           // Pickup addr of timer list start
    LDR     x0, [x3, #0]                        // Set current pointer to list start

// 将新的timer指针保存到 _tx_timer_current_ptr
__tx_timer_skip_wrap:

    STR     x0, [x1, #0]                        // Store new current timer pointer
    // }

__tx_timer_done: // 定时器检查结束


    /* See if anything has expired.  */
    // if ((_tx_timer_expired_time_slice) || (_tx_timer_expired))
    //{

    LDR     x3, =_tx_timer_expired_time_slice   // Pickup addr of expired flag
    LDR     w2, [x3, #0]                        // Pickup time-slice expired flag
    // 判断是否时间片用尽，True为用尽
    CMP     w2, #0                              // Did a time-slice expire?
    BNE     __tx_something_expired              // If non-zero, time-slice expired
    LDR     x1, =_tx_timer_expired              // Pickup addr of other expired flag
    LDR     w0, [x1, #0]                        // Pickup timer expired flag
    CMP     w0, #0                              // Did a timer expire?
    // 时间片没有用尽没有超时会走 __tx_timer_nothing_expired
    BEQ     __tx_timer_nothing_expired          // No, nothing expired

__tx_something_expired: // 有定时器超时会到这里


    STP     x29, x30, [sp, #-16]!               // Save x29 (frame pointer), x30 (link register)

    /* Did a timer expire?  */
    // if (_tx_timer_expired)
    // {

    LDR     x1, =_tx_timer_expired              // Pickup addr of expired flag
    LDR     w0, [x1, #0]                        // Pickup timer expired flag
    CMP     w0, #0                              // Check for timer expiration
    BEQ     __tx_timer_dont_activate            // If not set, skip timer activation

        /* Process timer expiration.  */
        // _tx_timer_expiration_process();
    
    // 调用定时器超时处理函数处理超时的定时器 
    BL      _tx_timer_expiration_process        // Call the timer expiration handling routine

    // }
__tx_timer_dont_activate:

    /* Did time slice expire?  */
    // if (_tx_timer_expired_time_slice)
    // {
    // 检查时间片是否用尽
    LDR     x3, =_tx_timer_expired_time_slice   // Pickup addr of time-slice expired
    LDR     w2, [x3, #0]                        // Pickup the actual flag
    CMP     w2, #0                              // See if the flag is set
    BEQ     __tx_timer_not_ts_expiration        // No, skip time-slice processing

        /* Time slice interrupted thread.  */
        // _tx_thread_time_slice();
    // 调用线程时间片处理函数
    BL      _tx_thread_time_slice               // Call time-slice processing

    // }/

__tx_timer_not_ts_expiration:

    LDP     x29, x30, [sp], #16                 // Recover x29, x30
    // }

__tx_timer_nothing_expired:

    RET                                         // Return to caller

// }
