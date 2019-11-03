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
	
	reg [0:BUF_MAX] buffer;
	wire [0:BUF_MAX] new_buffer;
	wire [8:0] mask;
	wire [14:0] off_addr;
	wire e0, d0;
	
	reg cache [0:32767];
	
	erosion (mask, e0);
	dilatation (mask, d0);
	
	assign off_addr = (out_addr+2) % ({15{1'b1}});
	assign new_buffer = {income, buffer[0:BUF_MAX-1]};
	assign mask = { income, buffer[1:2], buffer[256:258], buffer[512:514] };
	
	always @(posedge reset, posedge clock)
		if(reset)
			begin
				buffer <= 0;
			end
		else
			begin
				outcome <= cache[off_addr];
				buffer <= new_buffer;
				cache[out_addr] <= (which? d0 : e0);
			end
endmodule
