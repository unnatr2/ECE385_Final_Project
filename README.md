# ECE385 - Digital Systems Laboratory Final Project: FPGAudacity

For our ECE 385 Final Project, we explored Digital Signal Processing on the DE2 FPGA board by creating a basic hardware implementation of the popular open-source audio editor, Audacity. In summary, we implemented basic audio recording, playback and filtering. For example, we can broadcast voice, playback recordings, and layer effects on top of music for an enhanced playback experience.
For our design, we used several audio filtering algorithms and implemented them in hardware using SystemVerilog. We decided not to work with the NIOS II Processor since our project works with audio and the NIOS II Processor is significantly slower than the hardware implementation. We worked with the provided Audio Interface and included it in our design. We created our own SDRAM controller that enables audio recording and playback. We also used forward and inverse fast fourier transform modules from OpenCores.org to allow digital signal processing in the frequency domain. We worked on multiple filters like low/high pass filter, reverb, inversion and pitch.
To implement our full design, we needed access to a microphone and headphones/speaker compatible with the DE2 FPGA. No additional hardware is required as all input for settings/adjustments can be made using the on-board switches and push-buttons.

# Building Instructions

To build this project, we recommend using Quartus Prime Lite 18.0, which can be downloaded from Intel's official site. In Quartus, make `toplevel.sv` the toplevel entitiy and run `Compile`. Finally, program the `.sof` files onto a compatible DE2-115 FPGA.

# Usage Instructions

The project will read audio from the WM8731 Microphone Input and provide output on Line Out. Modes can be selected using the following switches:
- `SW0`: Volume
- `SW1`: Low-Pass filtering
- `SW2`: High-Pass filtering
- `SW3`: Reverberation (not fully functional)
- `SW4`: Signal Inversion
- `SW5`: Pitch shifting
- `SW17`: Recording and Playback
  - Holding `KEY3` will record incoming samples from line in
  - Holding `KEY2` will play back previously recorded samples from SDRAM
  - Pressing `KEY1` will clear all previous recordings in the first 30s of SDRAM memory.
  
All other modes use `KEY3` as a universal "decrementer" of the current setting and `KEY2` as an "incrementer". `KEY1` is used as an on/off toggle.


![image](https://i.gyazo.com/162e5b1d1189f6a7ff9d0a8a1de7c3bf.png)
