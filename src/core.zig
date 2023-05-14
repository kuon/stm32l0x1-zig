const std = @import("std");

const microzig = @import("microzig");
const regs = microzig.chip.peripherals;
const set = @import("core.zig").set_reg_field;

pub fn init_clocks() void {
    // Enable HSI
    regs.RCC.CR.modify(.{ .HSI16ON = 1 });

    // Wait for HSI ready
    while (regs.RCC.CR.read().HSI16RDYF != 1) {}

    // Use HSI16 as system clock and wakeup clock
    regs.RCC.CFGR.modify(.{ .SW = 0b01, .STOPWUCK = 1 });

    // Enable power interface clock
    regs.RCC.APB1ENR.modify(.{ .PWREN = 1 });

    // Disable RTC register protection
    // This MUST be done once the PWREN has been set in RCC_APB1ENR
    regs.PWR.CR.modify(.{ .DBP = 1 });

    // Enable LSE (external crystal at 32kHz)
    regs.RCC.CSR.modify(.{ .LSEON = 1 });
    // Wait for LSE to be stable
    while (regs.RCC.CSR.read().LSERDY != 1) {}

    // Use LSE as RTC source and enable RTC
    regs.RCC.CSR.modify(.{
        .RTCSEL = 0b01, // LSE
        .RTCEN = 1,
    });
}

const RTCConfig = struct {
    wakup_interval: u16,
};

pub fn init_rtc(config: RTCConfig) void {
    regs.EXTI.PR.modify(.{ .PIF1 = 0 }); // Clear pending bits

    if (config.wakup_interval > 0) {
        // Configure Wake up EXT
        // Enable RTC EXT interrupt
        regs.EXTI.IMR.modify(.{ .IM20 = 1 }); // Enable interrupt
        regs.EXTI.RTSR.modify(.{ .RT20 = 1 }); // Rising edge enabled
        // Alarm interrupt
        //regs.EXTI.IMR.modify(.{ .IM17 = 1 }); // Enable interrupt
        //regs.EXTI.RTSR.modify(.{ .RT17 = 1 }); // Rising edge enabled
    } else {
        // Wakeup
        regs.EXTI.IMR.modify(.{ .IM20 = 0 }); // Disable interrupt
        regs.EXTI.RTSR.modify(.{ .RT20 = 0 }); // Rising edge disable
        // Alarm
        // regs.EXTI.IMR.modify(.{ .IM17 = 0 }); // Disable interrupt
        // regs.EXTI.RTSR.modify(.{ .RT17 = 0 }); // Rising edge disable
    }
    // Wakeup
    regs.EXTI.EMR.modify(.{ .EM20 = 0 }); // Disable events
    regs.EXTI.FTSR.modify(.{ .FT20 = 0 }); // Failling edge disabled
    // Alarm
    // regs.EXTI.EMR.modify(.{ .EM17 = 0 }); // Disable events
    // regs.EXTI.FTSR.modify(.{ .FT17 = 0 }); // Failling edge disabled

    unlock_rtc();

    // Wait for APB registers
    regs.RTC.ISR.modify(.{ .RSF = 0 });
    while (regs.RTC.ISR.read().RSF == 0) {}

    // Enter init mode
    if (regs.RTC.ISR.read().INITF == 0) {
        regs.RTC.ISR.modify(.{ .INIT = 1 });
        while (regs.RTC.ISR.read().INITF == 0) {}
    }

    // RTC prescaler
    regs.RTC.PRER.modify(.{ .PREDIV_S = 0xFF, .PREDIV_A = 0x7F });

    // Clear RTC FMT bit (24-hour)
    regs.RTC.CR.modify(.{ .FMT = 0 });

    // Exit init mode
    regs.RTC.ISR.modify(.{ .INIT = 0 });
    while (regs.RTC.ISR.read().INITF == 1) {}

    // Configure RTC wake up
    // Disable wake up timer to modify it
    regs.RTC.CR.modify(.{ .WUTE = 0 });

    // Wait for bit to be set (write allowed)
    while (regs.RTC.ISR.read().WUTWF == 0) {}
    regs.RTC.ISR.modify(.{ .WUTF = 0 });

    // Disable alarm to modify it
    // regs.RTC.CR.modify(.{ .ALRAE = 0 });
    // while (regs.RTC.ISR.read().ALRAWF == 0) {}

    if (config.wakup_interval > 0) {
        // Set wake up period to (1hz)
        regs.RTC.WUTR.modify(.{ .WUT = (config.wakup_interval - 1) });

        // Configure wake up timer
        regs.RTC.CR.modify(.{
            .WUTIE = 1,
            .WUTE = 1,
            .WUCKSEL = 0b100, // 1 Hz clock
            //.WUCKSEL = 0b011, // 1 Hz clock
        });
        while (regs.RTC.ISR.read().WUTWF == 1) {}

        // Configure alarm
        // regs.RTC.ALRMAR.modify(.{
        //     .MSK1 = 1,
        //     .MSK2 = 1,
        //     .MSK3 = 1,
        //     .MSK4 = 1,
        // });
        //
        // regs.RTC.CR.modify(.{ .ALRAIE = 1, .ALRAE = 1, });
        //
        // Enable RTC interrupt
    }

    lock_rtc();
}

fn unlock_rtc() void {
    // Enable write access to RTC
    regs.RTC.WPR.modify(.{ .KEY = 0xCA });
    regs.RTC.WPR.modify(.{ .KEY = 0x53 });
}

fn lock_rtc() void {
    regs.RTC.WPR.modify(.{ .KEY = 0xFE });
    regs.RTC.WPR.modify(.{ .KEY = 0x64 });
}

pub fn reset() void {
    regs.SCB.AIRCR.modify(.{ .VECTKEYSTAT = 0x05FA, .SYSRESETREQ = 1 });
    while (true) {}
}

pub fn configure_sleep() void {
    regs.PWR.CR.modify(.{
        // Clear wakeup flag
        .CWUF = 1,
        // Ultra low power off
        .ULP = 0,
        // STOP mode when deepsleep
        .PDDS = 0,
        // Regulator in MAIN mode in STOP mode
        .LPRUN = 0,
        // Regulator ON in SLEEP
        //.LPSDSR = 0,
        // Regulator in MAIN mode in STOP mode
        .LPDS = 0,
    });
}

pub fn sleep_on_exit(enabled: bool) void {
    &regs.SCB.SCR.modify(.{ .SLEEPONEXIT = @boolToInt(enabled) });
}

pub fn sleep_deep(enabled: bool) void {
    &regs.SCB.SCR.modify(.{ .SLEEPDEEP = @boolToInt(enabled) });
}

pub fn delay(ms: u32) void {
    // CPU run at 16mHz on HSI16
    // each tick is 5 instructions (1000 * 16 / 5) = 3200
    var ticks: u32 = ms * (1000 * 16 / 5);
    var i: u32 = 0;
    while (i < ticks) {
        // This is 5 instructions
        microzig.cpu.nop();
        i += 1;
    }
}

pub fn nop() void {
    microzig.cpu.nop();
}

pub fn set_reg_field(reg: anytype, comptime field_name: anytype, value: anytype) void {
    var temp = reg.read();
    @field(temp, field_name) = value;
    reg.write(temp);
}

pub fn reg_field(reg: anytype, comptime field_name: anytype) u32 {
    var temp = reg.read();
    return @field(temp, field_name);
}

pub fn clear_rtc_wakeup_flag() void {
    // Clear wakeup
    if (regs.RTC.ISR.read().WUTF == 1) {
        regs.RTC.ISR.modify(.{ .WUTF = 0 });
        regs.EXTI.PR.modify(.{ .PIF20 = 1 });
    }
}

pub fn clear_alarm_wakeup_flag() void {
    // Clear alarm
    if (regs.RTC.ISR.read().ALRAF == 1) {
        regs.RTC.ISR.modify(.{ .ALRAF = 0 });
        regs.EXTI.PR.modify(.{ .PIF17 = 1 });
    }
}

pub fn enable_interrupt(comptime id: anytype) void {
    set(&regs.NVIC.ISER, @tagName(id), 1);
}

pub fn disable_interrupt(comptime id: anytype) void {
    set(&regs.NVIC.ICER, @tagName(id), 1);
}

pub fn pend_interrupt(comptime id: anytype) void {
    set(&regs.NVIC.ISPR, @tagName(id), 1);
}

pub fn unpend_interrupt(comptime id: anytype) void {
    set(&regs.NVIC.ICPR, @tagName(id), 1);
}

pub fn set_interrupt_priority(comptime id: anytype, priority: enum(u3) {
    maximum = 0,
    urgent = 1,
    very_high = 2,
    high = 3,
    medium = 4,
    low = 5,
    very_low = 6,
    minimum = 7,
}) void {
    const name = @tagName(id);
    const pri = @enumToInt(priority);
    if (id == .WWDG or id == .PVD or id == .RTC or id == .FLASH) {
        set(&regs.NVIC.IPR0, name, pri);
    } else if (id == .RCC or id == .EXTI0_1 or id == .EXTI2_3 or id == .EXTI4_15) {
        set(&regs.NVIC.IPR1, name, pri);
    } else if (id == .DMA1_Channel1 or id == .DMA1_Channel2_3 or id == .DMA1_Channel4_7) {
        set(&regs.NVIC.IPR2, name, pri);
    } else if (id == .ADC_COMP or id == .LPTIM1 or id == .USART4_USART5 or id == .TIM2) {
        set(&regs.NVIC.IPR3, name, pri);
    } else if (id == .TIM3 or id == .TIM6 or id == .TIM7) {
        set(&regs.NVIC.IPR4, name, pri);
    } else if (id == .TIM21 or id == .I2C3 or id == .TIM22 or id == .I2C1) {
        set(&regs.NVIC.IPR5, name, pri);
    } else if (id == .I2C2 or id == .SPI1 or id == .SPI2 or id == .USART1) {
        set(&regs.NVIC.IPR6, name, pri);
    } else if (id == .USART2 or id == .AES_RNG_LPUART1) {
        set(&regs.NVIC.IPR7, name, pri);
    } else {
        @compileError("Cannot set interrupt priority");
    }
}

pub fn enable_interrupts() void {
    microzig.cpu.enable_interrupts();
}

pub fn disable_interrupts() void {
    microzig.cpu.disable_interrupts();
}

pub fn wait_for_interrupt() void {
    microzig.cpu.wfi();
}

pub fn wait_for(
    comptime reg: anytype,
    comptime field: anytype,
    comptime value: anytype,
) void {
    while (!(@field(reg.read(), @tagName(field)) == value)) {}
}

const CoreError = error{
    TimeoutError,
};

pub fn timeout_wait_for(
    comptime timeout_ms: u32,
    comptime reg: anytype,
    comptime field: anytype,
    comptime value: anytype,
) !void {
    var ticks: u32 = timeout_ms * (1000 * 16 / 5);
    while (!(@field(reg.read(), @tagName(field)) == value)) {
        ticks -= 1;
        if (ticks == 0) {
            return CoreError.TimeoutError;
        }
    }
}
