//! td-free's VEML3328 colour-sensor configuration register, as an h5i-app
//! kernel for a microcontroller.
//!
//! Upstream: `mawoka-myblock/td-free` @ `5e67e73`
//! (`firmware/src/helpers/veml3328.rs`). td-free is an ESP32-C3 filament
//! diameter / colour sensor. Its *physical-value* conversion (lux → TD, colour
//! correction) is written in `f32`/`micromath` and is **outside** the Aeneas
//! subset (Charon/Aeneas do not model floating point); see STATUS.md. What *is*
//! extractable, and is genuinely safety-relevant on a sensor device, is the
//! VEML3328 configuration register bit-manipulation: writing one field (gain,
//! integration time) must never disturb another — in particular it must never
//! flip the shutdown bits and silently power the sensor down, which would make
//! every subsequent reading a nonsensical physical value.
//!
//! This kernel ports `Config::{new, with_high, with_low, set_bits}`, the gain /
//! integration-time bit encodings, and the `enable`/`disable`/`set_gain`/
//! `set_integration_time` register compositions, verbatim in the Aeneas subset.
//!
//! `#![no_std]`, no allocation, no floating point.

#![no_std]

// VEML3328 CONFIG-register bit fields. Values are the upstream shift
// expressions pre-evaluated to literals (Aeneas keeps plain `u16` consts
// cleaner than checked shifts); each is annotated with the upstream form.
pub const SD0: u16 = 1; //            1 << 0   — chip shutdown
pub const SD1: u16 = 32768; //        1 << 15  — channel shutdown
pub const SHUTDOWN: u16 = 32769; //   SD0 | SD1

pub const GAIN_MASK: u16 = 6144; //   0b11 << 11
pub const GAIN_ONE_EIGHTH: u16 = 6144; // 0b11 << 11
pub const GAIN_ONE_QUARTER: u16 = 4096; // 0b10 << 11
pub const GAIN_ONE: u16 = 0; //       0b00 << 11
pub const GAIN_TWO: u16 = 2048; //    0b01 << 11

pub const IT_MASK: u16 = 112; //      0b111 << 4
pub const IT_25MS: u16 = 192; //      0b1100 << 4
pub const IT_50MS: u16 = 128; //      0b1000 << 4
pub const IT_100MS: u16 = 0; //       0b0000 << 4
pub const IT_200MS: u16 = 16; //      0b0001 << 4
pub const IT_400MS: u16 = 32; //      0b0010 << 4
pub const IT_800MS: u16 = 48; //      0b0011 << 4

/// The CONFIG register contents.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Config {
    pub bits: u16,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Gain {
    OneEighth,
    OneQuarter,
    One,
    Two,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum IntegrationTime {
    _25ms,
    _50ms,
    _100ms,
    _200ms,
    _400ms,
    _800ms,
}

/// Power-on default: all bits clear.
pub fn config_new() -> Config {
    Config { bits: 0 }
}

/// Set the bits in `mask` (`Config::with_high`).
pub fn with_high(c: Config, mask: u16) -> Config {
    Config { bits: c.bits | mask }
}

/// Clear the bits in `mask` (`Config::with_low`).
pub fn with_low(c: Config, mask: u16) -> Config {
    Config { bits: c.bits & !mask }
}

/// Replace the `mask` field with `value` (`Config::set_bits`): clear the field,
/// then OR in the masked value.
pub fn set_bits(c: Config, mask: u16, value: u16) -> Config {
    Config { bits: (c.bits & !mask) | (value & mask) }
}

pub fn gain_bits(g: Gain) -> u16 {
    match g {
        Gain::OneEighth => GAIN_ONE_EIGHTH,
        Gain::OneQuarter => GAIN_ONE_QUARTER,
        Gain::One => GAIN_ONE,
        Gain::Two => GAIN_TWO,
    }
}

pub fn it_bits(it: IntegrationTime) -> u16 {
    match it {
        IntegrationTime::_25ms => IT_25MS,
        IntegrationTime::_50ms => IT_50MS,
        IntegrationTime::_100ms => IT_100MS,
        IntegrationTime::_200ms => IT_200MS,
        IntegrationTime::_400ms => IT_400MS,
        IntegrationTime::_800ms => IT_800MS,
    }
}

/// `Veml3328::enable`'s config: clear both shutdown bits, 100 ms integration,
/// gain 1x.
pub fn enable_config() -> Config {
    set_bits(
        set_bits(with_low(config_new(), SHUTDOWN), IT_MASK, IT_100MS),
        GAIN_MASK,
        GAIN_ONE,
    )
}

/// `Veml3328::disable`'s config: set the chip-shutdown bit.
pub fn disable_config(c: Config) -> Config {
    with_high(c, SD0)
}

/// `Veml3328::set_gain`'s config transform.
pub fn set_gain_config(c: Config, g: Gain) -> Config {
    set_bits(c, GAIN_MASK, gain_bits(g))
}

/// `Veml3328::set_integration_time`'s config transform.
pub fn set_it_config(c: Config, it: IntegrationTime) -> Config {
    set_bits(c, IT_MASK, it_bits(it))
}
