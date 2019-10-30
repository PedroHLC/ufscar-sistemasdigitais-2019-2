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

module img_proc
	( input reset, clock
	, input which
	, input income
	, output reg outcome
	);
	localparam BUF_MAX=514;
	
	reg [0:BUF_MAX] buffer;
	wire [8:0] mask;
	assign mask = { income, buffer[1], buffer[2]
		, buffer[256], buffer[257], buffer[258]
		, buffer[512], buffer[513], buffer[514] };
	wire e0, d0;
	
	erosion (mask, e0);
	dilatation (mask, d0);
	
	always @(posedge reset, posedge clock)
		if(reset)
			buffer <= 0;
		else
			begin
				buffer <= buffer >> 1;
				buffer[0] <= income;
				outcome <= (which? d0 : e0);
			end
endmodule
