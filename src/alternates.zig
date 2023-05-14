pub const STM32L0x1 = struct {
    pub const PA0 = struct {
        pub const USART2_RX = 0;
        pub const LPTIM1_IN1 = 1;
        pub const TIM2_CH1 = 2;
        // -
        pub const USART2_CTS = 4;
        pub const TIM2_ETR = 5;
        pub const LPUART1_RX = 6;
        pub const COMP1_OUT = 7;
    };
    pub const PA1 = struct {
        pub const EVENTOUT = 0;
        pub const LPTIM1_IN2 = 1;
        pub const TIM2_CH2 = 2;
        pub const I2C1_SMBA = 3;
        pub const USART2_RTS = 4;
        pub const TIM21_ETR = 5;
        pub const LPUART1_TX = 6;
        // -
    };
    pub const PA2 = struct {
        pub const TIME21_CH1 = 0;
        // -
        pub const TIME2_CH3 = 2;
        // -
        pub const USART2_TX = 4;
        // -
        pub const LPUART1_TX = 6;
        pub const COMP2_OUT = 7;
    };
    pub const PA3 = struct {
        pub const TIME21_CH2 = 0;
        // -
        pub const TIME2_CH4 = 2;
        // -
        pub const USART2_RX = 4;
        // -
        pub const LPUART1_RX = 6;
        // -
    };
    pub const PA4 = struct {
        pub const SPI1_NSS = 0;
        pub const LPTIM1_IN1 = 1;
        pub const LPTIM1_ETR = 2;
        pub const I2C1_SCL = 3;
        pub const USART2_CK = 4;
        pub const TIM2_CH1 = 5;
        // -
        // -
    };
    pub const PA5 = struct {
        pub const SPI1_SCK = 0;
        pub const LPTIM1_IN2 = 1;
        pub const TIM2_ETR = 2;
        // -
        // -
        pub const TIM2_CH1 = 5;
        // -
        // -
    };
    pub const PA6 = struct {
        pub const SPI1_MISO = 0;
        pub const LPTIM1_ETR = 1;
        // -
        // -
        pub const LPUART1_CTS = 4;
        // -
        pub const EVENTOUT = 6;
        pub const COMP1_OUT = 7;
    };
    pub const PA7 = struct {
        pub const SPI1_MOSI = 0;
        pub const LPTIM1_OUT = 1;
        // -
        // -
        pub const USART2_CTS = 4;
        pub const TIM21_ETR = 5;
        pub const EVENTOUT = 6;
        pub const COMP2_OUT = 7;
    };
    pub const PA8 = struct {
        pub const MCO = 0;
        // -
        pub const LPTIM1_IN1 = 2;
        pub const EVENTOUT = 3;
        pub const USART2_CK = 4;
        pub const TIM2_CH1 = 5;
        // -
        // -
    };
    pub const PA9 = struct {
        pub const MCO = 0;
        pub const I2C1_SCL = 1;
        pub const LPTIM1_OUT = 2;
        // -
        pub const USART2_TX = 4;
        pub const TIM21_CH2 = 5;
        // -
        pub const COMP1_OUT = 7;
    };
    pub const PA10 = struct {
        pub const TIM21_CH1 = 0;
        pub const I2C1_SDA = 1;
        pub const RTC_REFIN = 2;
        // -
        pub const USART2_RX = 4;
        pub const TIME2_CH3 = 5;
        // -
        pub const COMP1_OUT = 7;
    };
    pub const PA11 = struct {
        pub const SPI1_MISO = 0;
        pub const LPTIM1_OUT = 1;
        pub const EVENTOUT = 2;
        // -
        pub const USART2_CTS = 4;
        pub const TIM21_CH2 = 5;
        // -
        pub const COMP1_OUT = 7;
    };
    pub const PA12 = struct {
        pub const SPI1_MOSI = 0;
        // -
        pub const EVENTOUT = 2;
        // -
        pub const USART2_RTS = 4;
        // -
        // -
        pub const COMP2_OUT = 7;
    };
    pub const PA13 = struct {
        pub const SWDIO = 0;
        pub const LPTIM1_ETR = 1;
        // -
        pub const I2C1_SDA = 3;
        // -
        pub const SPI1_SCK = 5;
        pub const LPUART1_RX = 6;
        pub const COMP1_OUT = 7;
    };
    pub const PA14 = struct {
        pub const SWDCLK = 0;
        pub const LPTIM1_OUT = 1;
        // -
        pub const I2C1_SMBA = 3;
        pub const USART2_TX = 4;
        pub const SPI1_MISO = 5;
        pub const LPUART1_TX = 6;
        pub const COMP2_OUT = 7;
    };
    pub const PA15 = struct {
        pub const SPI1_NSS = 0;
        // -
        pub const TIM2_ETR = 2;
        pub const EVENTOUT = 3;
        pub const USART2_RX = 4;
        pub const TIM2_CH1 = 5;
        // -
        // -
    };
    pub const PB0 = struct {
        pub const EVENTOUT = 0;
        pub const SPI1_MISO = 1;
        pub const TIM2_CH2 = 2;
        // -
        pub const USART2_RTS = 4;
        pub const TIM2_CH3 = 5;
        // -
        // -
    };
    pub const PB1 = struct {
        pub const USART2_CK = 0;
        pub const SPI1_MOSI = 1;
        pub const LPTIM1_IN1 = 2;
        // -
        pub const LPUART1_RTS = 4;
        pub const TIM2_CH4 = 5;
        // -
        // -
    };
    pub const PB2 = struct {
        // -
        // -
        pub const LPTIM1_OUT = 2;
        // -
        // -
        // -
        // -
        // -
    };
    pub const PB3 = struct {
        pub const SPI1_SCK = 0;
        // -
        pub const TIM2_CH2 = 2;
        // -
        pub const EVENTOUT = 4;
        // -
        // -
        // -
    };
    pub const PB4 = struct {
        pub const SPI1_MISO = 0;
        // -
        pub const EVENTOUT = 2;
        // -
        // -
        // -
        // -
        // -
    };
    pub const PB5 = struct {
        pub const SPI1_MOSI = 0;
        // -
        pub const LPTIM1_IN1 = 2;
        pub const I2C1_SMBA = 3;
        // -
        pub const TIM21_CH1 = 5;
        // -
        // -
    };
    pub const PB6 = struct {
        pub const USART2_TX = 0;
        pub const I2C1_SCL = 1;
        pub const LPTIM1_ETR = 2;
        // -
        // -
        pub const TIM2_CH3 = 5;
        pub const LPUART1_TX = 6;
        // -
    };
    pub const PB7 = struct {
        pub const USART2_RX = 0;
        pub const I2C1_SDA = 1;
        pub const LPTIM1_IN2 = 2;
        // -
        // -
        pub const TIM2_CH4 = 5;
        pub const LPUART1_RX = 6;
        // -
    };
    pub const PB8 = struct {
        pub const USART2_TX = 0;
        // -
        pub const EVENTOUT = 2;
        // -
        pub const I2C1_SCL = 4;
        pub const SPI1_NSS = 5;
        // -
        // -
    };
};
