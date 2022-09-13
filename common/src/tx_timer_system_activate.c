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

#define TX_SOURCE_CODE

#ifndef TX_NO_TIMER

/* Include necessary system files.  */

#include "tx_api.h"
#include "tx_timer.h"


/**************************************************************************/
/*                                                                        */
/*  FUNCTION                                               RELEASE        */
/*                                                                        */
/*    _tx_timer_system_activate                           PORTABLE C      */
/*                                                           6.1          */
/*  AUTHOR                                                                */
/*                                                                        */
/*    William E. Lamie, Microsoft Corporation                             */
/*                                                                        */
/*  DESCRIPTION                                                           */
/*                                                                        */
/*    This function places the specified internal timer in the proper     */
/*    place in the timer expiration list.  If the timer is already active */
/*    this function does nothing.                                         */
/*                                                                        */
/*  INPUT                                                                 */
/*                                                                        */
/*    timer_ptr                         Pointer to timer control block    */
/*                                                                        */
/*  OUTPUT                                                                */
/*                                                                        */
/*    TX_SUCCESS                        Always returns success            */
/*                                                                        */
/*  CALLS                                                                 */
/*                                                                        */
/*    None                                                                */
/*                                                                        */
/*  CALLED BY                                                             */
/*                                                                        */
/*    _tx_thread_system_suspend         Thread suspend function           */
/*    _tx_thread_system_ni_suspend      Non-interruptable suspend thread  */
/*    _tx_timer_thread_entry            Timer thread processing           */
/*    _tx_timer_activate                Application timer activate        */
/*                                                                        */
/*  RELEASE HISTORY                                                       */
/*                                                                        */
/*    DATE              NAME                      DESCRIPTION             */
/*                                                                        */
/*  05-19-2020     William E. Lamie         Initial Version 6.0           */
/*  09-30-2020     Scott Larson             Modified comment(s), and      */
/*                                            opt out of function when    */
/*                                            TX_NO_TIMER is defined,     */
/*                                            resulting in version 6.1    */
/*                                                                        */
/**************************************************************************/
// 激活超时定时器，挂载到超时定时器链表中
VOID  _tx_timer_system_activate(TX_TIMER_INTERNAL *timer_ptr)
{

TX_TIMER_INTERNAL           **timer_list;
TX_TIMER_INTERNAL           *next_timer;
TX_TIMER_INTERNAL           *previous_timer;
ULONG                       delta;
ULONG                       remaining_ticks;
ULONG                       expiration_time;


    /* Pickup the remaining ticks.  */
    // 1 Msetp 获取剩余滴答值
    remaining_ticks =  timer_ptr -> tx_timer_internal_remaining_ticks;

    // 2 Mstep 剩余滴答值不为0
    /* Determine if there is a timer to activate.  */
    if (remaining_ticks != ((ULONG) 0))
    {

        /* Determine if the timer is set to wait forever.  */
        if (remaining_ticks != TX_WAIT_FOREVER) 
        {

            /* Valid timer activate request.  */

            /* Determine if the timer still needs activation.  */
            if (timer_ptr -> tx_timer_internal_list_head == TX_NULL) // 如果tx_timer_internal_list_head为空，则说明定时器不在链表里面
                                                                     //，也就是没有激活，否则定时器已经激活.head指向对应的_tx_timer_list中对应的某个链表头
            {

                /* Activate the timer.  */
                // 计算把它插入到的_tx_timer_list链表index
                /* Calculate the amount of time remaining for the timer.  */
                if (remaining_ticks > TX_TIMER_ENTRIES)
                {

                    /* Set expiration time to the maximum number of entries.  */
                    expiration_time =  TX_TIMER_ENTRIES - ((ULONG) 1);
                }
                else
                {

                    /* Timer value fits in the timer entries.  */

                    /* Set the expiration time.  */
                    expiration_time =  (remaining_ticks - ((ULONG) 1));
                }

                /* At this point, we are ready to put the timer on one of
                   the timer lists.  */

                /* Calculate the proper place for the timer.  */
                // 在循环链表中向前移动找到插入的位置
                timer_list =  TX_TIMER_POINTER_ADD(_tx_timer_current_ptr, expiration_time);
                // 循环数组操作。
                if (TX_TIMER_INDIRECT_TO_VOID_POINTER_CONVERT(timer_list) >= TX_TIMER_INDIRECT_TO_VOID_POINTER_CONVERT(_tx_timer_list_end))
                {

                    /* Wrap from the beginning of the list.  */
                    delta =  TX_TIMER_POINTER_DIF(timer_list, _tx_timer_list_end);
                    timer_list =  TX_TIMER_POINTER_ADD(_tx_timer_list_start, delta);
                }
                
                // Mstep 将定时器插入到对应链表结尾处
                /* Now put the timer on this list.  */
                if ((*timer_list) == TX_NULL)
                {

                    /* This list is NULL, just put the new timer on it.  */

                    /* Setup the links in this timer.  */
                    timer_ptr -> tx_timer_internal_active_next =      timer_ptr;
                    timer_ptr -> tx_timer_internal_active_previous =  timer_ptr;

                    /* Setup the list head pointer.  */
                    *timer_list =  timer_ptr;
                }
                else
                {
                    // 插入到链表尾部

                    /* This list is not NULL, add current timer to the end. */
                    next_timer =                                        *timer_list;
                    previous_timer =                                    next_timer -> tx_timer_internal_active_previous;
                    previous_timer -> tx_timer_internal_active_next =   timer_ptr;
                    next_timer -> tx_timer_internal_active_previous =   timer_ptr;
                    timer_ptr -> tx_timer_internal_active_next =        next_timer;
                    timer_ptr -> tx_timer_internal_active_previous =    previous_timer;
                }

                /* Setup list head pointer.  */
                // 更新定时器的链表头指针
                timer_ptr -> tx_timer_internal_list_head =  timer_list;
            }
        }
    }
}

#endif
