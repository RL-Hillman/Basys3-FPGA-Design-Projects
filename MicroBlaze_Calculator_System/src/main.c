/*
 * main.c
 *
 *  This program implements a calculator system on the Basys 3 board.
 *
 * Hardware used:
 * - AXI GPIO for switches and LEDs
 * - AXI GPIO for 7-Segment display
 * - AXI GPIO for push buttons
 * - AXI UART-Lite for terminal communication
 *
 * Operating modes are selected using SW15 and SW0:
 * - 00: Mode selection screen and LED pattern
 * - 10: Simple Calculator   (ADD / SUB)
 * - 01: Advanced Calculator (ADD / SUB / MUL / DIV)
 * - 11: Invalid mode, user is asked to return to 00
 *
 *
 *  Created on: 21 Apr 2026
 *      Author: Harel
 */

#include "xparameters.h"
#include "xgpio.h"
#include "xstatus.h"
#include "xil_printf.h"
#include "sleep.h"
#include "xuartlite.h"

#define SW_LEDS_ID   	XPAR_AXI_GPIO_0_DEVICE_ID
#define SEG7_ID      	XPAR_AXI_GPIO_1_DEVICE_ID
#define BUTTONS_ID    	XPAR_AXI_GPIO_2_DEVICE_ID
#define UART_ID			XPAR_AXI_UARTLITE_0_DEVICE_ID

#define SW_CHANNEL       1
#define LEDS_CHANNEL     2

#define SEG7_AN_CHANNEL  1
#define SEG7_DISP_CHANNEL 2

#define BUTTONS_CHANNEL  1

XGpio sw_leds;
XGpio seg7;
XGpio buttons;
XUartLite uart;

//Function prototypes
int Initialize(void);
u32 ReadSwitches(void);
void ReadSwMode(u32 *sw_value, u32 *sw_simple, u32 *sw_advanced);
void WriteLeds(u32 value);
void LedPatt(void);
void Write7SEG(char word[]);
void put7SEG(u8 anode, u8 dis);
u8 Decode7Seg(char c);
u32 ReadButtons(void);
int UartTryGetChar(char *c);
void UartSendChar(char c);
int ProcessInputChar(char c, char *buf, int *idx, float *value);
void simpleCalc(void);
void advancedCalc(void);
void UartSendUnsignedInt(u32 value);
void UartSendFloat3(float value);
void ClearScreen(void);



/*
 * Initialize all hardware peripherals used by the system.
 *
 * - GPIO for switches and LEDs
 * - GPIO for 7-Segment display
 * - GPIO for push buttons
 * - UART-Lite for terminal communication
 *
 * It also sets the GPIO direction for each channel.
 *
 * Returns:
 * XST_SUCCESS if all peripherals were initialized correctly.
 * XST_FAILURE if one of the initializations failed.
 */

int Initialize(void) {
	int status;

	status = XGpio_Initialize(&sw_leds, SW_LEDS_ID);

	if (status != XST_SUCCESS) {
		xil_printf("ERROR: sw_leds initialization failed\r\n");
		return XST_FAILURE;
	}

	status = XGpio_Initialize(&seg7, SEG7_ID);

	if (status != XST_SUCCESS) {
		xil_printf("ERROR: seg7 initialization failed\r\n");
		return XST_FAILURE;
	}

	status = XGpio_Initialize(&buttons, BUTTONS_ID);

	if (status != XST_SUCCESS) {
		xil_printf("ERROR: buttons initialization failed\r\n");
		return XST_FAILURE;
	}

	status = XUartLite_Initialize(&uart, UART_ID);

	if (status != XST_SUCCESS) {
		xil_printf("ERROR: uart initialization failed\r\n");
		return XST_FAILURE;
	}

	XGpio_SetDataDirection(&sw_leds, SW_CHANNEL, 0xFFFFFFFF);
	XGpio_SetDataDirection(&sw_leds, LEDS_CHANNEL, 0x00000000);

	XGpio_SetDataDirection(&seg7, SEG7_AN_CHANNEL, 0x00000000);
	XGpio_SetDataDirection(&seg7, SEG7_DISP_CHANNEL, 0x00000000);

	XGpio_SetDataDirection(&buttons, BUTTONS_CHANNEL, 0xFFFFFFFF);

	return XST_SUCCESS;
}

//Read the current push button value
u32 ReadButtons(void) {
	return XGpio_DiscreteRead(&buttons, BUTTONS_CHANNEL);
}

//Read the current switches value
u32 ReadSwitches(void) {
	return XGpio_DiscreteRead(&sw_leds, SW_CHANNEL);
}


//reads sw15 and sw0 value
void ReadSwMode(u32 *sw_value, u32 *sw_simple, u32 *sw_advanced)
{
    *sw_value = ReadSwitches();

    *sw_simple = (*sw_value >> 15) & 0x1;  /* SW15 */
    *sw_advanced = *sw_value & 0x1;        /* SW0  */
}


//Write a value to the board LEDs
void WriteLeds(u32 value) {
	XGpio_DiscreteWrite(&sw_leds, LEDS_CHANNEL, value);
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
	case 'D':
		return 0xC0;
	case 'V':
		return 0xC1;
	case 'N':
		return 0xAB;
	case 'S':
		return 0x92;
	case 'I':
		return 0xF9;
	case 'M':
		return 0xC8;
	case 'P':
		return 0x8C;
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
void Write7SEG(char word[]) {
	put7SEG(0x0E, Decode7Seg(word[3]));
	usleep(2000);

	put7SEG(0x0D, Decode7Seg(word[2]));
	usleep(2000);

	put7SEG(0x0B, Decode7Seg(word[1]));
	usleep(2000);

	put7SEG(0x07, Decode7Seg(word[0]));
	usleep(2000);

}


//Clear the UART terminal screen.
void ClearScreen(void)
{
    xil_printf("\033[2J\033[H");

    /*
    * Fallback option if the terminal does not support ANSI escape sequences:
    * print multiple new lines instead of clearing the screen.

    int i;

    for (i = 0; i < 30; i++)
    {
        xil_printf("\r\n");
    }
    */
}


/*
 * Display the LED pattern for mode 00.
 *
 * The pattern starts with the two left LEDs turned on, moves to the right,
 * and then moves back to the left.
 *
 * The function keeps running while the mode is 00.
 * When the user changes SW15 or SW0, the function turns off the LEDs
 * and returns to main().
 */
void LedPatt(void) {

	u32 sw_value;
	u32 sw_simple;
	u32 sw_advanced;
	u32 pattern;
	pattern = 0xC000;

	while (1) {

		while (1)  //right
		{
			ReadSwMode(&sw_value, &sw_simple, &sw_advanced);

			if ((!((sw_simple == 0) && (sw_advanced == 0)) || pattern == 0x0001)) {

				break;
			}
			WriteLeds(pattern);
			usleep(1000000);
			if (pattern == 0x8000){
				pattern = 0xC000;
			} else {
			pattern = pattern >> 1;

			}
		}

		while (1) //left
		{
			ReadSwMode(&sw_value, &sw_simple, &sw_advanced);

			if ((!((sw_simple == 0) && (sw_advanced == 0)) || pattern == 0x8000)) {

				break;
			}
			WriteLeds(pattern);
			usleep(1000000);
			if (pattern == 0x0001) {
				pattern = 0x0003;
			}
			else if (pattern == 0xC000) {
				pattern = 0x8000;
			}
			else {
				pattern = pattern << 1;

			}

		}
		if (!((sw_simple == 0) && (sw_advanced == 0))) {
			WriteLeds(0x0);
			break;
		}
	}
}







// Send one character through UART.
void UartSendChar(char c) {
	u8 temp;

	temp = (u8) c;
    while (XUartLite_Send(&uart, &temp, 1) != 1)
    {
        /* wait until the byte is accepted */
    }
}




/*
 * Print an unsigned integer through UART without using printf.
 *
 * The function extracts the digits from right to left,
 * stores them in a temporary buffer, and then prints them in the correct order.
 */
void UartSendUnsignedInt(u32 value) {
	char buf[10];
	int i;

	if (value == 0) {
		UartSendChar('0');
		return;
	}

	i = 0;

	while (value > 0) {
		buf[i] = (char) ('0' + (value % 10));
		value = value / 10;
		i++;
	}

	while (i > 0) {
		i--;
		UartSendChar(buf[i]);
	}
}


/*Print a floating-point number with 3 digits after the decimal point.
This replaces printf("%.3f"), which uses much more memory*/
void UartSendFloat3(float value) {
	u32 scaled;
	u32 whole;
	u32 frac;

	if (value < 0.0f) {
		UartSendChar('-');
		value = -value;
	}


	scaled = (u32) (value * 1000.0f + 0.5f);

	whole = scaled / 1000;
	frac = scaled % 1000;

	UartSendUnsignedInt(whole);
	UartSendChar('.');

	UartSendChar((char) ('0' + (frac / 100)));
	UartSendChar((char) ('0' + ((frac / 10) % 10)));
	UartSendChar((char) ('0' + (frac % 10)));
}



/*
 * Process one input character received from the UART terminal.
 *
 * The function builds a number inside the input buffer until ENTER is pressed.
 *
 * Supported input:
 * - positive numbers
 * - negative numbers
 * - decimal point
 * - backspace
 *
 * Return values:
 *  1  -> valid number was parsed successfully
 *  0  -> invalid input
 * -1  -> ENTER was pressed on an empty line
 *  2  -> input is still in progress
 */
int ProcessInputChar(char c, char *buf, int *idx, float *value) {
	int i;
	int sign;
	int seen_dot;
	int seen_digit;
	float place;


	/* ENTER was pressed: finish input and try to parse the number */
	if (c == '\r' || c == '\n') {
		UartSendChar('\r');
		UartSendChar('\n');

		if (*idx == 0) {
			return -1;
		}

		buf[*idx] = '\0';

		sign = 1;
		seen_dot = 0;
		seen_digit = 0;
		place = 0.1f;
		*value = 0.0f;

		for (i = 0; i < *idx; i++) {
			if (buf[i] == '-' && i == 0) {
				sign = -1;
			} else if (buf[i] == '.' && seen_dot == 0) {
				seen_dot = 1;
			} else if (buf[i] >= '0' && buf[i] <= '9') {
				seen_digit = 1;

				if (seen_dot == 0) {
					*value = (*value) * 10.0f + (float) (buf[i] - '0');
				} else {
					*value = *value + ((float) (buf[i] - '0') * place);
					place = place * 0.1f;
				}
			} else {
				*idx = 0;
				*value = 0.0f;
				return 0;
			}
		}

		if (seen_digit == 0) {
			*idx = 0;
			*value = 0.0f;
			return 0;
		}

		*value = (*value) * (float) sign;
		*idx = 0;

		return 1;
	}


	/* BACKSPACE / DELETE: remove the last typed character */
	if (c == 8 || c == 127) {
		if (*idx > 0) {
			(*idx)--;
			UartSendChar(8);
			UartSendChar(' ');
			UartSendChar(8);
		}

		return 2;
	}
	/* Regular character: add it to the input buffer and echo it to terminal */
	if (*idx < 15) {
		buf[*idx] = c;
		(*idx)++;
		UartSendChar(c);
	}

	return 2;
}



/*
 * Try to receive one character from UART without blocking the program.
 *
 * Returns:
 * 1 if a character was received.
 * 0 if no character is available.
 */
int UartTryGetChar(char *c) {
	u8 temp;
	unsigned int received;

	received = XUartLite_Recv(&uart, &temp, 1);

	if (received == 1) {
		*c = (char) temp;
		return 1;
	}

	return 0;
}



/*
 * Calculator input state machine.
 *
 * GET_X          -> waiting for the first operand
 * GET_Y          -> waiting for the second operand
 * WAIT_OPERATION -> waiting and letting button press to choose the operation
 */
typedef enum {
	GET_X, GET_Y, WAIT_OPERATION
} CalcState;



/*
 * Simple Calculator mode.
 *
 * Active mode:
 * SW15 = 1, SW0 = 0
 *
 * The user enters two floating-point operands through UART.
 * The push buttons are then used to select:
 * - ADD
 * - SUB
 *
 * MUL and DIV are not available in this mode.
 * The 7-Segment display blinks the word "SIMP" while the mode is active.
 */
void simpleCalc(void) {
	u32 sw_value;
	u32 sw_simple;
	u32 sw_advanced;
	u32 btn_value;
	u32 counter;
	u8 onoff;

	float x, y, result;
	float parsed_value;
	int input_idx;
	int status;
	char c;
	char input_buf[16];

	CalcState state;
	state = GET_X;

	xil_printf("Simple Calculator (Add/Sub)\r\n");

	counter = 0;
	onoff = 1;
	x = 0;
	y = 0;
	result = 0;
	parsed_value = 0;
	input_idx = 0;

	xil_printf("Please enter first operand X:\r\n");
	xil_printf("Press ENTER to start over\r\n");

	while (1) {

		/* stay if in Simple mode */
		ReadSwMode(&sw_value, &sw_simple, &sw_advanced);


		if (!((sw_simple == 1) && (sw_advanced == 0))) {
			put7SEG(0x0F, 0xFF);
			return;
		}

		/* blink SIMP f=1 Hz  */
		counter++;
		if (counter >= 125) {
			onoff = !onoff;
			counter = 0;
		}

		if (onoff == 1) {
			Write7SEG("SIMP");
		} else {
			put7SEG(0x0F, 0xFF);
			usleep(8000);
		}

		/* non-blocking UART input */
		if (UartTryGetChar(&c)) {
			if (state == GET_X) {
				status = ProcessInputChar(c, input_buf, &input_idx,
						&parsed_value);

				if (status == -1) {
					put7SEG(0x0F, 0xFF);
					return;
				} else if (status == 0) {
					xil_printf(
							"\r\nInvalid input for X. Please enter a valid number:\r\n");
				} else if (status == 1) {
					x = parsed_value;
					xil_printf("\r\nPlease enter second operand Y:\r\n");
					xil_printf(
							"Press ENTER on empty line to choose new numbers\r\n");
					state = GET_Y;
				}
			} else if (state == GET_Y) {
				status = ProcessInputChar(c, input_buf, &input_idx,
						&parsed_value);

				if (status == -1) {
					put7SEG(0x0F, 0xFF);
					return;
				} else if (status == 0) {
					xil_printf(
							"\r\nInvalid input for Y. Please enter a valid number:\r\n");
				} else if (status == 1) {
					y = parsed_value;
					xil_printf("\r\nPress a button for ADD / SUB\r\n");
					xil_printf("Press ENTER to choose new numbers\r\n");
					state = WAIT_OPERATION;
				}
			} else if (state == WAIT_OPERATION) {
				if (c == '\r' || c == '\n') {
					put7SEG(0x0F, 0xFF);
					return;
				}
			}
		}
		/* button handling only after both numbers exist */
		if (state == WAIT_OPERATION) {
			btn_value = ReadButtons();

			if (btn_value & 0x1) {
				result = x + y;
				xil_printf("X + Y = ");
				UartSendFloat3(result);
				xil_printf("\r\n");
				xil_printf("Press a button for ADD / SUB\r\n");
				xil_printf("Press ENTER to choose new numbers\r\n");

				usleep(200000);
			} else if (btn_value & 0x2) {
				result = x - y;
				xil_printf("X - Y = ");
				UartSendFloat3(result);
				xil_printf("\r\n");
				xil_printf("Press a button for ADD / SUB\r\n");
				xil_printf("Press ENTER to choose new numbers\r\n");

				usleep(200000);
			} else if (btn_value & 0x4) {
				xil_printf(
						"This option is not available in the current state\r\n");
				usleep(200000);
			} else if (btn_value & 0x8) {
				xil_printf(
						"This option is not available in the current state\r\n");
				usleep(200000);

			}
		}
	}
}


/*
 * Advanced Calculator mode.
 *
 * Active mode:
 * SW15 = 0, SW0 = 1
 *
 * The user enters two floating-point operands through UART.
 * The push buttons are then used to select:
 * - ADD
 * - SUB
 * - MUL
 * - DIV
 *
 * Division by zero is detected and reported to the terminal.
 * The 7-Segment display blinks the word "ADVN" while the mode is active.
 */
void advancedCalc(void) {
	u32 sw_value;
	u32 sw_simple;
	u32 sw_advanced;
	u32 btn_value;
	u32 counter;
	u8 onoff;

	float x, y, result;
	float parsed_value;
	int input_idx;
	int status;
	char c;
	char input_buf[16];

	CalcState state;
	state = GET_X;

	xil_printf("Advanced Calculator (Add/Sub/Mul/Div)\r\n");

	counter = 0;
	onoff = 1;
	x = 0;
	y = 0;
	result = 0;
	parsed_value = 0;
	input_idx = 0;

	xil_printf("Please enter first operand X:\r\n");
	xil_printf("Press ENTER to start over\r\n");

	while (1) {

		/* stay if in Advanced mode */

		ReadSwMode(&sw_value, &sw_simple, &sw_advanced);


		if (!((sw_simple == 0) && (sw_advanced == 1))) {
			put7SEG(0x0F, 0xFF);
			return;
		}

		/* blink ADVN f=1 Hz  */
		counter++;
		if (counter >= 125) {
			onoff = !onoff;
			counter = 0;
		}

		if (onoff == 1) {
			Write7SEG("ADVN");
		} else {
			put7SEG(0x0F, 0xFF);
			usleep(8000);
		}

		/* non-blocking UART input */
		if (UartTryGetChar(&c)) {
			if (state == GET_X) {
				status = ProcessInputChar(c, input_buf, &input_idx,
						&parsed_value);

				if (status == -1) {
					put7SEG(0x0F, 0xFF);
					return;
				} else if (status == 0) {
					xil_printf(
							"\r\nInvalid input for X. Please enter a valid number:\r\n");
				} else if (status == 1) {
					x = parsed_value;
					xil_printf("\r\nPlease enter second operand Y:\r\n");
					xil_printf(
							"Press ENTER on empty line to choose new numbers\r\n");
					state = GET_Y;
				}
			} else if (state == GET_Y) {
				status = ProcessInputChar(c, input_buf, &input_idx,
						&parsed_value);

				if (status == -1) {
					put7SEG(0x0F, 0xFF);
					return;
				} else if (status == 0) {
					xil_printf(
							"\r\nInvalid input for Y. Please enter a valid number:\r\n");
				} else if (status == 1) {
					y = parsed_value;
					xil_printf(
							"\r\nPress a button for ADD / SUB / MUL / DIV\r\n");
					xil_printf("Press ENTER to choose new numbers\r\n");
					state = WAIT_OPERATION;
				}
			} else if (state == WAIT_OPERATION) {
				if (c == '\r' || c == '\n') {
					put7SEG(0x0F, 0xFF);
					return;
				}
			}
		}
		/* button handling only after both numbers exist */
		if (state == WAIT_OPERATION) {
			btn_value = ReadButtons();

			if (btn_value & 0x1) {
				result = x + y;
				xil_printf("X + Y = ");
				UartSendFloat3(result);
				xil_printf("\r\n");
				xil_printf("Press a button for ADD / SUB / MUL / DIV\r\n");
				xil_printf("Press ENTER to choose new numbers\r\n");

				usleep(200000);
			} else if (btn_value & 0x2) {
				result = x - y;
				xil_printf("X - Y = ");
				UartSendFloat3(result);
				xil_printf("\r\n");
				xil_printf("Press a button for ADD / SUB / MUL / DIV\r\n");
				xil_printf("Press ENTER to choose new numbers\r\n");

				usleep(200000);
			} else if (btn_value & 0x4) {
				result = x * y;
				xil_printf("X * Y = ");
				UartSendFloat3(result);
				xil_printf("\r\n");
				xil_printf("Press a button for ADD / SUB / MUL / DIV\r\n");
				xil_printf("Press ENTER to choose new numbers\r\n");

				usleep(200000);
			} else if (btn_value & 0x8) {
				if (y == 0) {
					xil_printf("Error: division by zero\r\n");
				} else {
					result = x / y;
					xil_printf("X / Y = ");
					UartSendFloat3(result);
					xil_printf("\r\n");
				}

				xil_printf("Press a button for ADD / SUB / MUL / DIV\r\n");
				xil_printf("Press ENTER to choose new numbers\r\n");
				usleep(200000);
			}
		}
	}
}




/*
 * Main program loop.
 *
 * The program continuously checks SW15 and SW0 and enters the selected mode.
 *
 * Each mode contains its own internal loop and returns to main only when:
 * - the user changes the mode switches
 * - or the user exits the calculator by pressing ENTER on an empty line

 */
int main(void) {
	u32 sw_value;
	u32 sw_simple;
	u32 sw_advanced;
	u32 SideLeds;

	if (Initialize() != XST_SUCCESS) {
		return -1;
	}

	xil_printf("\r\n--- MicroBlaze Calculator System started ---\r\n");

	while (1) {

		ReadSwMode(&sw_value, &sw_simple, &sw_advanced);



		if ((sw_simple == 0) && (sw_advanced == 0)) {

			xil_printf("\r\n");
			xil_printf(
					"Please Choose a mode and set the two switches [SW15][SW0]:\r\n");
			xil_printf("(1) Simple Calculator (Add/Sub): [1][0]\r\n");
			xil_printf("(2) Advanced Calculator (Add/Sub/Mul/Div): [0][1]\r\n");

			LedPatt();
		} else if ((sw_simple == 0) && (sw_advanced == 1)) {

			advancedCalc();

		}

		else if ((sw_simple == 1) && (sw_advanced == 0)) {

			simpleCalc();

		}

		else if ((sw_simple == 1) && (sw_advanced == 1)) {
			xil_printf("To start, please place the switches in: 00\r\n");
			while (1) {

				ReadSwMode(&sw_value, &sw_simple, &sw_advanced);

				if (!((sw_simple == 1) && (sw_advanced == 1))) {
					WriteLeds(0x0);
					break;
				}
				SideLeds = 0x8001;
				WriteLeds(SideLeds);
				usleep(1000000);

				ReadSwMode(&sw_value, &sw_simple, &sw_advanced);

				if (!((sw_simple == 1) && (sw_advanced == 1))) {
					WriteLeds(0x0);
					break;
				}
				SideLeds = 0x0;
				WriteLeds(SideLeds);
				usleep(1000000);

			}
		}
		ClearScreen();

	}

	return 0;
}

