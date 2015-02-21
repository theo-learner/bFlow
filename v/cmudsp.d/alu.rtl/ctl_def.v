/*	File:	ctl_def.v	  					*/

/*	Description:	This file includes all the text macro definitions used in the	 	*/
/*					control of alu data path.												*/


/*==============================================================================*/

/* XDB, YDB out select lines */
`define out_xy0 2'b00
`define out_xy1 2'b01
`define out_ab0 2'b10
`define out_ab1 2'b11

/* x0, y0, x1, y1 in select lines */
`define xy_x 2'b00
`define xy_y 2'b01
`define xy_a 2'b10
`define xy_b 2'b11

/* xy0, xy1 select lines */
`define xyout_x0 2'b00
`define xyout_x1 2'b01
`define xyout_y0 2'b10
`define xyout_y1 2'b11

`define m_x0 3'b000
`define m_y0 3'b001
`define m_y1 3'b010
`define m_x1 3'b011
`define m_p  3'b100		/* power of 2 */
`define m_1  3'b101		/* one: flow through */ 
`define m_0  3'b110		/* zero: don't use mult */ 

`define a_a  4'b0001    
`define a_b  4'b0010 
`define a_x  4'b0011 
`define a_x0 4'b0100 
`define a_x1 4'b0101 
`define a_y  4'b0110  
`define a_y0 4'b0111  
`define a_y1 4'b1000 
`define a_m  4'b1001	/* mult output */
`define a_la 4'b1010 	/* logic unit, A */
`define a_lb 4'b1011 	/* logic unit, B */
`define a_0  4'b0000 	/* zero: flow through, don't use */

`define l_a  3'b001    
`define l_b  3'b010 
`define l_x0 3'b100 
`define l_x1 3'b101 
`define l_y0 3'b110  
`define l_y1 3'b111 
`define l_0  3'b000 	/* zero: don't use */

