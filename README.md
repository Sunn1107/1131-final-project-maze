# 1131-final-ptoject-maze
Authors: 112321064 112321070
## 迷宮探索：絕地大冒險
### Input/Output unit:
* 8x8 LED 矩陣 :  
> 透過 RGB 三色顯示不同內容：  
玩家位置顯示紅色。  
牆壁顯示藍色。  
出口顯示綠色。  
通路不發光。  
遊戲結束時，所有LED8x8 矩陣顯示器閃爍。
 <img src="https://github.com/user-attachments/assets/d857a40b-a5cf-4a62-88ef-61e7637ee530" style="width:30%;" />
 
* 七段顯示器 :  
> 用於顯示當前關卡數字（1、2、3...）。在遊戲結束時，七段顯示器保留最後的關卡數字。
<img src="https://github.com/user-attachments/assets/476cf724-fefa-481e-b96f-210097b02d77" style="width:30%;" />
<img src="https://github.com/user-attachments/assets/a9ced6d3-414a-467b-a8a8-ed60f35facc4" style="width:30%;" />
<img src="https://github.com/user-attachments/assets/a99807ed-0fd0-40d8-826c-05b8f803e5d3" style="width:30%;" />

* LED 陣列 :  
> 8 顆 LED，正常遊戲時為全關閉狀態。遊戲結束時，所有 LED 全亮。
  

* 蜂鳴器 (BUZZER)：  
> 當玩家完成所有關卡時觸發蜂鳴器發聲，提示遊戲結束。
<img src="https://github.com/user-attachments/assets/e5b740bb-38a9-4152-a0f1-666b8a40c760" style="width:30%;" />

### 功能說明
* 玩家控制：  
>透過 UP, DOWN, LEFT, RIGHT 四個輸入按鍵，控制玩家在迷宮中的移動。   
移動時檢查是否撞牆，若無阻礙則更新玩家位置。  

* 遊戲地圖：
>提供三個迷宮地圖，使用 8x8 的二進制陣列定義：  
1 代表牆壁，玩家無法通過。  
0 代表通路，玩家可以行走。  
每個地圖的左下角為出口。  

* 過關邏輯：  
>當玩家到達出口後，自動切換到下一個迷宮地圖。  
若完成最後一個地圖，遊戲結束並觸發以下效果：  
所有 LED 全亮。  

* 蜂鳴器 (BUZZER) 發聲。  
>顯示器進入閃爍模式。  

### 程式模組說明:
* DATA_R, DATA_G, DATA_B :   
>接到 8x8 RGB 矩陣 LED 的紅、綠、藍顏色控制腳。  
控制每個點的 RGB 顏色顯示（紅色=玩家，藍色=牆壁，綠色=出口）。  

* COMM :   
>接到 RGB 矩陣 LED 的掃描行控制腳。  
控制當前被掃描的行，逐行刷新顯示器。  

* SEG : 接到 7 段顯示器（Seven-Segment Display）。  
>顯示當前關卡數字（1, 2, 3）。  

* LED : 接到 8 顆 LED 指示燈。  
>遊戲結束時，所有 LED 全亮；遊戲進行中，LED 全關閉。  

* BUZZER : 接到蜂鳴器。  
>遊戲結束時，蜂鳴器響起提示玩家。  

#### 程式邏輯
1. 初始化階段 (Initial Block)
>程式在開始時會進行初始化，設置遊戲的基本參數：
player_x 和 player_y 設定玩家在地圖上的起始位置（左下角）。  
MAZE_1 代表第一張地圖，程式載入這張地圖作為初始狀態。  
顯示器、LED 和蜂鳴器都會初始化為關閉狀態。  
  
2. 時鐘分頻器 (Clock Dividers)
> 程式使用兩個分頻器來生成不同頻率的時鐘信號：  
10kHz 時鐘：用於刷新顯示矩陣。  
1Hz 時鐘：用於遊戲結束後的閃爍效果。  

3. 按鍵輸入檢測 (Button Input Logic)
> 程式檢查方向鍵 (UP, DOWN, LEFT, RIGHT) 的狀態來決定玩家的移動。  
移動的條件：玩家不會移動到牆壁（MAZE[player_y][player_x] == 0），並且不會超出邊界。  

4. 出口檢測和關卡更新
> 當玩家到達出口（右上角 (7, 0)）時，程式會檢查並更新關卡，並根據進度顯示關卡號。  
當玩家到達出口時：  
第一關完成，載入第二張地圖並顯示關卡 2。  
第二關完成，載入第三張地圖並顯示關卡 3。   
如果所有關卡完成，啟動蜂鳴器並使 LED 閃爍。  

5. 顯示邏輯
> 每 10kHz 時鐘週期，程式會更新 RGB 顯示器的顏色。  
玩家位置顯示為紅色 (DATA_R = 0, DATA_G = 1, DATA_B = 1)。  
牆壁顯示為藍色 (DATA_R = 1, DATA_G = 1, DATA_B = 0)。  
出口顯示為綠色 (DATA_R = 1, DATA_G = 0, DATA_B = 1)。  

### 影片
https://drive.google.com/drive/folders/1-tzRw5pFJM_YKahRFnB8r6rL0asePRd3?usp=sharing
