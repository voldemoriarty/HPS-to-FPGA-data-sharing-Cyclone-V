# HPS <-> FPGA Data Sharing Cyclone V 

![HPSOverview](pics/hpsoverview.png)

The ARM HPS (Hard Processor System) is has 3 main interfaces to communicate with the FPGA
1. **H2F AXI Bus:** For accessing FPGA peripherals from the HPS. Configurable width: 32, 64, 128 bits. Provides 960 MB of address space.

2. **F2H AXI Bus:** For accessing HPS peripherals from the FPGA. Configuarble width: 32, 64, 128 bits. Provides 960 MB of address space.

3. **F2S AXI / Avalon Bus:** For accessing external DDR SDRAM using the Hard Memory Controller present in the HPS from the FPGA. Supports upto 6 masters with read/write and burst support. Configurable width: 32, 64, 128, 256 bits AXI / Avalon. Provides 4 GB address space all mapped to the DDR SDRAM. 

4. **H2F Lightweight AXI Bus:** 32 bit small AXI bus with low bandwidth. Used to access peripherals in the FPGA from HPS. Its low performance nature makes it suitable for accessing simple CSRs. Provides 2 MB of address space.

# Interfaces Memory Map

The above described buses are accessed through load and store instruction in the HPS because of their memory mapped nature.

![AddressMap](pics/map.png)

- The FPGA sees the the address space titled "L3" in the above figure when looking through the F2H AXI interface
- The ARM sees the address space titled "MPU" in the above figure. The "FPGA Slaves Region" corresponds to H2F AXI interface addresses. The "Peripheral Region" is the address space of peripherals connected to the L3 and L4 buses. The H2F Lightweight AXI bus is itself a peripheral of the HPS so it's addresses appear in the Peripheral Region
- The ACP (Accelerator Coherency Port) is a 1GB window that accesses the SDRAM through the ARMs L2 Cache. The window is slideable on any Gigabyte aligned boundary.
- The FPGA sees the address space titled "SDRAM" when looking the F2S interfaces. The entire 4GB space is directly mapped to physical SDRAM address space (no virtualization). It is possible to restrict the FPGA accesses to a certain portion by modifying appropriately the *memory protection table* in the CSRs of the SDRAM Controller. The Controller AXI ports support ARM TrustZone protection. Avalon ports are configured for port level protection (whatever that means).

# Accessing SDRAM from the FPGA
DDR SDRAM can be accessed through the following routes
- **F2H (with or without ACP):** Useful for low bandwidth data transfers or cache coherent applications
- **F2S:** Useful for high bandwidth transfers (such as feeding data to an accelerator)


# Example Project: Matrix Multiplication
<!-- TODO: Complete links -->
An example project is provided which feeds a matrix multiplication accelerator with data from the SDRAM. The accelerator is configured for 5x5 16 bit integer matrix multiplication. It has 3 streaming ports (2 16 bit input, 1 32 bit output). The ports are pin compatible with Avalon-ST interface. This guide assumes a Linux based OS with commands run on the `embedded_shell`. The hardware that we will run on is the DE10 Nano. It should be trivial to port it to other SoC boards.

## Step 1: Get Required Files
- The GHRD (Golden Hardware Reference Design) contains a configured project with all the pin assignments and HPS configuration necessary. It also contains a makefile that makes building software easy.

- Accelerator RTL (PeStream.v) (Get it from this link: )


## Step 2: Create a Quartus Project
- Create a directory in which we will work on the project. In this directory create a `hardware` directory. Create a new Quartus project in the hardware named `de10nanoTop`. Select Cyclone V `5CSEBA6U23I7` as the device. The project summary window should match what is shown below:

  ![Project_Summary](pics/project_summary.png)

- Copy the accelerator RTL (`PeStream.v`) to the `hardware` directory
- Also copy the `Makefile` and `soc_system.qsys` files to the `hardware` directory. Your directory structure should look like this:
  ```
  .
  ├── db
  ├── de10nanoTop.qpf
  ├── de10nanoTop.qsf
  ├── Makefile
  ├── PeStream.v
  └── soc_system.qsys
  ```

## Step 3: Creating a Qsys Component for the Accelerator
Qsys is used to create and manage interconnections between HPS and FPGA. Hence we must create a Qsys component for our accelerator to be able to connect it with the HPS. 

- Open Qsys from the Quartus window (In newer versions Qsys is renamed to *Platform Designer*). Open `soc_system.qsys` when prompted. You should see the following window

  ![QsysInit](pics/qsys_init.png)
- In the *IP Catalog* tab click on the *New*. In the window that opens, fill the data as shown below

  ![Qsys1](pics/tcl_1.png)

- Next in the *Files* tab add the `PeStream.v` to the synthesis files and click the *Analyze Synthesis Files* button. Then choose `PeStream` as the top level. In the simulation section, click *Copy from Synthesis* button. Your output should match the image shown below

  ![Qsys2](pics/tcl_2.png)

- Next in the *Signals & Interfaces* tab you will assign "roles" to the top level ports of the accelerator. The accelerator has 3 streaming interfaces each with `ready`, `valid` and `payload` signals. These are directly pin compatible with Avalon-ST so now we will tell Qsys about it. In the beginning all the pins would be under a `avalon_slave_0` category as shown in the picture below:
  
  ![Qsys3](pics/tcl_3.png)

  Create 2 Avalon Streaming Sinks and 1 Avalon Streaming Source by clicking the *<\<add interface>>* label. Name the 2 sinks *streamA* and *streamB* by clicking the interface and pressing `F2` key or editing the *Name* Text box. Name the source *streamR*. Drag and drop the `streamA_*` to streamA, `streamB_*` signals to streamB and `streamR_*` signals to streamR. Delete the now empty `avalon_slave_0` by right click > Remove. Your window should match the picture shown below:

  ![Qsys3.1](pics/tcl_3_1.png)

- Now click each streamA interface and set the *Signal Type* of each signal as following shows:
  - `payload` -> `data`
  - `ready` -> `ready`
  - `valid` -> `valid`
  
  Also set the *Assosiated Reset* of each interface to "reset" in the dropdown menu.

  After doing each interface, all the errors and warnings should disappear and your window should match the image shown below:

  ![Qsys3.2](pics/tcl_3_2.png)

- Click Finish and save to complete the process. Now the accelerator should show up as an IP in the *IP Catalog*.

  ![IPNew](pics/ip_new.png)

- This process will create a file named `PeStream_hw.tcl` in the `hardware` directory. This TCL file is what Qsys uses to identify custom components

## Step 4: Cleaning up the Qsys System
Remove the *JTAG to Avalon Master* peripherals and "minimize" everything except the `hps` and `clk`. This helps to reduce the clutter on the screen. Your screen should look like the one below:

  ![QsysClean](pics/qsys_clean.png)

## Step 5: Configuring HPS Interfaces
Since our goal is to use SDRAM as the data storage location, we will enable 3 F2S interfaces. 2 of them for read only and 1 of them for write only. We will use Avalon Bus.

- Double click the HPS to open parameters window
- Edit the *AXI Bridges* and *FPGA-HPS SDRAM Interface* sections to match what is shown in the following picture

  ![Bridges](pics/bridges_cfg.png)

- Back in Qsys click System > Remove Dangling Connections

## Step 6: Adding Accelerator and DMAs
We will store the matrices in DDR memory and use a DMA to stream the data to and from the accelerator. The Altera mSGDMA (modular Scatter Gather DMA) will be used for the task as it can read from memory and streams. It also supports bursting and request queues. We need 3 DMAs; one for each Avalon interface of the accelerator. We will control the DMAs using the HPS Lightweight AXI interface. 

- Search for `msgdma` in the IP Catalog and add it

  ![DMAIP](pics/msgdma_ip.png)

- Since the two sinks in the accelerator take 16 bit data, we should configure the DMA appropriately. Set the options as shown in the picture below. Only change the settings in the *DMA Settings* section of the dialog.

  ![DMAINCFG](pics/in_dma_cfg.png)

- Once it has been added, right click it and click *Duplicate* to create another with the same config. Rename them to "streamA_DMA" and "streamB_DMA".
- Duplicate one of the DMAs again and modify it appropriately for the streaming source of the acclerator. Name it "streamR_DMA". The settings are shown in the picture below

  ![DMAOUTCFG](pics/dma_out_cfg.png)

- Now the Qsys system should look something like this:

  ![QSYSNoCONN](pics/qsys_no_conn.png)

## Step 7: Connecting with HPS
- Connect all the missing `clock` and `reset` ports with the `clock` and `reset` lines of the clock component. After this all errors should disappear and only warnings should be left.

- Connect the `csr` and `descriptor_slave` ports of each DMA to the H2F Lightweight AXI bus. These are the interfaces used to control the DMAs. Then click System > Assign Base Addresses. If an error appears that says `Error: soc_system.hps_0.h2f_lw_axi_master: streamR_DMA.csr (0x1000000..0x100001f) is outside the master's address range (0x0..0x1fffff)` then edit the streamA_DMA's CSR base address by double clicking the relevant column to `0x0004_0040` and click the lock to lock this address. Then click System > Assign Base Addresses again. This should fix the errors. If it doesn't you'll have to manually provide the addresses and lock them. The system should look like this

  ![LWCONN](pics/lw_conn.png)

- Now connect the streamA and streamB DMAs `mm_read` port to the `f2h_sdram` ports on the HPS. `f2h_sdram0` and `f2h_sdram1` are the read only ports so we connect them to it. 
- Connect `mm_write` port of streamR DMA to `f2h_sdram2` write only port.
- Now the system should look like below:

  ![DMACONN](pics/dma_conn_done.png)

## Step 8: Adding the accelerator
- Finally add the accelerator to the system
- Connect the st-source and sinks from the DMAs to the corresponding ports in the accelerator. The system should look like as shown in the picture

  ![FINALQSYS](pics/final_qsys.png)

  We will not be connecting the DMA interrupts for now

## Step 9: Finalizing
- Save the system and click the Generate Button
- Uncheck *Create Block Symbol File* option and click Generate

## Step 10: Creating a Top Level Module 
The generate step created the RTL files in the `soc_system` directory. Now we must instantiate the component in our top level component. 

- Create a new verilog file in Quartus named `de10nanoTop.v`
- Add the following code to it