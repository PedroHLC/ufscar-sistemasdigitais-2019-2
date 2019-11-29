module janela
	( input [9:0] r, c
	, output mask
	, output rt, gt, bt
	, output [2:0] which_pic
	, output next_state
	);
	localparam HEIGHT=3*128;
	localparam WIDTH=2*256;
	
	assign mask = (r <= HEIGHT-1 & c <= WIDTH-1);
	assign which_pic[2:1] = (r / 10'd128);
	assign which_pic[0] = (c >= 10'd256);
	assign rt = 1'b1;
	assign gt = 1'b1;
	assign bt = 1'b1;
	assign next_state = (r <= HEIGHT-1) & (r % HEIGHT == 10'd127) & (c == WIDTH);
endmodule

module conc
	( input [9:0] r, c
	, output [14:0] conc_s
	);
	assign conc_s = {r[6:0], c[7:0]};
endmodule
