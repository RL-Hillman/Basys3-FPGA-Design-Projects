/*
 * main.c
 *
 * Traffic Light Controller System on MicroBlaze.
 *
 * This program connects the software running on the MicroBlaze
 * to a custom AXI4-Lite VHDL IP that contains the traffic-light FSM.
 *
 * Software responsibilities:
 * - Read the physical switches using AXI GPIO 0.
 * - Write the switch value to register 2 of the custom IP.
 * - Read the current FSM state from register 0 of the custom IP.
 * - Read the current LED output from register 1 of the custom IP.
 * - Display the current FSM state on the 7-Segment display using AXI GPIO 1.
 * - Print system updates to the UART terminal.
 *
 * Important:
 * The traffic LEDs are driven directly by the custom IP hardware.
 * The MicroBlaze only reads their value for monitoring and printing.
 *
 * Custom IP AXI4-Lite register mapping:
 *
 * Register address 0: OUTPUT: bits (2,1,0): FSM state
 *                     000: DEFAULT_A, 001: DEFAULT_B, 010: DEFAULT_C,
 *                     011: A_ON, 100: AB_ON, 101: B_ON, 110: C_ON
 *
 * Register address 1: OUTPUT: bits (15,8,0): LED(15)=A, LED(8)=C, LED(0)=B
 *
 * Register address 2: INPUT:  bits (15,9,8,7,6,0): switches / car sensors
 *                     SW8 or SW9   -> request A
 *                     SW6 or SW7   -> request B
 *                     SW15 or SW0  -> request C
 *
 * Register address 3: N/A
 *
 * Created on: 18 May 2026
 * Author: Harel
 */

#include "xil_io.h"
#include "xparameters.h"
#include "xgpio.h"
#include "xstatus.h"
#include "xil_printf.h"
#include "sleep.h"
#include "xuartlite.h"

/*
 * Custom IP base address and register offsets.
 *
 * The custom traffic_fsm IP is memory-mapped into the MicroBlaze address space.
 * Xil_In32 and Xil_Out32 are used to read and write its AXI4-Lite registers.
 */
#define TRAFFIC_BASE_ADDR       XPAR_TRAFFIC_FSM_0_S00_AXI_BASEADDR

#define TRAFFIC_STATE_OFFSET    0x00
#define TRAFFIC_LEDS_OFFSET     0x04
#define TRAFFIC_SWITCH_OFFSET   0x08
#define TRAFFIC_UNUSED_OFFSET   0x0C

#define SW_ID		XPAR_GPIO_0_DEVICE_ID
#define SEG7_ID		XPAR_GPIO_1_DEVICE_ID
#define UART_ID		XPAR_UARTLITE_0_DEVICE_ID

#define SW_CHANNEL  1
#define SEG7_DISP_CHANNEL 1
#define SEG7_AN_CHANNEL  2

XGpio SW;
XGpio seg7;
XUartLite uart;

//Function prototypes
int Initialize(void);
u32 ReadSwitches(void);
void WriteSwitches(u32 sw_value);
u32 ReadLeds(void);
u32 ReadState(void);
void put7SEG(u8 anode, u8 dis);
u8 Decode7Seg(char c);
void Write7SEG(const char *word);
const char* DecodeStateToWord(u32 state);
void DecodeState(u32 state);
void DecodeLeds(u32 leds);
void DecodeSw(u32 sw_value);
void PrintStatusIfChanged(u32 state, u32 leds, u32 sw);

/*
 * Initialize all hardware peripherals used by the system.
 *
 * The function initializes:
 * - AXI GPIO for switches.
 * - AXI GPIO for the 7-Segment display.
 * - UART-Lite for terminal communication.
 *
 * It also sets the GPIO directions:
 * - Switches are inputs.
 * - 7-Segment segments and anodes are outputs.
 *
 * Finally, it clears the switch input register inside the custom IP
 * and turns off the 7-Segment display at startup.
 *
 * Returns:
 * XST_SUCCESS if all peripherals were initialized correctly.
 * XST_FAILURE if one of the initializations failed.
 */
int Initialize(void) {
	int status;

	status = XGpio_Initialize(&SW, SW_ID);

	if (status != XST_SUCCESS) {
		xil_printf("ERROR: DIP SWITCHES initialization failed\r\n");
		return XST_FAILURE;
	}

	status = XGpio_Initialize(&seg7, SEG7_ID);

	if (status != XST_SUCCESS) {
		xil_printf("ERROR: seg7 initialization failed\r\n");
		return XST_FAILURE;
	}

	status = XUartLite_Initialize(&uart, UART_ID);

	if (status != XST_SUCCESS) {
		xil_printf("ERROR: uart initialization failed\r\n");
		return XST_FAILURE;
	}

	XGpio_SetDataDirection(&seg7, SEG7_AN_CHANNEL, 0x00000000);
	XGpio_SetDataDirection(&seg7, SEG7_DISP_CHANNEL, 0x00000000);

	XGpio_SetDataDirection(&SW, SW_CHANNEL, 0xFFFFFFFF);

	// Start the custom IP with no active switches.
	Xil_Out32(TRAFFIC_BASE_ADDR + TRAFFIC_SWITCH_OFFSET, 0x00000000);

	// Turn off 7-segment display at startup.
	XGpio_DiscreteWrite(&seg7, SEG7_DISP_CHANNEL, 0xFF);
	XGpio_DiscreteWrite(&seg7, SEG7_AN_CHANNEL, 0x0F);

	return XST_SUCCESS;
}

//Read the current switches value
u32 ReadSwitches(void) {
	return XGpio_DiscreteRead(&SW, SW_CHANNEL);
}

//Write the switch value to the custom IP.
void WriteSwitches(u32 sw_value) {
	Xil_Out32(TRAFFIC_BASE_ADDR + TRAFFIC_SWITCH_OFFSET, sw_value & 0x0000FFFF);
}

//Read the current LED output value from the custom IP.
u32 ReadLeds(void) {
	return Xil_In32(TRAFFIC_BASE_ADDR + TRAFFIC_LEDS_OFFSET) & 0x0000FFFF;
}

//Read the current FSM state from the custom IP.
u32 ReadState(void) {
	return Xil_In32(TRAFFIC_BASE_ADDR + TRAFFIC_STATE_OFFSET) & 0x00000007;
}

/*
 * Write one digit to the 7-Segment display.
 *
 * anode selects which digit is currently active.
 * dis contains the segment pattern for that digit.
 */
void put7SEG(u8 anode, u8 dis)

{
	XGpio_DiscreteWrite(&seg7, SEG7_AN_CHANNEL, anode);
	XGpio_DiscreteWrite(&seg7, SEG7_DISP_CHANNEL, dis);

}

/*
 * Convert a character into a 7-Segment display pattern.
 *
 * The Basys 3 7-Segment display is active-low:
 * 0 turns a segment ON, 1 turns a segment OFF.
 */
u8 Decode7Seg(char c) {
	switch (c) {
	case 'A':
		return 0x88;
	case 'B':
		return 0x80;
	case 'C':
		return 0xC6;
	case '.':
		return 0x7F;
	default:
		return 0xFF;
	}
}

/*
 * Display a 4-character word on the 7-Segment display.
 *
 * The function multiplexes the display by enabling one digit at a time.
 * Calling this function repeatedly creates the visual effect of showing
 * all four characters at once.
 */
void Write7SEG(const char *word) {
	put7SEG(0x0E, Decode7Seg(word[3]));
	usleep(2000);

	put7SEG(0x0D, Decode7Seg(word[2]));
	usleep(2000);

	put7SEG(0x0B, Decode7Seg(word[1]));
	usleep(2000);

	put7SEG(0x07, Decode7Seg(word[0]));
	usleep(2000);

}

/*
 * Convert the current FSM state into a 4-character word
 * for the 7-Segment display.

 */
const char* DecodeStateToWord(u32 state) {
	switch (state & 0x7) {
	case 0:
		return "A   ";   // DEFAULT_A
	case 1:
		return "B   ";   // DEFAULT_B
	case 2:
		return "C   ";   // DEFAULT_C
	case 3:
		return "A   ";   // A_ON
	case 4:
		return "A..B";   // AB_ON
	case 5:
		return "B   ";   // B_ON
	case 6:
		return "C   ";   // C_ON
	default:
		return "....";   // invalid / unknown
	}
}

/*
 * Print the current FSM state name to the UART terminal.
 *
 * This function decodes the numeric state value read from register 0
 * into a readable state name.
 */
void DecodeState(u32 state) {
	xil_printf("THE CURRENT STATE IS:\r\n");

	switch (state & 0x7) {
	case 0:
		xil_printf("DEFAULT_A\r\n");
		break;
	case 1:
		xil_printf("DEFAULT_B\r\n");
		break;
	case 2:
		xil_printf("DEFAULT_C\r\n");
		break;
	case 3:
		xil_printf("A_ON\r\n");
		break;
	case 4:
		xil_printf("AB_ON\r\n");
		break;
	case 5:
		xil_printf("B_ON\r\n");
		break;
	case 6:
		xil_printf("C_ON\r\n");
		break;
	default:
		xil_printf("ERROR NO STATE WAS RECOGNIZED!\r\n");
		break;
	}
}

/*
 * Decode and print the active traffic light according to the LED bits.
 *
 * LED mapping:
 * - LED15 represents traffic light A.
 * - LED8  represents traffic light C.
 * - LED0  represents traffic light B.
 *
 */
void DecodeLeds(u32 leds) {
	u8 a_on = (leds & (1 << 15)) ? 1 : 0;
	u8 c_on = (leds & (1 << 8)) ? 1 : 0;
	u8 b_on = (leds & (1 << 0)) ? 1 : 0;

	if (a_on && b_on && !c_on)

		xil_printf("LED(15)=A and LED(0)=B ON\r\n");

	if (a_on && !b_on && !c_on)

		xil_printf("LED(15)=A ON\r\n");

	if (!a_on && b_on && !c_on)
		xil_printf("LED(0)=B ON\r\n");

	if (!a_on && !b_on && c_on)
		xil_printf("LED(8)=C ON\r\n");

	if (!a_on && !b_on && !c_on)
		xil_printf("ERROR NO TRAFFIC LIGHT IS ON\r\n");

}

/*
 * Decode and print the active car sensors.
 *
 * The sensors are represented by selected switch bits:
 * - SW15: West  -> East
 * - SW9 : West  -> South
 * - SW8 : South -> West
 * - SW7 : South -> East
 * - SW6 : East  -> South
 * - SW0 : East  -> West
 */
void DecodeSw(u32 sw_value) {
	sw_value &= 0x0000FFFF;

	xil_printf("Switches raw value: 0x%04X\r\n", (unsigned int) sw_value);

	xil_printf("Active sensors:\r\n");

	if (sw_value & (1 << 15))
		xil_printf("SW15 West->East\r\n");

	if (sw_value & (1 << 9))
		xil_printf("SW9 West->South\r\n");

	if (sw_value & (1 << 8))
		xil_printf("SW8 South->West\r\n");

	if (sw_value & (1 << 7))
		xil_printf("SW7 South->East\r\n");

	if (sw_value & (1 << 6))
		xil_printf("SW6 East->South\r\n");

	if (sw_value & (1 << 0))
		xil_printf("SW0 East->West\r\n");

	if ((sw_value
			& ((1 << 15) | (1 << 9) | (1 << 8) | (1 << 7) | (1 << 6) | (1 << 0)))
			== 0)
		xil_printf("NO CAR DETECTED\r\n");

	xil_printf("\r\n");
}

/*
 * Print system status only when the FSM state or switch input changes.
 *
 * If the current state or switch value is different from the previous one,
 * the function prints:
 * - Active switch sensors.
 * - Current FSM state.
 * - Current LED register value.
 * - Active traffic light.
 *
 * This prevents the UART terminal from being flooded with repeated prints
 * while the system remains in the same state and the switches do not change.
 */
void PrintStatusIfChanged(u32 state, u32 leds, u32 sw) {
	static u32 last_state = 0xFFFFFFFF;
	static u32 last_sw = 0xFFFFFFFF;

	state &= 0x7;
	leds &= 0x0000FFFF;
	sw &= 0x0000FFFF;

	if ((state != last_state) || (sw != last_sw)) {

		xil_printf("\r\n--- FSM UPDATE ---\r\n");
		DecodeSw(sw);
		DecodeState(state);

		xil_printf("LEDs raw value: 0x%04X\r\n", (unsigned int) leds);
		xil_printf("Active traffic light:\r\n");
		DecodeLeds(leds);

		last_state = state;
		last_sw = sw;
	}
}

/*
 * Main program loop.
 *
 * The program runs forever.
 *
 * Each loop iteration:
 * 1. Reads the physical switches from AXI GPIO 0.
 * 2. Writes the switch value to register 2 of the custom IP.
 * 3. Reads the current FSM state from register 0.
 * 4. Reads the LED output from register 1.
 * 5. Updates the 7-Segment display according to the current state.
 * 6. Prints a UART update only when the FSM state or switch input change.
 */
int main(void) {

	u32 sw_value;
	u32 leds;
	u32 state;

	if (Initialize() != XST_SUCCESS) {
		return -1;
	}

	xil_printf("\r\n");
	xil_printf("====================================\r\n");
	xil_printf(" Traffic Light Controller Started\r\n");
	xil_printf("====================================\r\n");
	while (1) {

		sw_value = ReadSwitches();
		WriteSwitches(sw_value);

		state = ReadState();
		leds = ReadLeds();

		Write7SEG(DecodeStateToWord(state));

		PrintStatusIfChanged(state, leds, sw_value);

	    usleep(1000);

	}

}

