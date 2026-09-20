# Game Pillars (核心設計支柱)

`afterdust-rpg` 的本質是**「具有湧現性質的廢土世界模擬 RPG」**，而非單向敘事的線性冒險遊戲。所有機制與實作必須嚴格遵守以下 6 大設計支柱：

---

### Pillar 1: 世界不等待玩家 (The World Ticks Without You)
* 遊戲中時間持續以離散的時間單位（Tick / 日）推進。
* NPC、聚落、商隊、派系皆由世界引擎自治驅動，各自消耗、生產、移動並計算利益。
* 玩家即使站在原地掛網 30 天，商隊依然會遭劫、物價依然會波動、邊境依然會失守。世界不是為玩家搭建的待機佈景。

---

### Pillar 2: 任務不是獨立副本 (Quests Are Emergent States)
傳統 RPG 的任務是預寫好的獨立事件：
$$\text{接取任務} \longrightarrow \text{傳送去副本打怪} \longrightarrow \text{交任務取得 100 元}$$

Afterdust 的任務是**世界狀態失衡產生的直接需求**：
$$\text{水荒} \longrightarrow \text{水價暴漲} \longrightarrow \text{商隊中斷} \longrightarrow \text{聚落發布高額收購委託} \longrightarrow \text{玩家介入運水} \longrightarrow \text{當地庫存增加、水價回跌}$$
如果玩家不解任務，只要有其他商隊抵達或黑市介入，該委託就會自然因「需求已滿足」而失效。

---

### Pillar 3: 玩家不是欽定的救世主 (The Player Is Just An Agent)
* 玩家在世界中的角色是自治行為者（Agent）之一，可以是商人、拾荒者、傭兵、掠奪者，或是冷眼旁觀的流浪漢。
* 系統不提供救世主特權光環。玩家所受到的物理、經濟與傷害規則，與世界中的 NPC 商隊和掠奪者相同。

---

### Pillar 4: 世界狀態高於預寫劇情 (World State > Pre-scripted Narrative)
遊戲體驗的核心循環源自因果鏈的湧現：

```text
       World State (聚落庫存、治安、商隊位置)
            ↓
          Event (商隊受襲、資源耗盡)
            ↓
      Observation (目擊者、情報擴散)
            ↓
       Rumor / Quest (酒館傳言、市場價格信號)
            ↓
     Player Decision (護航、搶劫、倒賣、漠視)
            ↓
       Consequences (供需改變、派系關係重塑)
            ↓
     New World State (下一個因果起點)
```

---

### Pillar 5: 真相與認知是分離的 (Truth vs. Observation / Fog of Information)
* **客觀真相 (Objective Truth)** 唯一存在於模擬引擎內部（例如：「Day 12，商隊 C1 在舊公路被黑犬幫搶毀」）。
* **觀測與情報 (Observation & Rumors)** 是局域且具備延遲的：
  * 灰谷只知道「商隊遲到了三天，水庫見底」。
  * 新希望只知道「發出的水車失去聯繫」。
  * 酒館裡流傳的是「東邊公路有土匪活動」。
* 玩家與各聚落永遠處於不完全情報之中，情報本身也是一種可交易、可造假、可被阻斷的世界資源。

---

### Pillar 6: 死亡不是遊戲結束 (Death Is Not Game Over)
* 角色死亡是世界歷史的一部分。
* 玩家角色死亡後，世界依然運轉；繼承者或新角色將直接面對前人行動遺留下來的殘破世界。
