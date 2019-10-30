module janela
	( input [9:0] r, c
	, output mask
	, output rt, gt, bt
	);
	assign mask = (r < 255 && c < 511);
	assign rt = c < 255;
	assign gt = r < 127;
	assign bt = (c >= 255 && r >= 127) || (rt && gt);
endmodule

module conc
	( input [9:0] r, c
	, output [14:0] conc_s
	);
	assign conc_s = {r[6:0], c[7:0]};
endmodule
