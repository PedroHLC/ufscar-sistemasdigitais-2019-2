module erosion
	( input [8:0] mask
	, output q
	);
	
	assign q = (mask == 9'b111111111);
endmodule

module dilatation
	( input [8:0] mask
	, output q
	);
	
	assign q = (mask > 0);
endmodule

module img_cache
	( input reset, clock, trigger
	, input mask_feed
	, input we, write_in
	, output reg out
	, output reg [8:0] mask
	);
	
	localparam
		IMG_WIDTH=256,
		IMG_HEIGHT=128,
		IMG_PIXELS=(IMG_WIDTH*IMG_HEIGHT);
	
	reg [0:(IMG_PIXELS-1)] cache;
	
	always @(posedge clock)
		begin
			mask <=
				{ mask_feed, cache[1:2]
				, cache[IMG_WIDTH:(IMG_WIDTH+2)]
				, cache[(IMG_WIDTH*2):(IMG_WIDTH*2+2)]
				};
			out <= cache[0];
		end
	
	always @(negedge clock)
		if(trigger)
			cache <= { cache[1:(IMG_PIXELS-1)], (reset ? 1'b0 : (we & trigger ? write_in : cache[0])) };
	
endmodule

module img_proc
	( input clock
	, input trigger
	, input [2:0] op
	, input income
	, output c1, e1, d1, f2, f3, f4, b1
	);
	
	localparam
		S_RESET=3'b000,
		S_W_LINE0=3'b001,
		S_W_LINE1=3'b010,
		S_W_LINE2=3'b011,
		S_W_LINE3=3'b100,
		S_W_LINE4=3'b101,
		S_READ=3'b110,
		S_READ2=3'b111;
	
	wire e0, d0, b0, reset;
	wire [8:0] mask, mask_clean, mask_dilatation, mask_filter_b, mask_filter_c;
	// LIMPA
	img_cache cache0(reset, clock, trigger, income, (op == S_W_LINE0), income, c1, mask_clean);
	// ERODI
	img_cache cache1(reset, clock, trigger, income, (op == S_W_LINE1), e0, e1, 0);
	// FILTRO
	img_cache cache2(reset, clock, trigger, c1, (op == S_W_LINE1), d0, d1, mask_dilatation);
	img_cache cache3(reset, clock, trigger, d1, (op == S_W_LINE2), e0, f2, mask_filter_b);
	img_cache cache4(reset, clock, trigger, f2, (op == S_W_LINE3), e0, f3, mask_filter_c);
	img_cache cache5(reset, clock, trigger, f3, (op == S_W_LINE4), d0, f4, 0);
	// BORDAS
	img_cache cache6(reset, clock, trigger, income, (op == S_W_LINE2), b0, b1, 0);
	// INVERTE (Pura diversao)
	//img_cache cache7(reset, clock, trigger, income, (op == S_W_LINE1), ~c1, i1, 0);
	
	assign reset = (op == S_RESET);
	
	assign mask =
		( op[1] ?
			( op[0] ? mask_dilatation
			: mask_clean )
		: ( op[0] ? mask_filter_c
		  : mask_filter_b )
		);
	
	assign b0 = (e1 ^ d1);
	
	erosion erosion0 (mask, e0);
	dilatation dilatation0 (mask, d0);
endmodule
