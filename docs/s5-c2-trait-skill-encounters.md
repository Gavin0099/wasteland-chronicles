# S5-C2 Trait & Skill Encounters — 實作紀錄（本機，未驗證）

> 狀態（Owner 把 closure 切成兩半）：
>
> ```
> C2-A Authority / Safety   → VERIFIED ✅（A1~A8 全綠，37 套測試 exit 0）
> C2-B Player Experience    → NOT VERIFIED 🟡（等四 Background + Trait A/B 手玩）
> S5-C2                     → 仍然 NOT CLOSED，兩半都過才算
> ```
>
> 這樣切的理由：測試全綠**不代表**角色差異好玩。C2-A 證明的是邊界安全，C2-B 才是
> 這一刀真正要驗的東西，而它只有人玩得出來。

## 這一刀要解決什麼

C0 讓玩家選出一個角色，C1 讓那個角色的能力可以被查詢、被持久化、被驗證，但
**那些能力在世界裡不做任何事**。走在路上的機械師和搜刮者面對同一台翻覆的貨車，
看到的是完全一樣的兩個按鈕。C2 的驗收問題只有一個：
**同一個遭遇，不同角色能不能用不同方式解決。**

本刀**不新增 encounter template**。世界上還是那五種路上事件（WRECK、ROCKSLIDE、
ROADBLOCK、DEHYDRATED_TRAVELLER、REFUGEE_COLUMN），改變的是站在它們前面的人。

## 九個做法

每個遭遇都保留原本誰都做得到的普通選項，沒有任何角色會面對一個他完全無法回答的路。

| 遭遇 | 選項 | 條件 | Gate | 代價 / 效果 |
| --- | --- | --- | --- | --- |
| WRECK | `STRIP_PARTS` 拆解引擎與傳動 | 機械 熟練(2) | capability | 1 天（水 −1、食物 −1）；`strip_parts_yield`，幾乎不會空手 |
| WRECK | `QUICK_PICK` 一眼挑出值得帶走的 | 搜刮 熟練(2) | knowledge | 不耗時間；`quick_pick_yield`，三成空手 |
| ROCKSLIDE | `SCOUT_PATH` 找一條小徑 | 荒野求生 熟練(2) | knowledge | 不耗廢料、不耗天 |
| ROCKSLIDE | `FORCE_THROUGH` 直接翻過去 | 魯莽（Trait） | knowledge | 不耗天、不耗廢料；**固定**弄丟 1 件物資（廢料→燃料→水） |
| ROADBLOCK | `HAGGLE` 把價錢談下來 | 交易 略懂(1) | capability | 瓶蓋 −4（原價 10），直接通過 |
| ROADBLOCK | `SLIP_PAST` 等天黑再摸過去 | 潛行 略懂(1) | capability | 1 天（水 −1、食物 −1），不付錢 |
| DEHYDRATED_TRAVELLER | `HYDRATE` 用正確的方式讓他補水 | 荒野求生 略懂(1) | capability | 水 −1、不耗天；`hydrate_yield`，不空手 |
| DEHYDRATED_TRAVELLER | `TAKE_PACK` 拿走他的背包 | 貪財（Trait） | knowledge | 無代價；`take_pack_yield` |
| REFUGEE_COLUMN | `TRADE_COLUMN` 跟他們換東西 | 交易 略懂(1) | capability | 瓶蓋 −5；`column_trade_yield` |

門檻只用**創角當下真的拿得到的等級**。四個 Background 給的是 2/1/1，所以條件只出現
在 rank 1 與 rank 2；MEDICINE 與 SPEECH 目前任何 Background 都是 0，因此本刀刻意
**沒有**掛任何 MEDICINE/SPEECH 條件——那會是寫出來卻沒有人能看見的死內容。它們是
C3 成長之後才會打開的新玩法。

實際分布（以能力評估器直接列舉，Trait 留空）：

```
CARAVAN_GUARD  unlocked: HYDRATE
               locked  : STRIP_PARTS, HAGGLE, SLIP_PAST, TRADE_COLUMN
MECHANIC       unlocked: STRIP_PARTS
               locked  : HAGGLE, SLIP_PAST, HYDRATE, TRADE_COLUMN
FARMER         unlocked: SCOUT_PATH, HAGGLE, HYDRATE, TRADE_COLUMN
               locked  : STRIP_PARTS, SLIP_PAST
SCAVENGER      unlocked: QUICK_PICK, SLIP_PAST, HYDRATE
               locked  : STRIP_PARTS, HAGGLE, TRADE_COLUMN
（hidden：QUICK_PICK / SCOUT_PATH 視角色而定，FORCE_THROUGH、TAKE_PACK 由 Trait 決定）
```

**已知的不平衡**：`CARAVAN_GUARD` 目前只解鎖 `HYDRATE`（而且農夫與搜刮者也有），
因為它的看家本領 FIREARMS 2 在本輪被拿掉了（見下）。實玩時守衛會是最單薄的一個 build，
這是已知的、有原因的缺口，不是漏做。

## 兩個 authority 修正（Owner 指出）

### 1. FIREARMS 2「按住槍不動」已移除

原本的 `STAND_FIRM` 偷偷假設了一件世界還沒有的事：**玩家身上有槍**。C2 只有 Skill
authority，Equipment 是 C5。`FIREARMS 2` 的意思是「懂槍」，不是「憑空擁有一把槍」，
而這正是我們刻意把 Skill 與 Equipment 分開的原因。

本輪的處理是**直接拿掉**，而不是改寫成「觀察對方武器」的知識型選項——因為
ROADBLOCK 的 encounter context 目前只有 `min_security`，裡面**沒有任何可被觀察的武器
事實**；要做成觀察型選項，得先把「對方持有什麼」變成真的世界事實，並且需要「觀察→
開出後續選項」的兩段式遭遇流程。兩件都超出本輪修正範圍。

乾淨的回歸點是：

```
C5：FIREARMS 2 + Equipped Firearm  →  [持槍施壓]
或  encounter 真的帶有武器事實後   →  FIREARMS 2 → [觀察他們的武器]
```

### 2. 救旅人的措辭不再冒充 Medicine / Injury authority

原本叫 `REVIVE`「照該有的方式把人救回來」，暗示了一套並不存在的傷勢→治療→康復世界
狀態。這個世界沒有 injury，沒有 treatment，旅人也不是 population 的成員，而是路邊的
道具。現在改為 `HYDRATE`「用正確的方式讓他補水」，結算文案是：

```
你讓他慢慢喝下水，確認他能自己站起來。
```

成立於既有的 encounter resolution 之內，沒有宣稱任何醫療系統存在。`revive_yield`
一併更名為 `hydrate_yield`，且函式上方寫明它**不是**醫療。

## UX 規則：hidden vs disabled

「做不到」有兩種，兩種不該長得一樣：

| 分類 | 意思 | 呈現 |
| --- | --- | --- |
| **Knowledge Gate** | 角色根本不知道有這個選項 | 完全隱藏 |
| **Capability Gate** | 角色知道可以這樣做，只是現在做不到 | 顯示，disabled，標出「需要：機械 熟練」 |

看不出土石坡上有小徑的人，不是「看得到一個鎖著的選項」，而是那條路對他不存在；
但**誰都看得見貨車裡有引擎**，只是拆不動——那個鎖著的按鈕，是玩家唯一會學到
「原來把機械練起來可以做這件事」的地方，也是幾小時後再遇到貨車時它亮起來的那一刻。

Trait 型做法歸類為 knowledge gate：不魯莽的人站在崩塌前，不會想到直接翻過去。

第三種情況與能力無關：瓶蓋不夠、廢料不夠，是暫時性的短缺，照舊顯示為 disabled 並附
上原因，行為與 S5-B4 相同。

實作：目錄的每個受限選項帶 `gate` 欄位；`PlayerUIProjection._project_encounter()`
只濾掉 knowledge gate，capability gate 以 `locked: true` 投影出去，由
`playable_shell` 顯示為「選項　—　需要：<條件>」。

## 可理解優先於不可預測

本版刻意把能力差異做成**看得懂、可預期**的：交易 1 讓過路費從 10 變 4；荒野求生 2
免費繞過崩塌；潛行 1 用一天換不付錢；魯莽不花資源但**固定**弄丟 1 件物資（而且事前
就寫在選項上）。玩家一眼就知道 build 為什麼有差。

原本 `STAND_FIRM` 的「六成對方退讓」已隨該選項移除；`FORCE_THROUGH` 原本 hash 決定
掉什麼，現在改成固定優先序。嚴格說那不是 runtime random 而是
hash-derived deterministic outcome，但從玩家角度仍然是不可預知的機率結果——這種東西
可以存在，只是現在不需要急著增加不透明度，等 encounter 系統成熟再加。

**保留**的不透明只有「收穫不明」：搜刮的產出本來就是 S5-B4 就決定的 doctrine（說明
代價、不說明報酬），不在本次收斂範圍。

## 權威與檢查點

- 需求條件只寫在 `simulation/travel_encounter.gd` 的選項表裡（`requires`），用的是 C1
  的 clause 語彙，由 `CapabilityProfile.meets_requirements()` 判定。目錄不自己實作
  資格判斷，引擎也不自己抄一份條件。
- `CapabilityProfile.meets_requirements()` 從「只有技能」擴充成「技能 + Core Trait」。
  `skill` clause 的形狀與語意完全不變；trait 是 `trait_present` / `trait_absent` 兩個
  **不同 kind**，所以既有呼叫端的行為不可能被意外改變。Trait 是是非題，不是等級。
- `SimulationEngine.authorize_encounter_option()` 在 commit 邊界**重新**檢查條件。UI
  的過濾只是投影；重播的 intent、舊存檔、或漂掉的 UI 都買不到角色沒有的做法。
- 失敗碼：`CAPABILITY_UNAVAILABLE`（沒有 capability profile）、
  `CAPABILITY_CHECK_FAILED`（條件本身無效）、`CAPABILITY_NOT_MET`（條件不符）。
- 沒有新的世界事實：所有結果只搬動既有資源（水／食物／廢料／燃料／瓶蓋）與既有天數。
  沒有戰鬥、傷勢、派系、聲望；`TAKE_PACK` 不會在人口帳上殺死任何人。
- 沒有 XP、Level、Perk、裝備。使用技能不會讓技能成長，那是 C3。

## C2-A Authority / Safety —— 已驗證

`tests/test_s5_c2_authorization.gd`，八個 gate 全綠。這一套刻意只鎖**不會因為手玩結論
而改變**的規則：不管之後 `HYDRATE` / `STRIP_PARTS` 要不要改、要不要加 Speech 選項、
哪些 hidden 要改成 disabled，下面這條都不動——

```
UI 顯示選項  ≠  玩家有權執行
```

| Gate | 鎖住什麼 |
| --- | --- |
| A1 | 沒解鎖的做法一律拒絕——**隱藏的和反白的走同一條拒絕路徑**，隱藏不是防護 |
| A2 | 投影之後才被換掉的 capability、被竄改的存檔、完全沒有 profile → 全部 fail closed；同時確認沒有 profile 時普通選項仍可用，不會把玩家鎖死在無法回答的路上 |
| A3 | 一次遭遇一次結算一張收據，收據只能被消費一次；重複 resolve、錯的收據索引、已消費的收據全部拒絕且不寫第二筆帳 |
| A4 | 不屬於這個遭遇的選項（含 C2 新選項與憑空捏造的 ID）以 `INVALID_OPTION` 拒絕，**在 capability 檢查之前** |
| A5 | 八個被條件擋下的做法 → 世界 SHA-256 逐字節不變 |
| A6 | 條件過了但資源不夠（瓶蓋 3 殺價、沒水補水）→ 以 `INSUFFICIENT_*` 拒絕，SHA-256 不變 |
| A7 | 4 Background × 5 遭遇 = 20 組存讀往返：hash 相同、投影的選項清單（含 locked 旗標）相同、**每個選項的授權判定字串也相同** |
| A8 | 同世界同遭遇不同 build → 合法選項集合不同、結算結果不同；同一個 build 跑兩次 → 世界完全相同（零 RNG）。replay SHA-256 `48efa70f…685d8d` |

**回歸**：`tests/*.gd` 共 37 套（既有 36 + 新的 C2-A）全部 exit 0，沒有 SCRIPT ERROR。
另外五個改動檔 `--check-only` 零錯誤。

## C2-B Player Experience —— 尚未驗證

**還沒有人實際進遊戲點過這些按鈕。** 客觀欄位已經用 `tools/c2_build_comparison.gd`
先填好（見下一節），但以下三題只有手玩能回答，在那之前 C2 不得標記為 CLOSED。

## 實玩前的客觀觀測（`tools/c2_build_comparison.gd`）

無法手玩時能先做完的，是這張表的**客觀欄位**：同一個世界、同一條路、同一天、同一個
遭遇，四個 Background 各自看到什麼、按下去實際發生什麼。工具讀的是目錄、投影與引擎
本身，不是另一套抄寫的規則；它**回答不了**第三欄（看到灰選項會不會想練），那是手感。

### 風險 1：FARMER 過度豐富 —— 成立，但真正的問題不是農夫

單一遭遇裡沒有人「什麼都有」：任何 build 在任何一個遭遇最多就是 3 個可選項。差異是
**攤在五個遭遇上**的——農夫在 5 個遭遇中有 4 個多出一條路，守衛只有 1 個，而且那一個
（`HYDRATE`）農夫與搜刮者也有。

也就是說：**守衛目前沒有任何一條別人沒有的路。**

原因量得出來，是內容缺口不是數值問題——十個技能裡有五個在世界上**沒有舞台**：

```
BARTER       使用 2 次        MEDICINE     — 沒有舞台
SURVIVAL     使用 2 次        SPEECH       — 沒有舞台
MECHANICS    使用 1 次        FIREARMS     — 沒有舞台
SCAVENGING   使用 1 次        MELEE        — 沒有舞台
STEALTH      使用 1 次        ELECTRONICS  — 沒有舞台
```

守衛的三項是 FIREARMS 2 / MELEE 1 / SURVIVAL 1，其中兩項落在「沒有舞台」那一欄。
這不該用硬塞守衛選項來補，而是 encounter library 目前偏食 SURVIVAL/BARTER 的診斷結果。

### 風險 2：灰按鈕會不會變成 UI 垃圾 —— 目前量到的上限是 2

```
單一遭遇內最多灰選項：2（ROADBLOCK，守衛與機械師）
五個遭遇合計：守衛 4、機械師 4、搜刮者 3、農夫 2
```

擔心的「一次出現 4～5 個灰按鈕」沒有發生。剩下的問題（是誘惑還是雜訊）只能靠玩。

### 風險 3：質變還是只剩效率差 —— 兩個做法確實只是效率差

實際跑過引擎的結果：

| 做法 | 對照 | 性質 |
| --- | --- | --- |
| `SLIP_PAST` 水1食1、天+1 | `PAY` 瓶蓋 10 | **質變**：用時間付錢 |
| `SCOUT_PATH` 零成本 | `CLEAR` 廢料1 ／ `DETOUR` 天+1 | **質變**：別人要付的它不用付 |
| `QUICK_PICK` 天+0 | `SEARCH` 天+1 | **質變**：買的是那一天 |
| `FORCE_THROUGH` 固定掉 1 件 | `CLEAR` 需要廢料 | **質變**：身上沒廢料時仍然有路 |
| `TAKE_PACK` 零成本拿 scrap 2 | `GIVE_WATER` 水1 換 scrap 1 | 質變（道德），但**沒有代價** |
| `HAGGLE` 瓶蓋 4 | `PAY` 瓶蓋 10 | **只是比較便宜** |
| `HYDRATE` 水1→scrap 2 | `GIVE_WATER` 水1→scrap 1 | **同樣代價、比較好的產出**＝最接近 `+loot` |
| `STRIP_PARTS` 天+1→scrap3+fuel1 | `SEARCH` 天+1→scrap4 | 同樣代價、不同產出分布；**偏效率差** |

`HYDRATE` 與 `STRIP_PARTS` 是目前最弱的兩個——它們沒有改變「你能怎麼做」，只改變
「你拿到多少」。這正是 Owner 指出的失敗模式，先記著，實玩時特別看這兩個。

### Trait debt：`GREEDY` 現在是純 bonus

`TAKE_PACK` 零代價拿到 scrap 2，等於 `HYDRATE` 的產出卻不用付那份水，也優於
`GIVE_WATER`。目前沒有任何 consequence 或 tradeoff——旅人不是 population 成員，所以
世界帳上不會發生任何事。**這是已記錄的 debt**：Trait 若只帶來好處，就會退化成 bonus，
而不是「你是哪種人」。需要世界有能力承載後果（S6 或 relationship/reputation authority）
才能真正修。

## 實玩要回答的三件事

1. 選不同 Background，真的有覺得「這角色會做不一樣的事」嗎？
2. 有沒有出現「靠，我這角色不會這個」的感覺？
3. 看到某個現在做不到的選項時，會不會想把那個能力練起來？

第 3 題開始出現 YES，才代表 Skill 已經從「存檔裡的一個數字」變成
「玩家想讓角色成長的原因」——那時才值得進 C3 Skill Growth。

## 之後要接的

- **技能舞台缺口表**：哪些能力世界根本沒有舞台、哪些現在就能掛，見
  [`docs/c2-skill-stage-gap.md`](c2-skill-stage-gap.md)。結論：SPEECH 是唯一一個
  不需要新 subsystem、現在就能掛的（ROADBLOCK），FIREARMS / MELEE / MEDICINE /
  ELECTRONICS 都必須等新的世界事實或新的子系統。**不為了讓表好看而填。**
- **FIREARMS 的回歸點**：C5 Equipment 有真正的 firearm item 之後，或是 encounter
  context 真的帶有可觀察的武器事實之後。守衛的單薄是這個缺口的直接後果。
- **C3 技能成長**：這些做法是「相關使用」最自然的證據來源。receipt 目前**沒有**記錄
  用了哪個條件；要做 C3 時得先決定要不要寫進 ledger payload（會動到存檔相容性）。
- MEDICINE / SPEECH 一旦有角色拿得到等級，旅人與關卡都已經有明顯的掛載點。
