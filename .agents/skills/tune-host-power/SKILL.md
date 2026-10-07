---
name: tune-host-power
description: >-
  Estimate and lower the power consumption of a physical host: establish a
  measured baseline, attribute the draw to components, rank the levers, and run
  reversible tuning experiments. Use when the user asks what a server, NAS, or
  lab machine costs to run, whether it can run 24/7, how to reduce its idle
  power, or mentions watts, kWh, electricity cost, smart plug readings, ASPM,
  C-states, cpufreq governors, SATA link power management, PSU efficiency, or
  `powertop` findings.
license: MIT
---

# Tune Host Power

Measurement-first method for evaluating and reducing a host's power draw. The
output is a baseline with an attribution table, a ranked list of levers with
expected gains, and per-step measured deltas for the experiments that run.

## 1. Choose the Instrument

- A wall meter (smart plug, UPS load readout, PDU) is the reference. Software
  counters measure only parts of the system: RAPL covers the CPU package and
  DRAM, never drives, fans, the board, the BMC, or PSU losses.
- Learn the meter's resolution and what else it feeds. Read it with the host
  unplugged and again with the host off but plugged in: the first is the shared
  baseline to subtract from every reading, the difference is the host's standby
  draw (PSU standby rail plus BMC), which no OS setting can touch and which
  counts toward the 24/7 figure.
- Compare before/after windows by their medians at the meter's resolution, over
  enough samples to average out other devices. A delta smaller than the
  resolution is "within noise", which is itself a result.
- Pull historical windows from the metrics store when the meter is scraped: a
  host's power-on and power-off transitions over past days give several
  independent on/off pairs without new experiments.

## 2. Read What the Host Already Knows

- CPU: RAPL package and DRAM watts (`/sys/class/powercap`), core and package
  C-state residency (`powertop`, `turbostat`), governor and driver mode
  (`/sys/devices/system/cpu/*/cpufreq`).
- Platform ceiling: many server boards expose no package state deeper than C6
  while consumer boards often reach C8 to C10, but the firmware decides either
  way. Read the package C-state limit it programmed (the `pkg-cstate-limit`
  field in the header `turbostat` prints on Intel hosts with MSR access) before
  treating a C6 ceiling as the platform's, then rule out a blocked device. A
  host already at its deepest state has no blocked state to unlock, so stories
  of halving idle power by fixing one device do not transfer to it.
- PCIe: `lspci -vv` link capabilities versus link control (ASPM advertised
  versus enabled), the `pcie_aspm` policy, `_OSC` lines in the kernel log that
  show whether the firmware granted ASPM control, and devices the kernel refuses
  (pre-1.1 devices, drivers that disable ASPM for stability).
- Storage: drive models and their datasheet idle figures, SATA link power
  policies per host, DIPM and DevSleep support (`hdparm -I`), NVMe APST states
  (`smartctl -c`), and which drives hold data versus sit empty.
- Out of band: install the IPMI tool on hosts with a BMC and read fan speeds,
  the fan mode, temperatures, and the DCMI power reading. A zero or missing DCMI
  reading means either that the PSU has no PMBus or that the BMC does not
  implement DCMI power management: check the sensor repository (`ipmitool sdr`)
  for power sensors before settling for the wall meter as the only instrument.
- PSU: identify the model and age. Certification efficiency applies at 20% to
  100% load; at the 5% to 10% load an idle server presents, a decade-old unit
  loses a quarter or more of the input power.
- Memory: DIMM count and type from `dmidecode`; registered DIMMs draw more than
  the RAPL DRAM figure suggests.

## 3. Attribute and Rank

Build an attribution table from the readings and datasheets, label datasheet
values as expectations, and rank the levers by expected gain:

- Drives that are not needed: removing an idle spinning disk saves 4 to 7 W DC,
  more at the wall. Respect the owner's policy on spin-down and start/stop wear
  instead of proposing standby timers.
- PSU replacement when the unit is old or oversized: often the largest single
  lever at low load, and a reliability upgrade for 24/7 duty. Do it last, so it
  is sized and measured at the final DC load.
- Fans: check the BMC fan mode before assuming a gain; a mode already at optimal
  leaves nothing.
- ASPM: enabling it recovers under 1 W per idle link on gigabit NICs and NVMe,
  and tens of watts only when a blocked link kept the package out of a deep
  state. Firmware that denies ASPM control and devices whose drivers disable it
  are the usual blockers.
- SATA link power management (`med_power_with_dipm`): 0.5 to 1 W per link, with
  a link-reset risk on old SSDs and drives; test one port at a time with the
  kernel log watched, and run a filesystem scrub before trusting it.
- CPU governor: near zero at idle on a host whose cores sleep most of the time,
  because the governor only sets the frequency of awake cores. Its benefit
  appears under sustained light load; quantify it with a controlled load, and
  under passive `intel_pstate` avoid the `powersave` governor, which pins the
  minimum frequency.
- Runtime PM for PCI and USB devices, NMI watchdog, dirty writeback interval:
  small, cheap, and safe to try after the above.
- BIOS: energy-efficient power technology, DRAM power-down, unused controllers
  and ports. Small gains, each needs a reboot and console access.
- Duty cycle: a host that runs an hour a day costs a small fraction of a 24/7
  host; compare tuning gains against scheduled power-on before tuning.

Convert watts to kWh and currency per year at the local tariff. The decision to
run 24/7 usually rests on that number, heat, and noise together.

## 4. Run Reversible Experiments

- One change per window, long enough for the meter's sample rate to average,
  with a readback that proves the change took effect (link control bits, sysfs
  values), not only the write.
- When a change can cut remote access (NIC links, the SATA controller of the
  root pool), arm a self-reverting timer first, for example
  `systemd-run --on-active=20min` writing the previous value, and cancel it only
  after the window is clean.
- Watch the kernel log for PCIe advanced error reporting, link reset, and driver
  errors, and the NIC error counters, during and after the window.
- Never use `powertop --auto-tune`: it applies every tunable at once, including
  ones that conflict with drive policies, and leaves nothing attributable.
- Runtime sysfs writes do not survive a reboot. Persist only the settings whose
  gain was measured, through the host's declarative configuration, and prove the
  boot-time path with one reboot.

## 5. Report

Report the baseline table, each experiment's before/after medians with sample
counts, the stability evidence, the resulting attribution, and the ranked
remaining levers with their expected gains and prerequisites. State which
numbers were measured and which are datasheet expectations.
