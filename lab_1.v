module lab_1(
    output reg [7:0] DATA_R, DATA_G, DATA_B, // RGB 輸出
    output reg [3:0] COMM,                   // 掃描行
    output reg [6:0] SEG,                    // Seven-segment display
    output reg [7:0] LED,                    // 控制 8 顆燈的開關
	 output reg BUZZER,
    input CLK,                               // 時鐘訊號
    input UP, DOWN, LEFT, RIGHT              // 玩家控制按鍵
);
    // 多張迷宮地圖定義
    parameter logic [7:0] MAZE_1 [7:0] = 
        '{8'b00000010, 
          8'b11101000,
          8'b10001111,
          8'b10111000,
          8'b10000000,
          8'b11110111,
          8'b00000100,
          8'b01111000};

    parameter logic [7:0] MAZE_2 [7:0] = 
        '{8'b10000010, 
          8'b11101110,
          8'b10001000,
          8'b10111011,
          8'b10000000,
          8'b00011110,
          8'b11000000,
          8'b00011110};
			 
		parameter logic [7:0] MAZE_3 [7:0] = 
			'{8'b01000010, 
          8'b01011110,
			8'b00010000,
			8'b11011011,
			8'b11001010,
			8'b00001000,
			8'b01101110,
			8'b01000000};

    logic [7:0] MAZE [7:0];

    reg [2:0] player_x = 0; // 玩家初始 X 座標 (左下角)
    reg [2:0] player_y = 7; // 玩家初始 Y 座標 (左下角)
    reg [2:0] scan_row = 0; // 當前掃描的行 (對應 COMM)
    wire CLK_10K;           // 顯示刷新頻率
    reg [3:0] col;          // 當前行的列掃描位

    reg [3:0] btn_last_state = 4'b0000; // 按鍵上一次狀態
    reg [1:0] current_map = 0; // 當前地圖索引

    wire CLK_1HZ;           // 用於閃爍的 1Hz 時鐘
    reg flash_flag = 0;     // 閃爍狀態標誌
	 //reg buzzed = 0;
    // 分頻器：產生顯示所需的 10KHz 時鐘
    divfreq F0(CLK, CLK_10K);
    // 分頻器：產生閃爍所需的 1Hz 時鐘
    divfreq_1hz F1(CLK, CLK_1HZ);

    // 初始化
    initial begin
        scan_row = 0;
        player_x = 0;
        player_y = 7;
        DATA_R = 8'b11111111;
        DATA_G = 8'b11111111;
        DATA_B = 8'b11111111;
        COMM = 4'b0000; // 預設不啟動
        current_map = 0;
        MAZE = MAZE_1; // 初始化地圖
        flash_flag = 0;
        SEG = 7'b1001111; // 預設顯示1
        LED = 8'b00000000; // 初始化 LED 為關閉
		  //buzzed = 0;
        BUZZER = 0;    // 風鳴器靜音
		  
    end

    // 玩家移動邏輯
    always @(posedge CLK) begin
        reg [3:0] btn_state;
        btn_state = {UP, DOWN, LEFT, RIGHT};

        if (btn_state != btn_last_state) begin // 检查按钮是否发生改变
            if (UP && !btn_last_state[3] && player_y > 0 && MAZE[player_y - 1][player_x] == 0)
                player_y <= player_y - 1;
            else if (DOWN && !btn_last_state[2] && player_y < 7 && MAZE[player_y + 1][player_x] == 0)
                player_y <= player_y + 1;
            else if (LEFT && !btn_last_state[1] && player_x > 0 && MAZE[player_y][player_x - 1] == 0)
                player_x <= player_x - 1;
            else if (RIGHT && !btn_last_state[0] && player_x < 7 && MAZE[player_y][player_x + 1] == 0)
                player_x <= player_x + 1;
        end

        btn_last_state <= btn_state; // 更新按鍵狀態

        // 若到達終點 (右上角)
        if (player_x == 7 && player_y == 0) begin
            if (current_map == 0) begin
                current_map <= 1;
                MAZE <= MAZE_2;
                player_x <= 0;
                player_y <= 7;
                SEG <= 7'b0100100; // 顯示 2
                // 這裡不立即亮燈，保持燈為關閉
                LED <= 8'b00000000; // 所有 LED 關閉
					end else if(current_map <= 1) begin
					current_map <= 2;
					MAZE <= MAZE_3;
					player_x <= 0;
               player_y <= 7;
					SEG <= 7'b0110000; // 顯示 3
					LED <= 8'b00000000; // 所有 LED 關閉
            end else begin
                // 到達最後，亮燈
                flash_flag <= 1;    // 開啟閃爍模式
					 //buzzed <= 1;
					 BUZZER <= 1;
      LED <= 8'b11111111; // 8 顆燈全亮
            end
        end else begin
            // 其他情況下 LED 維持關閉
            LED <= 8'b00000000; // 所有 LED 關閉
        end
    end

    // 顯示邏輯
    always @(posedge CLK_10K) begin
        if (!flash_flag) begin
            // 更新掃描行
            if (scan_row >= 7)
                scan_row <= 0;
            else
                scan_row <= scan_row + 1;

            COMM = {1'b1, scan_row};
            // 更新該行的列內容
            for (col = 0; col < 8; col = col + 1) begin
                if (player_x == col && player_y == scan_row) begin
                    // 玩家位置 (顯示紅色)
                    DATA_R[col] <= 1'b0;
                    DATA_G[col] <= 1'b1;
                    DATA_B[col] <= 1'b1;
                end else if (MAZE[scan_row][col] == 1) begin
                    // 牆壁 (顯示藍色)
                    DATA_R[col] <= 1'b1;
                    DATA_G[col] <= 1'b1;
                    DATA_B[col] <= 1'b0;
                end else if (scan_row == 0 && col == 7) begin
                    // 出口 (顯示綠色)
                    DATA_R[col] <= 1'b1;
                    DATA_G[col] <= 1'b0;
                    DATA_B[col] <= 1'b1;
                end else begin
					 // 通路 (不亮)
                    DATA_R[col] <= 1'b1;
                    DATA_G[col] <= 1'b1;
                    DATA_B[col] <= 1'b1;
                end
            end
        end else begin
            // 閃爍模式：切換 RGB 訊號
            if (CLK_1HZ) begin
                COMM <= COMM + 1'b1;
                DATA_R = 8'b01001001;  
                DATA_G = 8'b10010010;  
                DATA_B = 8'b11011011;  
            end
        end
    end
endmodule

// 分頻器模組：降低時鐘頻率至 10KHz
module divfreq(input CLK, output reg CLK_10K);
    reg [15:0] count;
    always @(posedge CLK) begin
        if (count >= 5000) begin
            count <= 0;
            CLK_10K <= ~CLK_10K;
        end else begin
            count <= count + 1;
        end
    end
endmodule

// 分頻器模組：降低時鐘頻率至 1Hz
module divfreq_1hz(input CLK, output reg CLK_1HZ);
    reg [24:0] count;
    always @(posedge CLK) begin
        if (count >= 25000000) begin
            count <= 0;
            CLK_1HZ <= ~CLK_1HZ;
        end else begin
            count <= count + 1;
        end
    end
endmodule







/*module lab_1(
    output reg [7:0] DATA_R, DATA_G, DATA_B, // RGB 輸出
    output reg [3:0] COMM,                   // 掃描行
    input CLK,                               // 時鐘訊號
    input UP, DOWN, LEFT, RIGHT              // 玩家控制按鍵
);
    // 多張迷宮地圖定義
 parameter logic [7:0] MAZE_1 [7:0] = 
        '{8'b00000010, 
          8'b11101000,
          8'b10001111,
          8'b10111000,
          8'b10000000,
          8'b11110111,
          8'b00000100,
          8'b01110000};

    parameter logic [7:0] MAZE_2 [7:0] = 
        '{8'b10000010, 
          8'b11101110,
          8'b10001000,
          8'b00111011,
          8'b00000000,
          8'b00011110,
          8'b11000000,
          8'b00011110};

    logic [7:0] MAZE [7:0];

    reg [2:0] player_x = 0; // 玩家初始 X 座標 (左下角)
    reg [2:0] player_y = 7; // 玩家初始 Y 座標 (左下角)
    reg [2:0] scan_row = 0; // 當前掃描的行 (對應 COMM)
    wire CLK_10K;           // 顯示刷新頻率
    reg [3:0] col;          // 當前行的列掃描位

    reg [3:0] btn_last_state = 4'b0000; // 按鍵上一次狀態
    reg [1:0] current_map = 0; // 當前地圖索引

    wire CLK_1HZ;           // 用於閃爍的 1Hz 時鐘
    reg flash_flag = 0;     // 閃爍狀態標誌
	 reg buzzed = 0; 

    // 分頻器：產生顯示所需的 10KHz 時鐘
    divfreq F0(CLK, CLK_10K);
    // 分頻器：產生閃爍所需的 1Hz 時鐘
    divfreq_1hz F1(CLK, CLK_1HZ);

    // 初始化
    initial begin
        scan_row = 0;
        player_x = 0;
        player_y = 7;
        DATA_R = 8'b11111111;
        DATA_G = 8'b11111111;
        DATA_B = 8'b11111111;
        COMM = 4'b0000; // 預設不啟動
        current_map = 0;
        MAZE = MAZE_1; // 初始化地圖
        flash_flag = 0;
    end

    // 玩家移動邏輯
    always @(posedge CLK) begin
        reg [3:0] btn_state;
        btn_state = {UP, DOWN, LEFT, RIGHT};

		  if (!buzzed) begin
            BUZZER <= 1;  // 啟動風鳴器
            buzzed <= 1;  // 清除响聲標誌
        end else begin
            BUZZER <= 0;  // 靜音
        end
		  
        if (btn_state != btn_last_state) begin // 检查按钮是否发生改变
            if (UP && !btn_last_state[3] && player_y > 0 && MAZE[player_y - 1][player_x] == 0)
                player_y <= player_y - 1;
            else if (DOWN && !btn_last_state[2] && player_y < 7 && MAZE[player_y + 1][player_x] == 0)
                player_y <= player_y + 1;
            else if (LEFT && !btn_last_state[1] && player_x > 0 && MAZE[player_y][player_x - 1] == 0)
                player_x <= player_x - 1;
            else if (RIGHT && !btn_last_state[0] && player_x < 7 && MAZE[player_y][player_x + 1] == 0)
                player_x <= player_x + 1;
        end

        btn_last_state <= btn_state; // 更新按鍵狀態

        // 若到達終點 (右上角)
        if (player_x == 7 && player_y == 0) begin
            if (current_map == 0) begin
                current_map <= 1;
                MAZE <= MAZE_2;
                player_x <= 0;
                player_y <= 7;
            end else begin
                flash_flag <= 1; // 開啟閃爍模式
            end
        end
    end

    // 顯示邏輯
    always @(posedge CLK_10K) begin
        if (!flash_flag) begin
            // 更新掃描行
            if (scan_row >= 7)
                scan_row <= 0;
            else
                scan_row <= scan_row + 1;

            COMM = {1'b1, scan_row};
            // 更新該行的列內容
            for (col = 0; col < 8; col = col + 1) begin
                if (player_x == col && player_y == scan_row) begin
                    // 玩家位置 (顯示紅色)
                    DATA_R[col] <= 1'b0;
                    DATA_G[col] <= 1'b1;
                    DATA_B[col] <= 1'b1;
                end else if (MAZE[scan_row][col] == 1) begin
                    // 牆壁 (顯示藍色)
                    DATA_R[col] <= 1'b1;
                    DATA_G[col] <= 1'b1;
                    DATA_B[col] <= 1'b0;
                end /*else if (MAZE[scan_row][col] == 4) begin
                    // 出口 (顯示綠色)
                    DATA_R[col] <= 1'b1;
                    DATA_G[col] <= 1'b0;
                    DATA_B[col] <= 1'b1;
                end else begin
                    // 通路 (顯示白色)
                    DATA_R[col] <= 1'b1;
                    DATA_G[col] <= 1'b1;
                    DATA_B[col] <= 1'b1;
                end
            end
        end else begin
            // 閃爍模式：切換 RGB 訊號
            if (CLK_1HZ) begin
				COMM <= COMM + 1'b1;
		  DATA_R = 8'b01101101;  
        DATA_G = 8'b10110110;  
        DATA_B = 8'b11011011;  
				
            end
        end
    end
endmodule

// 分頻器模組：降低時鐘頻率至 10KHz
module divfreq(input CLK, output reg CLK_10K);
    reg [15:0] count;
    always @(posedge CLK) begin
        if (count >= 5000) begin
            count <= 0;
            CLK_10K <= ~CLK_10K;
        end else begin
            count <= count + 1;
        end
    end
endmodule

// 分頻器模組：降低時鐘頻率至 1Hz
module divfreq_1hz(input CLK, output reg CLK_1HZ);
    reg [24:0] count;
    always @(posedge CLK) begin
        if (count >= 25000000) begin
            count <= 0;
            CLK_1HZ <= ~CLK_1HZ;
        end else begin
            count <= count + 1;
        end
    end
endmodule*/








/*module lab_1(
    output reg [7:0] DATA_R, DATA_G, DATA_B, // RGB 輸出
    output reg [3:0] COMM,                   // 掃描行
    input CLK,                               // 時鐘訊號
    input UP, DOWN, LEFT, RIGHT              // 玩家控制按鍵
);
    // 多張迷宮地圖定義
    parameter logic [7:0] MAZE_1 [7:0] = 
        '{8'b11111100, 
          8'b10000001,
          8'b10111001,
          8'b10100001,
          8'b10101111,
          8'b10000001,
          8'b10111001,
          8'b00111111};

    parameter logic [7:0] MAZE_2 [7:0] = 
        '{8'b11111100, 
          8'b10000001,
          8'b10111101,
          8'b10000101,
          8'b11110101,
          8'b10000101,
          8'b10111101,
          8'b00000001};

    logic [7:0] MAZE [7:0];

    reg [2:0] player_x = 0; // 玩家初始 X 座標 (左下角)
    reg [2:0] player_y = 7; // 玩家初始 Y 座標 (左下角)
    reg [2:0] scan_row = 0; // 當前掃描的行 (對應 COMM)
    wire CLK_10K;           // 顯示刷新頻率
    reg [3:0] col;          // 當前行的列掃描位

    reg [3:0] btn_last_state = 4'b0000; // 按鍵上一次狀態
    reg [1:0] current_map = 0; // 當前地圖索引

    // 分頻器：產生顯示所需的 10KHz 時鐘
    divfreq F0(CLK, CLK_10K);

    // 初始化
    initial begin
        scan_row = 0;
        player_x = 0;
        player_y = 7;
        DATA_R = 8'b11111111;
        DATA_G = 8'b11111111;
        DATA_B = 8'b11111111;
        COMM = 4'b1111; // 預設不啟動
        current_map = 0;
        MAZE = MAZE_1; // 初始化地圖
    end

    // 玩家移動邏輯
    always @(posedge CLK) begin
        reg [3:0] btn_state;
        btn_state = {UP, DOWN, LEFT, RIGHT};

        if (btn_state != btn_last_state) begin // 检查按钮是否发生改变
            if (UP && !btn_last_state[3] && player_y > 0 && MAZE[player_y - 1][player_x] == 0)
                player_y <= player_y - 1;
            else if (DOWN && !btn_last_state[2] && player_y < 7 && MAZE[player_y + 1][player_x] == 0)
                player_y <= player_y + 1;
            else if (LEFT && !btn_last_state[1] && player_x > 0 && MAZE[player_y][player_x - 1] == 0)
                player_x <= player_x - 1;
            else if (RIGHT && !btn_last_state[0] && player_x < 7 && MAZE[player_y][player_x + 1] == 0)
                player_x <= player_x + 1;
        end

        btn_last_state <= btn_state; // 更新按鍵狀態

        // 若到達終點 (右上角)，切換到下一張地圖
        if (player_x == 7 && player_y == 0) begin
            if (current_map == 0) begin
                current_map <= 1;
                MAZE <= MAZE_2;
            end else begin
                $display("Game Over: All maps completed!");
                $stop;
            end

            // 重置玩家位置
            player_x <= 0;
            player_y <= 7;
        end
    end

    // 顯示邏輯
    always @(posedge CLK_10K) begin
        // 更新掃描行
        if (scan_row >= 7)
            scan_row <= 0;
        else
            scan_row <= scan_row + 1;

        COMM = {1'b1, scan_row};
        // 更新該行的列內容
        for (col = 0; col < 8; col = col + 1) begin
            if (player_x == col && player_y == scan_row) begin
                // 玩家位置 (顯示紅色)
                DATA_R[col] <= 1'b0;
                DATA_G[col] <= 1'b1;
                DATA_B[col] <= 1'b1;
            end else if (MAZE[scan_row][col] == 1) begin
                // 牆壁 (顯示藍色)
                DATA_R[col] <= 1'b1;
                DATA_G[col] <= 1'b1;
                DATA_B[col] <= 1'b0;
            end else if (MAZE[scan_row][col] == 4) begin
                // 出口 (顯示綠色)
                DATA_R[col] <= 1'b1;
                DATA_G[col] <= 1'b0;
                DATA_B[col] <= 1'b1;
            end else begin
                // 通路 (顯示白色)
                DATA_R[col] <= 1'b1;
                DATA_G[col] <= 1'b1;
                DATA_B[col] <= 1'b1;
            end
        end
    end
endmodule

// 分頻器模組：降低時鐘頻率至 10KHz
module divfreq(input CLK, output reg CLK_10K);
    reg [15:0] count;
    always @(posedge CLK) begin
        if (count >= 5000) begin
            count <= 0;
            CLK_10K <= ~CLK_10K;
        end else begin
            count <= count + 1;
        end
    end
endmodule
*/




/*module lab_1(
    output reg [7:0] DATA_R, DATA_G, DATA_B, // RGB 輸出
    output reg [3:0] COMM,                   // 掃描行
    input CLK,                               // 時鐘訊號
    input UP, DOWN, LEFT, RIGHT              // 玩家控制按鍵
);
    // 迷宮地圖定義 (8x8)
    parameter logic [7:0] MAZE [7:0] = 
        '{8'b11111100, // 每位表示迷宮格子 (1=牆壁, 0=通路, 4=出口)
          8'b10000001,
          8'b10111001,
          8'b10100001,
          8'b10101111,
          8'b10000001,
          8'b10111001,
          8'b00111111};
    
    reg [2:0] player_x = 0; // 玩家初始 X 座標 (左下角)
    reg [2:0] player_y = 7; // 玩家初始 Y 座標 (左下角)
    reg [2:0] scan_row = 0; // 當前掃描的行 (對應 COMM)
    wire CLK_10K;           // 顯示刷新頻率
    reg [3:0] col;          // 當前行的列掃描位

    reg [3:0] btn_last_state = 4'b0000; // 按鍵上一次狀態

    // 分頻器：產生顯示所需的 10KHz 時鐘
    divfreq F0(CLK, CLK_10K);

    // 初始化
    initial begin
        scan_row = 0;
        player_x = 0;
        player_y = 7;
        DATA_R = 8'b11111111;
        DATA_G = 8'b11111111;
        DATA_B = 8'b11111111;
        COMM = 4'b1111; // 預設不啟動
    end

    // 玩家移動邏輯
    always @(posedge CLK) begin
        reg [3:0] btn_state;
        btn_state = {UP, DOWN, LEFT, RIGHT};

        if (btn_state != btn_last_state) begin // 检查按钮是否发生改变
            if (UP && !btn_last_state[3] && player_y > 0 && MAZE[player_y - 1][player_x] == 0)
                player_y <= player_y - 1;
            else if (DOWN && !btn_last_state[2] && player_y < 7 && MAZE[player_y + 1][player_x] == 0)
                player_y <= player_y + 1;
            else if (LEFT && !btn_last_state[1] && player_x > 0 && MAZE[player_y][player_x - 1] == 0)
                player_x <= player_x - 1;
            else if (RIGHT && !btn_last_state[0] && player_x < 7 && MAZE[player_y][player_x + 1] == 0)
                player_x <= player_x + 1;
        end

        btn_last_state <= btn_state; // 更新按鍵狀態

        // 若到達終點 (右上角)，停止
        if (player_x == 7 && player_y == 0) begin
            //$display("Game Over: Reached the goal!");
            $stop;
        end
    end

    // 顯示邏輯
    always @(posedge CLK_10K) begin
        // 更新掃描行
        if (scan_row >= 7)
            scan_row <= 0;
        else
            scan_row <= scan_row + 1;

        COMM = {1'b1, scan_row};
        // 更新該行的列內容
        for (col = 0; col < 8; col = col + 1) begin
            if (player_x == col && player_y == scan_row) begin
                // 玩家位置 (顯示紅色)
                DATA_R[col] <= 1'b0;
                DATA_G[col] <= 1'b1;
                DATA_B[col] <= 1'b1;
            end else if (MAZE[scan_row][col] == 1) begin
                // 牆壁 (顯示藍色)
                DATA_R[col] <= 1'b1;
                DATA_G[col] <= 1'b1;
                DATA_B[col] <= 1'b0;
            end else if (MAZE[scan_row][col] == 4) begin
                // 出口 (顯示綠色)
                DATA_R[col] <= 1'b1;
                DATA_G[col] <= 1'b0;
                DATA_B[col] <= 1'b1;
            end else begin
                // 通路 (顯示白色)
                DATA_R[col] <= 1'b1;
                DATA_G[col] <= 1'b1;
                DATA_B[col] <= 1'b1;
            end
        end
    end
endmodule

// 分頻器模組：降低時鐘頻率至 10KHz
module divfreq(input CLK, output reg CLK_10K);
    reg [15:0] count;
    always @(posedge CLK) begin
        if (count >= 5000) begin
            count <= 0;
            CLK_10K <= ~CLK_10K;
        end else begin
            count <= count + 1;
        end
    end
endmodule*/







/*module lab_1(
    output reg [7:0] DATA_R, DATA_G, DATA_B, // RGB 輸出
    output reg [3:0] COMM,                   // 掃描行
    input CLK,                               // 時鐘訊號
    input UP, DOWN, LEFT, RIGHT              // 玩家控制按鍵
);
    // 迷宮地圖定義 (8x8)
    parameter logic [7:0] MAZE [7:0] = 
        '{8'b11111100, // 每位表示迷宮格子 (1=牆壁, 0=通路, 4=出口)
          8'b10000001,
          8'b10111001,
          8'b10100001,
          8'b10101111,
          8'b10000001,
          8'b10111001,
          8'b00111111};
    
    reg [2:0] player_x = 1; // 玩家初始 X 座標 (左上角)
    reg [2:0] player_y = 1; // 玩家初始 Y 座標
    reg [2:0] scan_row = 0; // 當前掃描的行 (對應 COMM)
    wire CLK_10K;           // 顯示刷新頻率
    reg [3:0] col;          // 當前行的列掃描位

    reg [3:0] btn_last_state = 4'b0000; // 按鍵上一次狀態

    // 分頻器：產生顯示所需的 10KHz 時鐘
    divfreq F0(CLK, CLK_10K);

    // 初始化
    initial begin
        scan_row = 0;
        player_x = 1;
        player_y = 1;
        DATA_R = 8'b11111111;
        DATA_G = 8'b11111111;
        DATA_B = 8'b11111111;
        COMM = 4'b1111; // 預設不啟動
    end

    // 玩家移動邏輯
    always @(posedge CLK) begin
        reg [3:0] btn_state;
        btn_state = {UP, DOWN, LEFT, RIGHT};

        if (btn_state != btn_last_state) begin // 检查按钮是否发生改变
            if (UP && !btn_last_state[3] && player_y > 0 && MAZE[player_y - 1][player_x] == 0)
                player_y <= player_y - 1;
            else if (DOWN && !btn_last_state[2] && player_y < 7 && MAZE[player_y + 1][player_x] == 0)
                player_y <= player_y + 1;
            else if (LEFT && !btn_last_state[1] && player_x > 0 && MAZE[player_y][player_x - 1] == 0)
                player_x <= player_x - 1;
            else if (RIGHT && !btn_last_state[0] && player_x < 7 && MAZE[player_y][player_x + 1] == 0)
                player_x <= player_x + 1;
        end

        btn_last_state <= btn_state; // 更新按鍵狀態
    end

    // 顯示邏輯
    always @(posedge CLK_10K) begin
        // 更新掃描行
        if (scan_row >= 7)
            scan_row <= 0;
        else
            scan_row <= scan_row + 1;

        COMM = {1'b1, scan_row};
        // 更新該行的列內容
        for (col = 0; col < 8; col = col + 1) begin
            if (player_x == col && player_y == scan_row) begin
                // 玩家位置 (顯示紅色)
                DATA_R[col] <= 1'b0;
                DATA_G[col] <= 1'b1;
                DATA_B[col] <= 1'b1;
            end else if (MAZE[scan_row][col] == 1) begin
                // 牆壁 (顯示藍色)
                DATA_R[col] <= 1'b1;
                DATA_G[col] <= 1'b1;
                DATA_B[col] <= 1'b0;
            end else if (MAZE[scan_row][col] == 4) begin
                // 出口 (顯示綠色)
                DATA_R[col] <= 1'b1;
                DATA_G[col] <= 1'b0;
                DATA_B[col] <= 1'b1;
            end else begin
                // 通路 (顯示白色)
                DATA_R[col] <= 1'b1;
                DATA_G[col] <= 1'b1;
                DATA_B[col] <= 1'b1;
            end
        end
    end
endmodule

// 分頻器模組：降低時鐘頻率至 10KHz
module divfreq(input CLK, output reg CLK_10K);
    reg [15:0] count;
    always @(posedge CLK) begin
        if (count >= 5000) begin
            count <= 0;
            CLK_10K <= ~CLK_10K;
        end else begin
            count <= count + 1;
        end
    end
endmodule*/









/*module lab_1(
    output reg [7:0] DATA_R, DATA_G, DATA_B, // RGB 輸出
    output reg [3:0] COMM,                   // 掃描行
    input CLK,                               // 時鐘訊號
    input UP, DOWN, LEFT, RIGHT              // 玩家控制按鍵
);
    // 迷宮地圖定義 (8x8)
    parameter logic [7:0] MAZE [7:0] = 
        '{8'b11111100, // 每位表示迷宮格子 (1=牆壁, 0=通路, 4=出口)
          8'b10000001,
          8'b10111001,
          8'b10100001,
          8'b10101111,
          8'b10000001,
          8'b10111001,
          8'b00111111};
    
    reg [2:0] player_x = 1; // 玩家初始 X 座標 (左上角)
    reg [2:0] player_y = 1; // 玩家初始 Y 座標
    reg [2:0] scan_row = 0; // 當前掃描的行 (對應 COMM)
    wire CLK_10K;           // 顯示刷新頻率
    reg [3:0] col;          // 當前行的列掃描位
    
    // 分頻器：產生顯示所需的 10KHz 時鐘
    divfreq F0(CLK, CLK_10K);

    // 初始化
    initial begin
        scan_row = 0;
        player_x = 1;
        player_y = 1;
        DATA_R = 8'b11111111;
        DATA_G = 8'b11111111;
        DATA_B = 8'b11111111;
        COMM = 4'b1111; // 預設不啟動
    end

    // 玩家移動邏輯
    always @(posedge CLK) begin
        if (UP && player_y > 0 && MAZE[player_y - 1][player_x] == 0)
            player_y <= player_y - 1;
        else if (DOWN && player_y < 7 && MAZE[player_y + 1][player_x] == 0)
            player_y <= player_y + 1;
        else if (LEFT && player_x > 0 && MAZE[player_y][player_x - 1] == 0)
            player_x <= player_x - 1;
        else if (RIGHT && player_x < 7 && MAZE[player_y][player_x + 1] == 0)
            player_x <= player_x + 1;
    end

    // 顯示邏輯
    always @(posedge CLK_10K) begin
        // 更新掃描行
        if (scan_row >= 7)
            scan_row <= 0;
        else
            scan_row <= scan_row + 1;

        //COMM <= ~(4'b1000 >> scan_row); // 更新 COMM 對應行
			COMM = {1'b1, scan_row};
        // 更新該行的列內容
        for (col = 0; col < 8; col = col + 1) begin
            if (player_x == col && player_y == scan_row) begin
                // 玩家位置 (顯示紅色)
                DATA_R[col] <= 1'b0;
                DATA_G[col] <= 1'b1;
                DATA_B[col] <= 1'b1;
            end else if (MAZE[scan_row][col] == 1) begin
                // 牆壁 (顯示藍色)
                DATA_R[col] <= 1'b1;
                DATA_G[col] <= 1'b1;
                DATA_B[col] <= 1'b0;
            end else if (MAZE[scan_row][col] == 4) begin
                // 出口 (顯示綠色)
                DATA_R[col] <= 1'b1;
                DATA_G[col] <= 1'b0;
                DATA_B[col] <= 1'b1;
            end else begin
                // 通路 (顯示白色)
                DATA_R[col] <= 1'b1;
                DATA_G[col] <= 1'b1;
                DATA_B[col] <= 1'b1;
            end
        end
    end
endmodule

// 分頻器模組：降低時鐘頻率至 10KHz
module divfreq(input CLK, output reg CLK_10K);
    reg [15:0] count;
    always @(posedge CLK) begin
        if (count >= 5000) begin
            count <= 0;
            CLK_10K <= ~CLK_10K;
        end else begin
            count <= count + 1;
        end
    end
endmodule*/

/*module lab_1 (
    input CLK,             // 時鐘
    input KEY_UP,          // 上鍵
    input KEY_DOWN,        // 下鍵
    input KEY_LEFT,        // 左鍵
    input KEY_RIGHT,       // 右鍵
    output reg [7:0] DATA_R, DATA_G, DATA_B,  // 顯示顏色 (例如 LED 顯示)
    output reg [3:0] COMM                 // 顯示訊息
);
    // 迷宮地圖，0是空白，1是牆壁，2是出口，3是角色
    reg [2:0] maze[0:7][0:7];
    reg [2:0] player_x, player_y;  // 角色位置 (x, y)
    reg [3:0] prev_comm;  // 儲存前一個顯示訊息，以避免重複顯示

    initial begin
        // 初始化迷宮地圖
        // 0: 空白，1: 牆壁，2: 出口，3: 角色
        maze[0][0] = 3;    // 起點 (角色)
        maze[7][7] = 2;    // 出口
        maze[0][1] = 1;    // 墙壁
        maze[1][1] = 1;    // 墙壁
        maze[1][2] = 1;    // 墙壁
        // 可以繼續設置迷宮地圖
        
        // 初始化角色位置
        player_x = 0;
        player_y = 0;
        prev_comm = 4'b0000;  // 初始化為無訊息顯示
    end

    // 控制角色移動的邏輯
    always @(posedge CLK) begin
        if (KEY_UP && player_y > 0 && maze[player_y-1][player_x] != 1) begin
            player_y <= player_y - 1;  // 向上移動
        end
        else if (KEY_DOWN && player_y < 7 && maze[player_y+1][player_x] != 1) begin
            player_y <= player_y + 1;  // 向下移動
        end
        else if (KEY_LEFT && player_x > 0 && maze[player_y][player_x-1] != 1) begin
            player_x <= player_x - 1;  // 向左移動
        end
        else if (KEY_RIGHT && player_x < 7 && maze[player_y][player_x+1] != 1) begin
            player_x <= player_x + 1;  // 向右移動
        end
    end

    // 顯示角色和迷宮的更新
    always @(posedge CLK) begin
        // 如果角色到達出口，顯示全亮
        if (maze[player_y][player_x] == 2) begin
            COMM = 4'b1111;  // 顯示成功訊息或結束
            DATA_R = 8'b11111111;  // 全亮紅色
            DATA_G = 8'b11111111;  // 全亮綠色
            DATA_B = 8'b11111111;  // 全亮藍色
        end else begin
            // 更新顯示地圖
            COMM = 4'b0000;   // 顯示角色當前位置
            // 顯示角色位置
            DATA_R = (maze[player_y][player_x] == 3) ? 8'b11111111 : 8'b00000000;
            DATA_G = (maze[player_y][player_x] == 2) ? 8'b11111111 : 8'b00000000;
            DATA_B = (maze[player_y][player_x] == 1) ? 8'b11111111 : 8'b00000000;
        end
    end
endmodule*/