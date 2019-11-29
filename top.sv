module top
	( input CLOCK_50
	, input [9:0] SW
	, output [9:0] LEDR
	, output [7:0] VGA_R, VGA_G, VGA_B
	, output VGA_HS, VGA_VS
	, output VGA_CLK, VGA_BLANK_N, VGA_SYNC_N
	);
	
	// Todos os cabos que vamos precisar
	wire video_on, mem_clock, pixel_clock;
	wire [9:0] pixel_row, pixel_column;
	wire [14:0] conc_s;
	wire mask, mem_q, activate;
	wire vga_sr, vga_sg, vga_sb;
	wire red_time, green_time, blue_time, video_time;
	wire [2:0] which_pic;
	
	// Alguns multiplexadores
	assign video_time = video_on & mask;
	assign activate = video_time & out_q;
	assign mem_clock = video_time & pixel_clock;
	
	// Estados
	wire [3:0] current_op;
	wire reset, next_state, keep_coming;
	assign reset = SW[9];
	assign keep_coming = SW[0];
	state state0 (reset, keep_coming, pixel_clock, next_state, current_op);
	
	// Controladora VGA
	VGA_SYNC v0
		( .clock_50MHz(CLOCK_50)
		, .red(activate & red_time)
		, .green(activate & green_time)
		, .blue(activate & blue_time)
		, .red_out(vga_sr), .green_out(vga_sg), .blue_out(vga_sb)
		, .horiz_sync_out(VGA_HS), .vert_sync_out(VGA_VS)
		, .video_on(video_on), .pixel_clock(pixel_clock)
		, .pixel_row(pixel_row), .pixel_column(pixel_column)
		);
	assign VGA_CLK = pixel_clock;
	assign VGA_BLANK_N = 1;
	assign VGA_SYNC_N = 0;
	assign VGA_R = (vga_sr ? 8'hFF : 8'b0);
	assign VGA_G = (vga_sg ? 8'hFF : 8'b0);
	assign VGA_B = (vga_sb ? 8'hFF : 8'b0);
	
	// Nossos componentes
	janela janela0 (pixel_row, pixel_column, mask, red_time, green_time,
		blue_time, which_pic, next_state);
	conc conc0 (pixel_row, pixel_column, conc_s);
	
	// Tratamento morfologico
	wire out_q, c1, e1, d1, f2, f3, f4, b1, i1;
	img_proc proc0 (pixel_clock, video_time, current_op, mem_q,
		c1, e1, d1, f2, f3, f4, b1, i1);
	assign LEDR = {reset, 5'b0, current_op[3:0]};
	
	// Qual imagem mostrar?
	always @(*)
		if(reset)
			out_q = mem_q;
		else case(which_pic)
			3'b000: out_q = c1;
			3'b001: out_q = d1;
			3'b010: out_q = e1;
			3'b011: out_q = f4;
			3'b100: out_q = b1;
			3'b101: out_q = i1;
			default: out_q = 1'b0;
		endcase
	
	// Memoria com a Imagem Original
	altsyncram
		#( .width_a(1)
		, .widthad_a(15)
		, .widthad_byteena_a(1)
		, .numwords_a(32768)
		, .init_file("final.mif")
		, .operation_mode("ROM")
		, .outdata_aclr_a("NONE")
		, .outdata_reg_a("CLOCK0")
		) mem0
		( .address_a(conc_s)
		, .clock0(mem_clock)
		, .q_a(mem_q)
		);
	
endmodule

module state
	( input reset
	, input keep_coming
	, input clock
	, input next_state
	, output reg [3:0] state
	);
	
	always @(posedge clock, posedge reset)
		if(reset)
			state <= 3'b0;
		else if(next_state)
			if(state < 3'b101)
				state <= state + 3'b1;
			else if (keep_coming)
				state <= 3'b001;
endmodule
