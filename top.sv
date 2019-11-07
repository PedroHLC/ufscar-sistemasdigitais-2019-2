module top
	( input CLOCK_50
	, input [9:7] SW
	, output [9:0] LEDR
	, output [7:0] VGA_R, VGA_G, VGA_B
	, output VGA_HS, VGA_VS
	, output VGA_CLK, VGA_BLANK_N, VGA_SYNC_N
	);
	
	// Define botoes
	wire [3:0] proc_what;
	wire reset, just_borders;
	state s0 (clock, SW[9:7], proc_what, just_borders, reset);
	
	// Todos os cabos que vamos precisar
	wire video_on, mem_clock, pixel_clock;
	wire [9:0] pixel_row, pixel_column;
	wire [14:0] conc_s;
	wire mask, mem_q, activate;
	wire vga_sr, vga_sg, vga_sb;
	wire red_time, green_time, blue_time;
	wire sq_right, sq_bottom;
	
	// Alguns multiplexadores
	assign activate = video_on & mask & (reset ? mem_q : out_q);
	assign mem_clock = video_on & pixel_clock & mask;
	
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
	assign VGA_R = (vga_sr ? 255 : 0);
	assign VGA_G = (vga_sg ? 255 : 0);
	assign VGA_B = (vga_sb ? 255 : 0);
	
	// Nossos componentes
	janela j0 (pixel_row, pixel_column, mask, red_time, green_time,
		blue_time, sq_right, sq_bottom);
	conc c0 (pixel_row, pixel_column, conc_s);
	
	// Tratamento morfologico
	wire p0_q, p1_q, p2_q, p3_q, out_q;
	img_proc p0 (reset, mem_clock, proc_what[3], conc_s, mem_q, p0_q);
	img_proc p1 (reset, mem_clock, proc_what[2], conc_s, p0_q, p1_q);
	img_proc p2 (reset, mem_clock, proc_what[1], conc_s, p1_q, p2_q);
	img_proc p3 (reset, mem_clock, proc_what[0], conc_s, p2_q, p3_q);
	assign out_q = (just_borders? (p0_q ^ p1_q) :
			(sq_right && sq_bottom? p3_q :
				(sq_bottom ? p2_q : (sq_right ? p1_q : p0_q))
		));
	assign LEDR = {proc_what[3], proc_what[2], proc_what[1], proc_what[0],
		just_borders, 4'b0, reset};
	
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
		) m0
		( .address_a(conc_s)
		, .clock0(mem_clock)
		, .q_a(mem_q)
		);
	
endmodule

module state
	( input clock
	, input [2:0] sw
	, output reg [3:0] procs
	, output reg just_borders
	, output reg reset
	);
	
	always @(sw)
		case(sw)
			3'b000: begin // IMAGEM ORIGINAL = RESET
					reset <= 1;
					procs <= 4'b0000;
					just_borders <= 0;
				end
			3'b001: begin // SO EROSAO
					reset <= 0;
					procs <= 4'b0000;
					just_borders <= 0;
				end
			3'b010: begin // SO DILATACAO
					reset <= 0;
					procs <= 4'b1111;
					just_borders <= 0;
				end
			3'b011: begin // FILTRO
					reset <= 0;
					procs <= 4'b1001;
					just_borders <= 0;
				end
			default: begin // BORDAS
					reset <= 0;
					procs <= 4'b0101;
					just_borders <= 1;
				end
		endcase
endmodule
