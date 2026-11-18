# FPGA Vending System: Setup and User Guide

This guide walks you through creating a Vivado project from the Verilog sources, connecting the Arty Z7-20, and using the controller to configure stock and complete a purchase.

Read the limitations in section 9 before planning a hardware demonstration. The commands below have been checked against the source layout; synthesis, simulation, timing closure, and physical operation still require validation in your own Vivado installation and on your hardware.

| Your objective | Follow these sections |
| --- | --- |
| Understand the design | Section 1 for the RTL modules and section 8 for the controls |
| Inspect the existing LCD simulation without a board | Sections 2-5 |
| Run a physical demonstration | Sections 2-4 and 6-9; review the simulation limitations in section 5 |
| Diagnose unexpected behavior | Sections 9 and 10 |

## 1. What runs where

The project contains Verilog RTL, an XDC constraints file, and a small LCD testbench. It is not a desktop or web application. You use a development computer to edit and simulate the RTL and to generate a bitstream. The bitstream runs in the programmable logic of an Arty Z7-20 FPGA board.

The controller has no processor software, operating system, network service, database, package-manager dependencies, or environment variables to configure. All product prices, stock, and balance are held in registers and are cleared by reset; there is no persistent transaction storage.

The top-level module `top_button_handler` controls both operating modes, product selection, prices, stock, balance, and LCD text. It instantiates four `button_debounce` modules, one per button, and one `LCD_display` module for the parallel LCD signals. `test_lcd_display` exercises only the LCD module; it does not exercise the full vending controller.

## 2. Prerequisites

### Development computer

1. Install Git and confirm that `git --version` works in a terminal.
2. Install AMD Vivado with support for **Zynq-7000** devices, the Vivado Simulator, and cable drivers. Use an operating-system version supported by your chosen Vivado release. The repository does not specify or validate a particular Vivado version; do not infer one from the source creation dates.
3. Confirm that the part `xc7z020clg400-1` is available when creating a project. Digilent's [Arty Z7-20 project template](https://github.com/Digilent/Arty-Z7-20-template/blob/master/proj/create_project.tcl) uses this part. Selecting the part directly avoids requiring a separate board-definition installation.
4. Use a text editor that saves source and Markdown files as UTF-8. Basic Verilog, digital logic, and Vivado knowledge will help when interpreting warnings and waveforms.

The instructions use Vivado's GUI and its **Tcl Console**. Terminal commands marked `sh` work in PowerShell, Command Prompt, Bash, or a Git terminal. Commands marked `tcl` must be entered in Vivado, not in an operating-system shell. Follow AMD's [installation guide](https://docs.amd.com/r/en-US/ug973-vivado-release-notes-install-license) for your selected release and its system requirements.

### Hardware, only for a physical demonstration

- A Digilent **Arty Z7-20** board. The supplied constraints identify the Rev. B pin map; compare them with the schematic for the board revision in use.
- A USB data cable connected to the board's programming/JTAG interface and a suitable board power source.
- A compatible 16x2 character LCD with an 8-bit parallel interface, including its required power, ground, contrast, and backlight circuitry.
- Four external product-selection switches with defined high and low logic levels. The onboard switches are already assigned to reset and mode selection.
- External circuitry that accepts four 4-bit BCD values if a balance display is needed. The RTL does **not** directly drive the seven segments or implement digit multiplexing.
- Appropriate wiring and any required level translation. All active XDC I/O constraints use `LVCMOS33`. Verify the LCD and display-interface voltage requirements; an LCD's physical connector numbering and power wiring are not specified in this repository.

Simulation needs no board or peripherals. A board alone is insufficient for the complete LCD and balance-display demonstration.

## 3. Clone and inspect the repository

Open a terminal in the parent folder where you want to keep the project:

```sh
git clone https://github.com/SangNguyen-232/FPGA-Vending-System.git
cd FPGA-Vending-System
git status --short
```

The last command should show no local modifications immediately after cloning. If you already have a clone, enter that directory and inspect its status before making changes.

The source layout is:

```text
FPGA-Vending-System/
  README.md
  GUIDE.md
  sources_1/new/
    top_button_handler.v
    button_debounce.v
    LCD_display.v
    test_lcd_display.v
  constrs_1/imports/Downloads/
    Arty-Z7-20-Master.xdc
```

There is no checked-in `.xpr` file. Create the Vivado project in the next step. Keep `test_lcd_display.v` in the simulation fileset, not the synthesis source list.

## 4. Create the Vivado project

1. Start Vivado and show the **Tcl Console**.
2. Change the console's working directory to your clone. Replace the example path with the actual path. Use forward slashes and braces for Windows paths containing spaces:

   ```tcl
   cd {C:/work/FPGA-Vending-System}
   ```

   On Linux, an equivalent example is `cd {/home/your-name/work/FPGA-Vending-System}`.
3. Run the following Tcl commands once in a new project session:

   ```tcl
   set repo [pwd]
   create_project vending [file join $repo build vivado] -part xc7z020clg400-1
   set_property target_language Verilog [current_project]
   add_files -norecurse [list \
       [file join $repo sources_1 new top_button_handler.v] \
       [file join $repo sources_1 new button_debounce.v] \
       [file join $repo sources_1 new LCD_display.v]]
   add_files -fileset constrs_1 -norecurse \
       [file join $repo constrs_1 imports Downloads Arty-Z7-20-Master.xdc]
   add_files -fileset sim_1 -norecurse \
       [file join $repo sources_1 new test_lcd_display.v]
   set_property top top_button_handler [get_filesets sources_1]
   set_property top test_lcd_display [get_filesets sim_1]
   update_compile_order -fileset sources_1
   update_compile_order -fileset sim_1
   ```

4. Confirm in **Sources** that `top_button_handler` is the design top and `test_lcd_display` is the simulation top. The design should contain the LCD controller and four debounce instances.
5. On later visits, use **Open Project** and select `build/vivado/vending.xpr`. Do not rerun `create_project` over an existing project. Generated files under `build/` are ignored by Git.

The XDC sets `clk` to an 8 ns period, equivalent to 125 MHz. Timing counters in the RTL assume this frequency. The legacy testbench uses a different frequency, as explained below.

## 5. Run and interpret the existing simulation

1. In **Flow Navigator**, choose **Run Simulation > Run Behavioral Simulation**. AMD documents this workflow in the [Vivado logic simulation guide](https://docs.amd.com/r/en-US/ug900-vivado-logic-simulation/Using-the-launch_simulation-Command). The equivalent Tcl command is:

   ```tcl
   launch_simulation -mode behavioral
   ```

2. Inspect compile/elaboration messages. The existing LCD instance omits the `update`, `sw_p`, and `flag_counter` input connections; these may produce warnings or undriven values. They are limitations of the supplied testbench.
3. In the simulation hierarchy, select `test_lcd_display` and add `clk`, `rst`, `line1`, `line2`, `rs`, `rw`, `en`, and `data` to the waveform window. Expand `uut` to inspect its `state`, `delay_counter`, and `char_index`.
4. Observe that the testbench toggles `clk` every 5 ns, giving a 100 MHz clock. It releases reset at 10 ns and calls `$stop` 1,000 ns later, at **1,010 ns**. Vivado may initially run only to its configured simulation duration, such as 1,000 ns. If the current simulation time is still earlier than 1,010 ns, enter `run 2 us` to reach the testbench's `$stop`; execution pauses at that stop instead of completing the requested duration. This is only an initial waveform inspection, not a test pass/fail result.
5. To inspect the legacy waveform for longer after the stop, enter `run 50 ms` in the simulation Tcl Console. This continues the existing stimulus; it does not correct the disconnected inputs or add assertions. You should be able to inspect the initial LCD command sequence and subsequent character transfers. The hex payloads are legacy values, not correctly padded and ordered text messages.
6. Close the simulation before proceeding to synthesis.

The first LCD state alone takes about 100,000 clock cycles, roughly 1 ms at the testbench's 100 MHz clock. Consequently, the original 1.01 microsecond run cannot demonstrate a completed LCD initialization, let alone a complete vending transaction.

For meaningful future regression coverage, a dedicated testbench must drive every input, use an 8 ns clock when checking board timing, supply explicit 16-character strings, run long enough for complete transfers, and assert the expected outputs. A separate top-level testbench is needed for balance, stock, selection, reset, insufficient-funds, and administrator scenarios. No such self-checking suite is included, and successful elaboration alone is not evidence that those scenarios pass.

## 6. Check the physical connections

Use `Arty-Z7-20-Master.xdc` as the source of truth for package pins. The following table summarizes its active assignments. Lists are ordered by increasing signal bit index.

| RTL signal | Board signal or external connection | FPGA package pin(s) |
| --- | --- | --- |
| `clk` | Board clock, 125 MHz | H16 |
| `rst` | SW0, active-high reset | M20 |
| `sw_au` | SW1: low = user, high = administrator | M19 |
| `btn[0..3]` | BTN0 through BTN3 | D19, D20, L20, L19 |
| `led[0..3]` | LED0 through LED3 | R14, P14, N16, M14 |
| `sw_p[0..3]` | External switches on CK_IO0 through CK_IO3 | T14, U12, U13, V13 |
| `update_money` | CK_IO4; unused by the RTL | V15 |
| `seg_0_data[0..3]` | BCD units, CK_IO26 through CK_IO29 | U5, V5, V6, U7 |
| `seg_1_data[0..3]` | BCD tens, CK_IO30 through CK_IO33 | V7, U8, V8, V10 |
| `seg_2_data[0..3]` | BCD hundreds, CK_IO34 through CK_IO37 | W10, W6, Y6, Y7 |
| `seg_3_data[0..3]` | BCD thousands, CK_IO38 through CK_IO41 | W8, Y8, W9, Y9 |
| `rs`, `rw`, `en` | LCD control, CK_A0 through CK_A2 | Y11, Y12, W11 |
| `data[0..2]` | LCD D0 through D2, CK_A3 through CK_A5 | V11, T5, U10 |
| `data[3..7]` | LCD D3 through D7, CK_A6 through CK_A10 | F19, F20, C20, B20, B19 |

The `seg_*_data` buses carry digit values 0 through 9; a direct connection to a raw seven-segment LED will not decode those values. Use an appropriate external decoder/display interface. Connect the LCD's control and data signals by function, using its own datasheet for connector pins and electrical requirements. Power, ground, contrast, and backlight connections are separate from the FPGA package-pin mapping above.

## 7. Synthesize, implement, and program

1. Confirm the design top is `top_button_handler` and the part is `xc7z020clg400-1`.
2. Choose **Run Synthesis**. Inspect errors and warnings before proceeding. In particular, review the truncated debounce literal, unused inputs, and width mismatch described in section 9.
3. Open the synthesized design and inspect **I/O Ports** against section 6 and the XDC. Do not substitute pins for a different board without updating and reviewing the constraints.
4. Choose **Run Implementation**. Review the timing summary and design-rule checks. The target clock is 125 MHz; verify that the implemented design meets its constraints. Documentation does not establish timing closure.
5. Choose **Generate Bitstream** only after addressing blocking errors and reviewing the reports. The expected output location for the project created above is `build/vivado/vending.runs/impl_1/top_button_handler.bit`.
6. Connect the powered board to the computer's USB programming interface. Open **Hardware Manager > Open Target > Auto Connect**. If no device appears, check the data cable, board power, cable drivers, and hardware-server connection.
7. Select the FPGA device, choose **Program Device**, and select the generated `.bit` file. Check that programming completes successfully.
8. Set SW0 high briefly, then low, to reset and start the controller. Reset clears every product's price and stock as well as the balance.

This procedure programs the current FPGA configuration. It does not configure nonvolatile boot storage; repeat programming after a power cycle unless you separately implement and verify a persistent boot flow.

Closing Vivado does not stop the programmed logic while the board remains powered. To end a demonstration, stop interacting with the controls and power down the board according to its hardware instructions. On the next session, reopen `build/vivado/vending.xpr`, reconnect the hardware target, program the bitstream again if needed, and reset before configuring prices and stock.

## 8. Operate and manually verify the controller

### 8.1 Identify the controls

Onboard **SW0** is the global reset (`rst`), and onboard **SW1** selects the operating mode (`sw_au`). The four product-selection switches are external inputs named `sw_p`; do not confuse a product switch with onboard SW0 or SW1.

Release all buttons and turn all four product switches off before resetting. Return SW0 low after reset. Press and release one button at a time, allowing the LCD to refresh before the next action. The debounce logic generates an event for an accepted low-to-high transition; holding a button high does not continuously repeat its action.

| `sw_p[3:0]` | Selection |
| --- | --- |
| `0000` | No product: balance controls in user mode |
| `0001` | Product 1, external `sw_p[0]` on |
| `0010` | Product 2, external `sw_p[1]` on |
| `0100` | Product 3, external `sw_p[2]` on |
| `1000` | Product 4, external `sw_p[3]` on |
| Any other value | Invalid selection: more than one product switch is on |

Set SW1 high for administrator mode or low for user mode. The buttons then have the following meanings:

| Mode and selection | BTN0 | BTN1 | BTN2 | BTN3 |
| --- | --- | --- | --- | --- |
| Administrator, one product selected | Increase unit price up to 9 | Decrease price while it is greater than 1 | Increase stock up to 9 | Clear selected price and stock |
| User, no product selected | Add 5 balance units | Add 10 balance units | Clear balance | No action |
| User, one product selected | Increase quantity up to available stock and 9 | Decrease quantity to zero | Attempt purchase | No action |

In administrator mode, no product or an invalid selection shows the mode heading but does not change product data. In user mode, an invalid selection displays `ONLY_1_SWITCH_ON` and does not enter the product or balance-control branch.

Prices and deposits are demonstration units. The `$` character is a display label from the project; it does not represent a connection to a payment provider or physical currency detector.

### 8.2 Read the displays

The LCD has sixteen character positions per line. The following examples show its logical text; padding spaces are omitted. Physical readability still depends on the LCD wiring and timing described in sections 6 and 9.

| State | First LCD line | Second LCD line |
| --- | --- | --- |
| Administrator, no product selected | `ADMIN_MODE` | Blank |
| Administrator, product 1 priced at 2 with stock 3 | `ADMIN MODE 1` | `Price:2$   Num:3` |
| User, no product selected; only product 1 configured | `P1:2$_3  P2:0$_0` | `P3:0$_0  P4:0$_0` |
| User, product 1 selected; requested quantity 2 | `Ready:3 Price:2` | `Count:2 Price:4` |
| Purchase succeeds | `SUCCESS!` | Status-counter character |
| A nonzero requested quantity is unaffordable, with stock available | `NOT ENOUGH MONEY` | Status-counter character |
| More than one product switch is on in user mode | `ONLY_1_SWITCH_ON` | Blank |

The four BCD outputs show the remaining balance, not the purchase total. With a balance of 10, `seg_3_data` through `seg_0_data` are `0`, `0`, `1`, `0`. The purchase total is the second line's `Price` field. The stock and unit-price fields normally use single digits, each from 0 to 9; a valid quantity of 9 at a unit price of 9 gives a two-digit total of 81.

On success, the selected product's LED is toggled during the status period. The LEDs are not a general administrator/user mode indicator in the current RTL. Pressing purchase with quantity zero or stock zero does not produce a separate out-of-stock message or complete a purchase.

### 8.3 Complete a first purchase

Follow this small scenario to avoid the balance-width limitation and to give each step an observable result:

1. Reset using SW0, then return SW0 low.
2. Set SW1 high for administrator mode. Select only product 1 (`sw_p = 0001`).
3. Press BTN0 twice to set its price to 2. Press BTN2 three times to set stock to 3. Check the LCD's administrator price and quantity fields.
4. Turn all product switches off, then set SW1 low for user mode. Press BTN1 once to add 10 units. The BCD balance outputs should represent 0010.
5. Select product 1. Press BTN0 twice to request two units. Check that the requested quantity is 2 and the total price is 4.
6. Press BTN2. The design should deduct 4 from the balance, reduce stock from 3 to 1, and show `SUCCESS!`. The balance should become 6, and the requested quantity and purchase total are cleared by the purchase operation. Keep user mode and product 1 selected, leave the buttons released, and wait for the normal product display to return after roughly five seconds.
7. Turn all product switches off and press BTN2 to clear the remaining balance. This clears a register; no physical refund device is controlled.
8. Select product 1, press BTN0 once, and press BTN2. With a zero balance and price 2, the expected status is `NOT ENOUGH MONEY`, with stock unchanged. Keep user mode and product 1 selected until the normal product display returns. The failed purchase retains the requested quantity and total; press BTN1 once to return both to zero before the next check.
9. Enable more than one product switch in user mode. The expected LCD warning is `ONLY_1_SWITCH_ON`. Return to a valid selection before the next transaction.
10. Reset again and verify that prices, stock, and balance are cleared.

Treat these as expected source-level behaviors to verify, not a record of completed board tests. Record any discrepancy with its exact input sequence and waveform or hardware observation.

### 8.4 Cancel, change products, and repeat

1. If a success or insufficient-funds message is active, keep the same product selected in user mode and wait for the normal product display. The status counter advances only in the user-mode branch with a valid selected product. Turning all product switches off, choosing an invalid selection, or entering administrator mode pauses that counter.
2. To cancel an uncompleted quantity, keep the current product selected and press/release BTN1 until the LCD shows `Count:0 Price:0`. This clears the request, not the balance or stock.
3. Turn the current product switch off before turning the next product switch on. Select the new quantity only after the new product's normal display appears. Changing switches alone does not recalculate or clear a pending total.
4. To add balance, first clear any pending quantity as above, then turn all product switches off in user mode. Use BTN0 for 5 units or BTN1 for 10 units. To clear the balance, use BTN2 in this same no-product state.
5. For a repeatable fresh demonstration, use SW0 to reset and then configure the prices and stock again. Administrator BTN3 clears only the selected product's price and stock; it is not a global reset.

The approximately five-second period is a status display, not an enforced input lockout. The RTL still processes buttons during it, and a new transaction can reuse status-counter state. Waiting without changing controls is the procedure used here to keep observations repeatable. Do not infer an exact countdown duration from a single character on the LCD.

### 8.5 Record verification results

For each test, record the source revision or local changes, Vivado version, FPGA part, board revision, peripheral wiring, starting values, button/switch sequence, and observed result. The scenario above covers administrator setup, deposit, a successful purchase, balance clearing, insufficient funds, invalid selection, and global reset. Separately check each of the four product switches and the administrator decrease/clear controls before demonstrating all products. Compile and run a dedicated top-level testbench before claiming automated coverage of these operations.

## 9. Known limitations

- **Balance width:** `money` is 8 bits, so its representable range is 0 to 255. Conditions comparing it with 9995 or 9990 do not protect against overflow at 255. Keep manual examples below that boundary. The thousands digit will remain zero for representable balances.
- **Debounce threshold:** `20'd1250000` cannot fit in 20 bits and truncates to 201424. At 125 MHz, this is approximately 1.61 ms of counter time, not the intended 10 ms. Fixing it requires an RTL change and separate validation.
- **LCD port width:** `top_button_handler` supplies a 2-bit `flag_counter` to a 1-bit LCD input. That LCD input is currently unused.
- **Unused money input:** `update_money` is constrained but never referenced in the controller logic. Balance changes come from the buttons in the no-product user state.
- **Incomplete testbench:** the existing LCD testbench leaves three inputs unconnected, uses a 100 MHz clock, contains legacy character payloads, and stops at 1.01 microseconds without assertions.
- **Selection changes during a purchase:** the requested quantity and calculated price are not automatically cleared whenever `sw_p` changes. Follow section 8.4 before switching products. The purchase branch does not recheck that the requested quantity is at most the selected product's stock, so a stale quantity can underflow the stock register. Entering administrator mode clears the pending quantity and total, but does not reset the status counter.
- **Status handling:** the status timer advances only while a valid product is selected in user mode. Button events are still processed during a status display. Keep the mode and selection unchanged and wait without pressing buttons for the manual sequence in section 8.
- **Zero initial prices and stock:** reset initializes both to zero. Set a price and add stock in administrator mode before demonstrating a purchase; stocked products with a zero price can be purchased for zero.
- **Price decrease boundary:** the administrator decrement action stops at 1. Use BTN3 to clear a price to zero; that action also clears stock.
- **Display and peripheral timing:** the LCD uses fixed delays and never reads the busy flag. Compatibility with the actual LCD's initialization, clear-command, and refresh timing must be verified. The repository does not include a full external circuit schematic.
- **Outputs during reset:** the top-level reset branch does not assign `led` or the BCD digit outputs. Their initial values can be unknown in simulation, or they can retain values from before a later reset. The BCD digits update from the cleared balance after reset is released; the LEDs may retain their previous state until the status logic assigns them again. Do not use an all-off LED state as proof of reset.
- **Prototype scope:** there is no physical dispensing actuator, coin detector, payment gateway, change-return actuator, nonvolatile stock storage, or full system regression suite.

## 10. Troubleshooting and maintenance

| Symptom | What to check |
| --- | --- |
| Git is not recognized | Install Git, reopen the terminal, and run `git --version`. |
| Requested FPGA part is unavailable | Modify the Vivado installation to include Zynq-7000 device support. |
| Source file cannot be found | Check the Tcl `pwd` value and confirm that it is the clone root before creating the project. |
| Simulation ends almost immediately | The supplied testbench calls `$stop` at 1,010 ns; follow section 5 to inspect beyond it. |
| Compile/elaboration or synthesis warnings | Inspect the exact message and compare it with section 9; do not hide warnings as a substitute for reviewing them. |
| LCD is blank or garbled | Verify reset, actual board clock, 8-bit data order, RS/RW/EN wiring, voltage compatibility, contrast, and LCD timing requirements. |
| Buttons appear inactive | Return reset low, select the correct mode and product state, allow settling time, and inspect the debounce signals in simulation. |
| A status message seems paused | Return to user mode with the same valid product selected and wait without pressing buttons. The status counter pauses outside that branch. |
| Price or quantity follows the wrong product | Clear the pending quantity using section 8.4 before changing product switches. Check the known stale-selection limitation. |
| Product cannot be purchased | Add stock, set the price, request a nonzero quantity, and confirm sufficient balance. |
| Balance wraps unexpectedly | The balance is 8 bits; review the overflow limitation above. |
| Seven-segment display is incorrect | The outputs are BCD values; check the external decoder and display wiring. |
| No FPGA appears in Hardware Manager | Check USB data capability, power, cable drivers, and target connection. |

Before submitting changes, inspect `git diff --check` and `git diff`, then perform the simulation and hardware checks appropriate to the modified logic. Keep generated Vivado files in `build/`. Use English for all comments, documentation, README content, and setup instructions. Keep this guide synchronized with the actual tool requirements, source files, constraints, commands, and observed limitations.
