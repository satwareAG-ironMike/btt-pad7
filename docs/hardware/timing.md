# RTC, clock, watchdog

## Verified facts

| Item | Finding | Evidence |
|------|---------|----------|
| RTC | sun6i-rtc 7000000.rtc registered as `rtc0`; unconfigured (no RTC data source) | dmesg 2026-10-31 |
| Boot wall-clock | kernel sets system clock to 1970-01-02T00:00:04 UTC (86404) at boot | dmesg 2026-10-31 |
| Clock drift | wall clock stepped ~10 h 35 m between two reads on the same day; NTP suspected, **unverified** | 2026-10-31 reverify |
| Watchdog | sunxi-wdt 30090a0.watchdog: timeout 16 s, nowayout=0; `/sys/class/watchdog/watchdog0` | dmesg 2026-10-31 |

## Online resources

- Linux RTC API: <https://docs.kernel.org/api/rtc.html>
- sun6i-rtc driver: https://github.com/torvalds/linux/tree/master/drivers/rtc/sunxi

## Drift and notes

- No battery-backed RTC persistence: wall clock resets to epoch+1 on every
  boot (dmesg). NTP status on this minimal image is unverified.
