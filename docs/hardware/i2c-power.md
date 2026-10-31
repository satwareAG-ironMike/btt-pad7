# I2C, power, GPIO, PWM, thermal

## Verified facts

| Item | Finding | Evidence |
|------|---------|----------|
| I2C buses | 4 buses (i2c-0 to i2c-3) | 2026-10-28 survey |
| PMIC | AXP313a @ i2c-1/0x36 (axp20x-i2c) | dmesg 2026-10-31 |
| AC audio | ac200-sunxi @ i2c-0/0x10 probe fails -22; dmesg "it's ac300, skip the ac200 init!" | dmesg 2026-10-31 |
| Soft I2C | scl/sda on GPIO 74/76 (gpiochip0) | 2026-10-28 deep-scan |
| GPIO | gpiochip0 = sunxi 288 pins (spi1 CS0/1/2 = 75/71/77; CAN INT 73; soft-I2C scl/sda 74/76; ws2812-gpio 78; led_work 229 active-low; reset 210); gpiochip1 = R_PIO 32 pins | 2026-10-28 deep-scan |
| PWM | pwmchip0 npwm=6, export dir empty (no pwmN); pwm_sunxi_enhance + clk_pwm loaded | 2026-10-31 reverify |
| Thermal | hwmon0-3 (4 zones: cpu/gpu/ve/ddr); temp1_input 52307 / 52064 / 53198 / 52388 mC (~52 C); hwmon `type` file empty | 2026-10-31 reverify |

## Online resources

- Linux power management: <https://docs.kernel.org/power/>
- Allwinner (AXP313 vendor page): <https://www.allwinner.com/>

## Drift and notes

- ac200-sunxi probe failure (-22) confirmed at 2026-10-31; the device is the
  AC300 variant, not the AC200 the driver targets.
- PWM exports empty since 2026-10-31 reverify; npwm=6 is static.
