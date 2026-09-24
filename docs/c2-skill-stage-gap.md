# C2 技能舞台缺口表 — 哪些能力世界根本沒有提供舞台

> 這是**診斷**，不是待辦清單，也不是授權。它只回答一件事：以**現在世界裡真的存在的
> 事實**為限，每個技能有沒有可以站的地方。沒有的就寫沒有，不補、不猜、不為了讓表格
> 看起來平衡而發明。
>
> 產生自 `tools/c2_build_comparison.gd` 的舞台統計 + 逐一核對 encounter context 與
> 世界資料結構。2026-09-21。

## 世界目前真的有的事實

掛載點只能長在這些東西上。清單本身就是缺口表的上限：

| 來源 | 實際欄位 |
| --- | --- |
| Encounter context（唯一在遭遇當下可讀的） | WRECK：`fresh_wreck{day,type}`（帳本裡真的失事的商隊）／ROCKSLIDE：**無**／ROADBLOCK：`min_security`／DEHYDRATED_TRAVELLER：`from_name`（真的缺水的聚落）／REFUGEE_COLUMN：`headcount`、`origin_name`、`destination_name`（`world.refugees` 裡真的存在的隊伍） |
| Settlement | 庫存、產出、消耗、人口、水／食物壓力與曝露、`cumulative_deaths`、`security`、`maintenance_scrap`、`maintenance_fuel`、四項 `base_price_*`、`target_*`、`last_need_outcomes` |
| Caravan | 路線、貨物、`is_destroyed` |
| Refugee party | 起訖、`headcount`、剩餘天數 |
| Player | 背包五種資源、瓶蓋、容量、水／食物壓力與曝露、capability profile |
| Ledger | 既成事件（含 `TRANSIT_PREDATION`、`CARAVAN_DESTROYED`） |

**世界沒有的**：任何物品實體（裝備、武器、工具）、任何 actor 的敵意／情緒／關係狀態、
傷勢／疾病／可治療狀態、電力或電子設施、派系、聲望、對話對象的身世。

## 缺口表

| Skill | 現在有沒有自然舞台 | 最自然的掛載點 | 掛載狀態 | 前提／禁止事項 |
| --- | --- | --- | --- | --- |
| SURVIVAL | **已有**（用 2 次） | 路線、地形、脫水 | — | — |
| BARTER | **已有**（用 2 次） | 過路費、與難民交換 | — | 另有一個**現成但沒接上的舞台**：城鎮市集已經實作，`base_price_*` 是真的欄位，但交易目前完全不看 BARTER |
| SCAVENGING | **已有**（用 1 次） | 殘骸、廢墟 | — | — |
| MECHANICS | **已有**（用 1 次） | 車輛、機械 | — | 另有未接的真實欄位：聚落的 `maintenance_scrap` / `maintenance_fuel`（屬 C6 Job 的範圍，不是 C2） |
| STEALTH | **已有**（用 1 次） | 繞過、隱蔽通行 | — | — |
| **SPEECH** | **可能現在就有** | ROADBLOCK：說服收費的人讓你過 | **Can mount now**（唯一一個） | 見下節。可用的事實只有 `min_security`；不得發明對方的身世、派系、家庭或秘密 |
| FIREARMS | 暫時沒有 | 等真正的 firearm item／armed actor 成為世界事實 | **Needs new world fact**（C5 Equipment） | 關卡的人身上**沒有任何武器資料**，只有散文寫「沒有拔槍」。`FIREARMS 2` 是懂槍，不是有槍 |
| MELEE | 很弱 | 等 physical confrontation / combat authority | **Needs new subsystem** | 世界裡沒有任何 actor 帶敵意狀態。不要硬塞 |
| ELECTRONICS | 暫時沒有 | 等真的有 terminal／電子控制／供電設施 | **Needs new world fact** | 世界資料裡**沒有任何欄位把「電子」和「機械」分開**；`maintenance_*` 不足以區分。發明一個終端機就是發明世界 |
| MEDICINE | 沒有 | 等 injury / disease / treatable condition authority | **Needs new subsystem** | 這正是 `REVIVE → HYDRATE` 改名的原因 |

## SPEECH：唯一一個現在就能掛的，以及它的邊界

SPEECH 之所以不同於 FIREARMS / MEDICINE，是因為它**不需要新的 subsystem**，只需要一個
可交涉的對象——而 ROADBLOCK 已經斷言了這個對象的存在：`PAY` 這個選項真的把瓶蓋交給
某些人，也就是說「有人在那裡，而且要東西」是遭遇本身已經成立的事實，不是新發明的。

**可以現在掛（零新事實）**

```
ROADBLOCK
[跟他們談談]  ← SPEECH
→ 不付瓶蓋、不耗時間通過
```

它與既有選項的關係是乾淨的：`PAY` 付錢、`HAGGLE`（BARTER）殺價、`SLIP_PAST`（潛行）
用時間換、`DETOUR` 繞路、SPEECH 則是**完全不付**。四種資源軸各佔一條，不重疊。

**不可以拿來當理由的東西**

- 對方有家人、有秘密、屬於某個派系、有名字——世界資料裡沒有，寫下去就是發明。
- 唯一能用來上色的事實是 `min_security`（這一帶有沒有人管事），遭遇散文已經在用它。

**REFUGEE_COLUMN 是次佳，但有一個岔路**

難民隊的對象是**真的**——`world.refugees` 裡的隊伍，有真實的人數與真實的起訖聚落。
但 SPEECH 在那裡最自然的效果是「問出前方／來處的狀況」，而那是**資訊**：起點聚落真實
的缺水與治安狀態，目前對玩家是不公開的（遠端聚落只投影最小資料，S7 Information Fog
還沒做）。

```
非資訊型效果（例如說動他們少要一點）  → 與 BARTER 重疊，價值低
資訊型效果（問出來處真正的狀況）      → Needs new authority（S7 玩家知識邊界）
```

**DEHYDRATED_TRAVELLER 不行**：他幾乎沒有反應，沒有可交涉的對象。要讓他能說話，得先
有「他清醒了」這個狀態——那是 MEDICINE 的 subsystem 問題，不是 SPEECH 的。

## 這張表怎麼用

1. **守衛單薄不是數值問題**。守衛的三項是 FIREARMS 2 / MELEE 1 / SURVIVAL 1，其中
   兩項落在「沒有舞台」欄。要修它，要嘛等 C5 給 FIREARMS 真正的物品，要嘛承認目前的
   encounter library 偏食 SURVIVAL / BARTER。
2. **不要為了讓表好看而填**。FIREARMS / MELEE / MEDICINE / ELECTRONICS 四項現在都只能
   靠發明世界事實才填得起來，那會把 C2 變成「看到弱就補 mechanic」。
3. **BARTER 在市集的缺口是免費的機會**：市集是既有系統，價格是既有欄位，不需要任何新
   世界事實——但那是交易系統的改動，不是 C2 的遭遇改動，需要獨立授權。
4. 每次新增 encounter 之後重跑 `tools/c2_build_comparison.gd`，可以直接看出哪個 build
   長期被餓死、哪個技能永遠沒有舞台、哪個 build 吃掉所有解法。
