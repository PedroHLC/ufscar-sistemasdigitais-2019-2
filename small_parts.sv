module janela
	( input [9:0] r, c
	, output mask
	, output rt, gt, bt
	, output right, bottom
	);
	assign mask = (r <= 255 && c <= 511);
	assign right = c > 255;
	assign bottom = r > 127;
	assign rt = (~right && ~bottom) || (right && bottom);
	assign gt = bottom;
	assign bt = right;
endmodule

module conc
	( input [9:0] r, c
	, output [14:0] conc_s
	);
	assign conc_s = {r[6:0], c[7:0]};
endmodule
