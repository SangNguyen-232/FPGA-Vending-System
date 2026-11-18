# FPGA Vending System

A Verilog vending-machine controller developed for **CO3091 - Logic Design Project**. The design targets the programmable logic of the Digilent Arty Z7-20 and uses buttons, switches, a parallel 16x2 character LCD, LEDs, and four BCD digit outputs.

Start with [GUIDE.md](GUIDE.md) for prerequisites, cloning, Vivado project creation, simulation, wiring, programming, and a manual verification procedure.

The [course technical report](DATKLL.pdf), dated December 15, 2024, provides the project's original design narrative, diagrams, and team contribution record. Some descriptions differ from the current RTL; consult the [report-to-source comparison](GUIDE.md#11-technical-report-and-source-alignment) before using it as an operating specification.

## Implemented behavior

- Switch between user and administrator modes.
- Select one of four products using an external one-hot switch bank.
- Show product stock, unit prices, requested quantity, and transaction status on the LCD.
- Add 5 or 10 balance units when no product is selected; clear the balance with a button.
- Increase or decrease the requested quantity and purchase it when stock and balance permit.
- Deduct the purchase total, retain the remaining balance, and indicate success using LEDs.
- In administrator mode, adjust a product's price, add stock, or clear its price and stock.
- Provide four BCD digits representing the balance for an external display circuit.

## Repository contents

| File | Purpose |
| --- | --- |
| `sources_1/new/top_button_handler.v` | Top-level controller and product/balance state |
| `sources_1/new/button_debounce.v` | Button synchronization and debounce logic |
| `sources_1/new/LCD_display.v` | Parallel 8-bit LCD controller |
| `sources_1/new/test_lcd_display.v` | Legacy LCD stimulus testbench |
| `constrs_1/imports/Downloads/Arty-Z7-20-Master.xdc` | Clock and I/O pin constraints |
| `GUIDE.md` | New-user setup and verification instructions |
| `DATKLL.pdf` | Course technical report, design diagrams, and contribution record |

## Current limitations

This is an educational RTL prototype. The repository does not include a Vivado project file, a bitstream, a complete external wiring schematic, or a self-checking system test suite. A physical product dispenser, payment reader, and change-return mechanism are not implemented.

The balance is an 8-bit register, the debounce threshold is truncated by its declared width, and the legacy LCD testbench is too short to verify a complete display update. Read the [known limitations](GUIDE.md#9-known-limitations) before using the design. Hardware operation and synthesis must be checked with the tools and board available to you.

## Contribution requirements

Keep code comments, documentation, setup instructions, and other project explanatory text in English. Update `GUIDE.md` whenever prerequisites, pin assignments, build steps, or test procedures change.
