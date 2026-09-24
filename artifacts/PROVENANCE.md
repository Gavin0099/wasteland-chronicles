# artifacts/ PROVENANCE

這些是**再生成的證據檔**，不是手寫紀錄。沒有這張表的話，半年後沒有人知道某個
snapshot 是哪個年代的世界說的話——而過期的證據比沒有證據更危險：它會讓後來的 agent
把早就修好的問題當成現在的問題。

本表由重新生成時的實際狀態填寫，與 generator 程式無關（生成器一行都沒有改）。

## 這批證據生成於

| 項目 | 值 |
| --- | --- |
| Source commit（生成當下的 HEAD） | `477fe09ffbd4fd4a1318a3bb283c4ed7454f4535` |
| Branch | `codex/encounter-result-feedback` |
| Engine | Godot 4.7.2.stable.official.ed1daf0bf |
| World snapshot schema | `progression_schema_version: 1` |
| 生成方式 | 逐檔 `godot --headless --path . --script <generator>`；generator 即下表，全部是既有測試套件 |
| 生成日期 | 2026-09-21 |

## 決定性

同一個 HEAD 連跑兩次，九個檔案的 SHA-256 **逐字節相同**——沒有 timestamp、沒有隨機
來源、沒有需要排除的 provenance 欄位。如果之後某次重生成出現差異，那是**行為變了**，
不是雜訊。

## 檔案、生成者與雜湊

| Artifact | Generator | SHA-256 |
| --- | --- | --- |
| `s4c2_n0_evidence.txt` | `tests/n0_numeric_evidence.gd` | `79692a2cd0c2c01481f60bdda5bcbd4a0ff22087f1d9c3bfaff9123f009785ef` |
| `world_snapshot.json` | `tests/test_s4_identity.gd` | `80812875297910002a1d64ceb8cef90a1d8a7a29e6774510fb29354701d8fd34` |
| `world_snapshot_s4b.json` | `tests/test_s4_life_state.gd` | `775f0a1f35dea416a4061203da038b1f2334d276f4f80a79490703b7d383ccdf` |
| `world_snapshot_s4c.json` | `tests/test_s4_profile.gd` | `8902f219b99591d21439325d2b9a5bb5d88424c2109ebb6c20825f55e4303811` |
| `world_snapshot_s4c1.json` | `tests/test_s4_c1_event_ledger.gd` | `1c1c896bf6c731289963727b0ed2b080d87c08ee65bf6fe831d4905c46bc99f0` |
| `world_snapshot_s4c2.json` | `tests/test_s4_c2_numeric.gd` | `d5cadc956305d5c88ff8e4b100f63ea551875083c7c45685a3d2a48724221c93` |
| `world_snapshot_s4d.json` | `tests/test_s4_traits.gd` | `58f724f0f3a15538979356c3003267c26092fe608a1a9fb8b9aca9113cb66a7e` |
| `world_snapshot_s4e.json` | `tests/test_s4_aptitude.gd` | `681ff3e758634a79f6638c071a44a3f6c2a306c98c33f25ae1721b96347a59c5` |
| `world_snapshot_s4f1.json` | `tests/test_s4_f1_decisions.gd` | `24b6f3cece190a8daa6244fbf0e6a962d595dafdd76518e8d8bdb2cfd14fd4b4` |

## 這次 refresh 修正了什麼陳述

舊的 committed 版本停在 S4-C.2 修好之前，檔案裡寫著：

```
Snapshot fixed point at Day 50: NO
Continuation Day 50 -> 100: FIRST DIVERGENCE at Day 51
scrap  live=31 (int) | json=31.0 (float) | loaded=31.0 (float)   <-- TYPE CHANGED
```

現行系統早就不是這樣了（fixed point YES、無分歧、型別在往返後保持 int），舊檔也缺
`progression_schema_version` 與 `pending_encounter_result` 這兩個後來加入的欄位。

這是**純維護**：零 production code、零 test code 改動，不構成任何 gate 的證據，也不
為任何 slice 宣稱通過。S5-C2 的狀態不因這個 commit 改變。
