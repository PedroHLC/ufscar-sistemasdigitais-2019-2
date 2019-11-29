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
	wire red_trigger, green_trigger, blue_trigger, video_trigger;
	wire [1:0] which_pic;
	
	// Alguns multiplexadores
	assign video_trigger = video_on & mask;
	assign mem_clock = video_trigger & pixel_clock;
	assign activate = video_trigger & out_q;
	
	// Estados
	wire [2:0] current_op, barrier;
	wire reset, next_state, keep_coming;
	assign reset = SW[9];
	assign keep_coming = SW[0];
	assign barrier = SW[3:1];
	state state0 (reset, pixel_clock, keep_coming, barrier, next_state, current_op);
	
	// EasterEgg
	wire [9:0] fake_row, fake_column;
	dvdmov mov0 (reset, pixel_clock, SW[6], pixel_row, pixel_column, fake_row, fake_column);
	
	// Controladora VGA
	VGA_SYNC v0
		( .clock_50MHz(CLOCK_50)
		, .red(activate & red_trigger)
		, .green(activate & green_trigger)
		, .blue(activate & blue_trigger)
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
	janela janela0 (fake_row, fake_column, mask, red_trigger, green_trigger,
		blue_trigger, which_pic, next_state);
	conc conc0 (fake_row, fake_column, conc_s);
	
	// Tratamento morfologico
	wire out_q, c1, e1, d1, f2, f3, f4, b1;
	img_proc proc0 (pixel_clock, video_trigger, current_op, mem_q,
		c1, e1, d1, f2, f3, f4, b1);
	assign LEDR = {reset, 6'b0, current_op};
	
	// Qual imagem mostrar?
	always @(*)
		if(reset)
			out_q = mem_q;
		else case(which_pic)
			2'b00: out_q = c1;
			2'b01: out_q = f4;
			2'b10: out_q = b1;
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
	, input clock
	, input keep_coming
	, input [2:0] barrier
	, input next_state
	, output reg [2:0] state
	);
	
	always @(posedge clock, posedge reset)
		if(reset)
			state <= 3'b0;
		else if(next_state)
			if(state < (3'b101-barrier))
				state <= state + 3'b1;
			else if (keep_coming)
				state <= 3'b001;
endmodule

module dvdmov
	( input reset, clock, easteregg_trigger
	, input [9:0] pixel_row, pixel_column
	, output [9:0] fake_row, fake_column
	);
	localparam LIMIT_X=640-256-1, LIMIT_Y=460-(3*128)-1;
	reg [1:0] direction;
	reg [9:0] offset_x, offset_y;
	
	assign fake_row = pixel_row - offset_y;
	assign fake_column = pixel_column - offset_x;
	
	wire finished_frame;
	assign finished_frame =
		(pixel_row == 10'd460) & (pixel_column == 10'd620);
	
	always @(posedge clock)
		if(reset) begin
			offset_x <= 10'd191;
			offset_y <= 10'd47;
		end else if (easteregg_trigger & finished_frame) begin
			offset_x <= (direction[0] ? offset_x + 1'b1 : offset_x - 1'b1);
			offset_y <= (direction[1] ? offset_y + 1'b1 : offset_y - 1'b1);
		end
	
	always @(negedge clock)
		begin
			if (offset_y == 10'b0)
				direction[1] <= 1'b1;
			else if (offset_y >= LIMIT_Y)
				direction[1] <= 1'b0;
			else if (reset)
				direction[1] <= 1'b1;
			
			if (offset_x == 10'b0)
				direction[0] <= 1'b1;
			else if (offset_x >= LIMIT_X)
				direction[0] <= 1'b0;
			else if (reset)
				direction[0] <= 1'b1;
		end
endmodule
