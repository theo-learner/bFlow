/*	File:	control_p.v	  						*/

/*	module name: control_p						*/

/*	Description: 		 						*/

/*		control logic for parallel move				*/

/*		all signals latched			*/


/*==============================================================================*/


/********************************************************************************/
/*																				*/
/*	module:																		*/
/*																				*/
/********************************************************************************/

module control_p (
	Clk, reset,
	pdb,
	immediate,
	x0_in_ctl,
	x1_in_ctl,
	y0_in_ctl,
	y1_in_ctl,
	x0_write,
	x1_write,
	y0_write,
	y1_write,
	limit0_lsb,
	limit1_lsb,
	xy0_ctl,
	xy1_ctl,
	xdb_out_ctl,
	ydb_out_ctl,
	XDB_write,
	YDB_write,
	move_from_ab
	);

	
/*========================= I/O direction ============================*/

input	Clk, reset;
input [`databus]	pdb;	/* instruction word */
input	immediate;		/* flag for immediate data on pdb */			
output [1:0] xdb_out_ctl,ydb_out_ctl;
output XDB_write, YDB_write;
output	x0_write, x1_write, y0_write, y1_write;
output [1:0] x0_in_ctl, x1_in_ctl, y0_in_ctl, y1_in_ctl;
output [1:0] xy0_ctl, xy1_ctl;
output	limit0_lsb, limit1_lsb;	/* limiter used for lsb in long move */
output move_from_ab;			/* A, B accumulator source of data move */

/*========================= I/O type ============================*/

reg [1:0] xdb_out_ctl,ydb_out_ctl;
reg x1_write, x0_write;	/* write enable signal for x registers */
reg y1_write, y0_write;	/* write enable signal for y registers */
reg XDB_write, YDB_write;	/* output enable signal for y registers */
reg [1:0] x0_in_ctl, x1_in_ctl, y0_in_ctl, y1_in_ctl;
reg [1:0] xy0_ctl, xy1_ctl;
reg	limit0_lsb, limit1_lsb;
reg move_from_ab;			/* A, B source of data move */

/*========================= Internal Nets ============================*/

/* register inputs for control signals that get latched */
reg [1:0] x0_in_ctl_d, x1_in_ctl_d, y0_in_ctl_d, y1_in_ctl_d;
reg [1:0] xysource_ctl;	/* temporary register for _in_ctl_d */
reg x1_write_d, x0_write_d;	/* write enable signal for x registers */
reg y1_write_d, y0_write_d;	/* write enable signal for y registers */
reg [1:0] xdb_out_ctl_d, ydb_out_ctl_d;
reg XDB_write_d, YDB_write_d;
reg [1:0] xy0_ctl_d, xy1_ctl_d;
reg	limit0_lsb_d, limit1_lsb_d;
reg [1:0] dbsource_ctl;
reg move_from_ab_d;		/* A, B source of data move */

	
/*==============================================================================*/
/*	processes																	*/
/*==============================================================================*/


always @(pdb or immediate)
begin
	/* set defaults */
	/* signals that effect stage 3 and are latched */
	xysource_ctl = `xy_x;
	x0_in_ctl_d = `xy_x;
	x1_in_ctl_d = `xy_x;
	y0_in_ctl_d = `xy_y;
	y1_in_ctl_d = `xy_y;
	x0_write_d = 0;
	x1_write_d = 0;
	y0_write_d = 0;
	y1_write_d = 0;
	/* signals that effect stage 2 and are not latched */
	limit0_lsb_d = 0;
	limit1_lsb_d = 0;
	xy0_ctl_d = `xyout_x0;
	xy1_ctl_d = `xyout_y0;
	dbsource_ctl = `out_ab0;
	xdb_out_ctl_d = `out_ab0;
	ydb_out_ctl_d = `out_ab1;
	XDB_write_d = 0;
	YDB_write_d = 0;
	move_from_ab_d = 0;			/* A, B source of data move */
	
	if (!immediate) begin		/* make sure pdb is not immediate data */
	casex (pdb[23:8])	
	/*--------------------------------------*/
	/*			MOVE X: Y:					*/
	/*										*/
	/*--------------------------------------*/
	16'b1xxxxxxxxxxxxxxx : begin
		$display($time, " MOVE X: Y: activated.  PDB = %h", pdb);		
		/* X: portion */
		if (!pdb[15])		/* read from registers (15 or 22 ?) */
		begin
			XDB_write_d = 1;
			case (pdb[19:18])	/* source */
				2'b00: begin
					xy0_ctl_d = `xyout_x0;
					xdb_out_ctl_d = `out_xy0;
				end
				2'b01: begin
					xy0_ctl_d = `xyout_x1;
					xdb_out_ctl_d = `out_xy0;
				end
				2'b10: begin
					/* limit0 tied to A */
					xdb_out_ctl_d = `out_ab0;
					move_from_ab_d = 1'b1;
				end
				2'b11: begin
					/* limit1 tied to B */
					xdb_out_ctl_d = `out_ab1;
					move_from_ab_d = 1'b1;
				end
			endcase
		end
		else begin		/* write to registers  */
			case (pdb[19:18])	/* destination */
				2'b00: begin
					x0_write_d = 1;
					x0_in_ctl_d = `xy_x;
				end
				2'b01: begin
					x1_write_d = 1;
					x1_in_ctl_d = `xy_x;
				end
				2'b10: ; /* A not implemented */
				2'b11: ; /* B not implemented */
			endcase
		end
		/* Y: portion */
		if (!pdb[22])		/* write to Y memory (15 or 22?) */
		begin
			YDB_write_d = 1;
			case (pdb[17:16])	/* source */
				2'b00: begin
					xy1_ctl_d = `xyout_y0;
					ydb_out_ctl_d = `out_xy1;
				end
				2'b01: begin
					xy1_ctl_d = `xyout_y1;
					ydb_out_ctl_d = `out_xy1;
				end
				2'b10: begin
					/* limit0 tied to A */
					ydb_out_ctl_d = `out_ab0;
					move_from_ab_d = 1'b1;
				end
				2'b11: begin
					/* limit1 tied to B */
					ydb_out_ctl_d = `out_ab1;
					move_from_ab_d = 1'b1;
				end
			endcase
		end
		else begin		/* read from Y memory */
			case (pdb[17:16])	/* destination */
				2'b00: begin
					y0_write_d = 1;
					y0_in_ctl_d = `xy_y;
				end
				2'b01: begin
					y1_write_d = 1;
					y1_in_ctl_d = `xy_y;
				end
				2'b10: ; /* A not implemented */
				2'b11: ; /* B not implemented */
			endcase
		end
	end /* MOVE X: Y: */
	/*--------------------------------------*/
	/*		MOVE X:, MOVE Y:				*/
	/*										*/
	/* can be aliased by MOVE L:			*/
	/*--------------------------------------*/
	16'b010xxxxxxxxxxxxx : begin	
		$display($time, " MOVE X:, MOVE Y: activated.  PDB = %h", pdb);		
		if (!pdb[15])		/* read from registers  */
		begin
			if (pdb[19])	/* which memory */
			begin
				YDB_write_d = 1;
				ydb_out_ctl_d = dbsource_ctl;
			end
			else begin
				XDB_write_d = 1;
				xdb_out_ctl_d = dbsource_ctl;
			end
			case (pdb[17:16])	/* source register */
				2'b00: begin
					xy1_ctl_d = `xyout_y0;
					dbsource_ctl = `out_xy1;
				end
				2'b01: begin
					xy1_ctl_d = `xyout_y1;
					dbsource_ctl = `out_xy1;
				end
				2'b10: begin
					/* limit0 tied to A */
					dbsource_ctl = `out_ab0;
					move_from_ab_d = 1'b1;
				end
				2'b11: begin
					/* limit1 tied to B */
					dbsource_ctl = `out_ab1;
					move_from_ab_d = 1'b1;
				end
			endcase
		end	/* if (!pdb[15]) */
		else begin		/* write to registers */
			/* source */
			if (pdb[19])
				xysource_ctl = `xy_y;
			else
				xysource_ctl = `xy_x;
			case ({pdb[20],pdb[18:16]})	/* destination */
				4'b0100: begin
					x0_write_d = 1;
					x0_in_ctl_d = xysource_ctl;
				end
				4'b0101: begin
					x1_write_d = 1;
					x1_in_ctl_d = xysource_ctl;
				end
				4'b0110: begin
					y0_write_d = 1;
					y0_in_ctl_d = xysource_ctl;
				end
				4'b0111: begin
					y1_write_d = 1;
					y1_in_ctl_d = xysource_ctl;
				end
				default:	; /* A, B not implemented */
			endcase
		end
	end /* MOVE X:, MOVE Y: */
	/* should MOVEP be with the parallel moves ? */
	/*--------------------------------------*/
	/*			MOVEP 						*/
	/*										*/
	/*--------------------------------------*/
	16'b0000100xx1xxxxxx : begin
		$display($time, " MOVEP activated.  PDB = %h", pdb);		
		case (pdb[7:6])
			2'b00: begin	/* Register Reference */
				if (pdb[15])		/* write to memory */
				begin
					if (pdb[16])		/* Y memory */
					begin
						YDB_write_d = 1;
						if (pdb[11])
						begin
							if (pdb[8])
							begin
								/* limit1 tied to B */
								ydb_out_ctl_d = `out_ab1;
								move_from_ab_d = 1'b1;
							end
							else begin
								/* limit0 tied to A */
								ydb_out_ctl_d = `out_ab0;
								move_from_ab_d = 1'b1;
							end
						end
						else
							ydb_out_ctl_d = `out_xy1;
					end /* if (pdb[16] */
					else begin			/* X memory */
						XDB_write_d = 1;
						if (pdb[11])
						begin
							if (pdb[8])
							begin
								/* limit1 tied to B */
								xdb_out_ctl_d = `out_ab1;
								move_from_ab_d = 1'b1;
							end
							else begin
								/* limit0 tied to A */
								xdb_out_ctl_d = `out_ab0;
								move_from_ab_d = 1'b1;
							end
						end
						else
							xdb_out_ctl_d = `out_xy1;
					end /* else (pdb[16] */
					case (pdb[11:8])	/* source */
						4'b0100: 
							xy1_ctl_d = `xyout_x0;
						4'b0101: 
							xy1_ctl_d = `xyout_x1;
						4'b0110: 
							xy1_ctl_d = `xyout_y0;
						4'b0111: 
							xy1_ctl_d = `xyout_y1;
						4'b1110: ;
							/* limit0 tied to A */
						4'b1111: ;
							/* limit1 tied to B */
						default: ;	/* NOT SUPPORTED */
					endcase
				end /* if (pdb[15] */
				else begin		/* read from memory */
					case ({pdb[11:8], pdb[16]})	/* destination, memory */
						/* from Y memory */
						5'b0100_1: begin
							x0_write_d = 1;
							x0_in_ctl_d = `xy_y;
						end
						5'b0101_1: begin
							x1_write_d = 1;
							x1_in_ctl_d = `xy_y;
						end
						5'b0110_1: begin
							y0_write_d = 1;
							y0_in_ctl_d = `xy_y;
						end
						5'b0111_1: begin
							y1_write_d = 1;
							y1_in_ctl_d = `xy_y;
						end
						/* from X memory */
						5'b0100_0: begin
							x0_write_d = 1;
							x0_in_ctl_d = `xy_x;
						end
						5'b0101_0: begin
							x1_write_d = 1;
							x1_in_ctl_d = `xy_x;
						end
						5'b0110_0: begin
							y0_write_d = 1;
							y0_in_ctl_d = `xy_x;
						end
						5'b0111_0: begin
							y1_write_d = 1;
							y1_in_ctl_d = `xy_x;
						end
						default: ;	/* NOT SUPPORTED */
					endcase
				end	/* else (pdb[15] */
			end
			default: ;	/* other movep NOT SUPPORTED */
		endcase
	end /* MOVEP */
	default: ;	/* other moves NOT SUPPORTED */
	endcase
	end /* if (!immediate) */
end /* always */
						
/*===========	Latch control signals		=================================*/
					
always @(posedge Clk)
	begin
		if (reset)
		begin
			x0_in_ctl  <= `xy_x;
			x1_in_ctl  <= `xy_x;
			y0_in_ctl  <= `xy_y;
			y1_in_ctl  <= `xy_y;
			x0_write  <= 0;
			x1_write  <= 0;
			y0_write  <= 0;
			y1_write  <= 0;
			limit0_lsb <= 0;
			limit1_lsb <= 0;
			xy0_ctl <= `xyout_x0;
			xy1_ctl <= `xyout_y0;
			xdb_out_ctl <= `out_ab0;
			ydb_out_ctl <= `out_ab1;
			XDB_write <= 0;
			YDB_write <= 0;
			move_from_ab <= 0;
		end
		else begin
			x0_in_ctl <= x0_in_ctl_d;
			x1_in_ctl <= x1_in_ctl_d;
			y0_in_ctl <= y0_in_ctl_d;
			y1_in_ctl <= y1_in_ctl_d;
			x0_write <= x0_write_d;
			x1_write <= x1_write_d;
			y0_write <= y0_write_d;
			y1_write <= y1_write_d;
			limit0_lsb <= limit0_lsb_d;
			limit1_lsb <= limit1_lsb_d;
			xy0_ctl <= xy0_ctl_d;
			xy1_ctl <= xy1_ctl_d;
			xdb_out_ctl <= xdb_out_ctl_d;
			ydb_out_ctl <= ydb_out_ctl_d;
			XDB_write <= XDB_write_d;
			YDB_write <= YDB_write_d;
			move_from_ab <= move_from_ab_d;
		end
	end
/* end always */


endmodule
