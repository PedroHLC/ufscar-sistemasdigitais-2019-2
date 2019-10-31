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
	, input [14:0] out_addr
	, input income
	, output reg outcome
	);
	localparam BUF_MAX=514;
	
	reg [14:0] addr;
	reg [0:BUF_MAX] buffer;
	wire [8:0] mask;
	assign mask = { income, buffer[1], buffer[2]
		, buffer[256], buffer[257], buffer[258]
		, buffer[512], buffer[513], buffer[514] };
	wire e0, d0;
	
	reg cache [0:32767];
	
	erosion (mask, e0);
	dilatation (mask, d0);
	
	always @(posedge reset, posedge clock)
		if(reset)
			begin
				buffer <= 0;
				addr <= 0;
			end
		else
			begin
				addr <= out_addr;
				outcome <= cache[addr+2];
				buffer <= buffer >> 1;
				buffer[0] <= income;
				cache[addr] <= (which? d0 : e0);
			end
endmodule
