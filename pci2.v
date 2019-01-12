module device(input [3:0]n,input force_req, input[31:0] AddressToContact,input[3:0] control,input[3:0]byte_en,output reg req,
					  input gnt,inout[31:0] address,input clk,inout[3:0] BeC,inout frame,inout devsel,inout irdy,inout trdy);
		reg [31:0]mem[0:9]; 		  
		reg device_add = 1;
		
		reg [31:0] msg=32'hAAAA_AAAA;
		
		reg[31:0] out_add;
		reg out_devsel,out_frame;
		reg[3:0] out_BeC;
		reg out_irdy,out_trdy;
		reg add_mode = 0,devsel_mode = 0 ,BeC_mode = 0 ,irdy_mode = 0,trdy_mode = 0,frame_mode= 0;
		assign address = add_mode ? out_add:32'bzzzz_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz;
		assign devsel = devsel_mode? out_devsel:1'bz;
		assign BeC = BeC_mode ? out_BeC:4'bzzzz;
		assign irdy = irdy_mode? out_irdy:1'bz;
		assign trdy = trdy_mode? out_trdy:1'bz;
		assign frame = frame_mode? out_frame :1'bz;
		//initial begin $readmemh("memory.txt",mem); end
		//send the req signal when force_req is 1 at negedge of the clk
		
		
		reg [5:0] state=1;
		
		integer i;
		always @(posedge clk)
		begin
			case(state)
				1:begin
					i <=0;
					if(gnt)state <= 2;
					else if(address==device_add && BeC==1)state<=10;
					else if(address==device_add && BeC==2)state<=11;
					else if(!gnt && address!=device_add)state <= 1;
				end
				2:begin
					if(gnt && control==1)state<=3;
					else if(gnt && control==2)state <= 4;
					else if(!gnt)state <= 1;
				end
				3:begin
					if(gnt)state<=5;
					if(!gnt)state<=1;
				end
				
				4:begin
					if(i==(n))state<=16;
					else if(gnt && (!irdy && !trdy))begin i <= i + 1; state <= 4; end
					else if(gnt && (irdy || trdy))state<=4;
					
				end
				
				5:begin
					if(gnt)state<=7;
					if(!gnt)state <= 1;
				end
				
				7:begin
					if(gnt && (irdy ||trdy))state<=7;
					if(gnt && (!irdy && !trdy))begin i <= i + 1;state <= 7; end
					if(i == (n)) state <= 8;
					
				end
				
				8:begin
					if(frame)state <= 9;
				end
				
				9:begin
					state<=1;
				end
				
				10:begin
					if(!frame)state<=12;
				end
				
				11:begin
					if(!irdy && !frame)state<=14;
				end
				
				12:begin
					if(irdy || trdy)state<=12;
					if(!irdy && !trdy)begin state<=12; i <= i + 1; end
					if(frame || i==(n))state <= 13;
					
				end
				
				13:begin
					state <= 1;
				end
				
				14:begin
					if(irdy || trdy)state<=14;
					if(!irdy && !trdy)begin state<=14; i <= i + 1; end
					if(frame || i==(n))state <= 15;
				end
				
				15:begin
					state <= 1;
				end
				16:begin
					if(frame)state <= 17;
				end
				17:begin
					state <= 1;
				end
			endcase
		end
		
		
		always @(negedge clk)
		begin
			if(force_req)begin req <= 1; end
			case(state)
				1:begin
					add_mode <= 0; devsel_mode <=0; BeC_mode <=0; irdy_mode <=0; trdy_mode <= 0; frame_mode <= 0;
				end
				2:begin
					add_mode <= 1;out_add <= AddressToContact; BeC_mode <= 1; out_BeC <= control; frame_mode <= 1; out_frame <= 0;
					irdy_mode<=1; trdy_mode <= 0; devsel_mode <= 0;
				end
				3:begin
					BeC_mode <= 1; out_BeC <= byte_en; add_mode <= 0; out_irdy <= 0;
				end
				4:begin
					out_BeC <= byte_en; add_mode <= 1;  out_add <= msg; out_irdy <= 0;
				end
				5:begin
					out_BeC <= byte_en;
				end
				7:begin
					mem[i] <= address;
				end
				8:begin
					out_frame <= 1;
				end
				
				9:begin
					out_irdy <= 1; out_BeC <= 0; req <= 0;
				end
				10:begin
					irdy_mode <= 0; trdy_mode <= 1; devsel_mode <= 1; BeC_mode <= 0; add_mode <= 1; out_devsel <= 0; out_trdy <= 0;
				end
				11:begin
					irdy_mode <= 0; trdy_mode <= 1; devsel_mode <= 1; BeC_mode <= 0; add_mode <= 0;
				end
				12:begin
					out_devsel <= 0; out_trdy <= 0; out_add <= msg; devsel_mode<=1; trdy_mode <= 1;
				end
				13:begin
					out_trdy <= 1; out_devsel<=1; out_add<= 0;
				end
				14:begin
					out_devsel <= 0; out_trdy<= 0; 
					if(BeC[0])mem[i][7:0]<=address[7:0];
					if(BeC[1])mem[i][15:8]<=address[15:8];
					if(BeC[2])mem[i][23:16]<=address[23:16];
					if(BeC[3])mem[i][31:24]<=address[31:24];
				end
				15:begin
					out_trdy <= 1; out_devsel<=1; out_add<= 0;
				end
				16:begin
					out_frame <= 1;
				end
				17:begin
					out_BeC<=0; out_add<=0; out_irdy <= 0; req <=0;
				end
			endcase
		end
		

endmodule
	
