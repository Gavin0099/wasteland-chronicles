# C1-P0 — Strict Rank Codec Decision

決策：CLOSED；實作與證據為 `simulation/rank_json_codec.gd`、`tests/test_c1_p0_rank_codec.gd`。不修改 `NumericCanon` 的世界浮點規則。

採用 native JSON 解碼加上一個保留 token 拼法的結構掃描。Native parser 處理一般值；scanner 逐層讀 object／array／string／scalar，在確定的 `player.capability.skill_ranks.<skill_id>` 路徑才驗證 rank token。不是全文 regex，也不是事後猜 Dictionary 的 2.0 來源。

| 原始 rank token | 結果 |
| --- | --- |
| `0`～`5` | 接受，明確還原為 TYPE_INT |
| `2.0`、`2e0`、`2E+0` | 拒絕，不當成 int |
| `−1`、`6`、`-0` | 拒絕；wire form 只接受單一 0～5 字元 |
| 字串、bool、null、object、array、NaN、Infinity | 拒絕，無 partial data |

JSON 中的 escaped key 先解碼再辨識／檢查重複。所有重複 object key（包含同名的 escaped 拼法）拒絕。字串裡提到 `skill_ranks` 不會被當作 rank 資料。遞迴深度超過 128 拒絕，object／array 尾逗號拒絕。

只恢復已驗證的 rank token，其他世界數值維持 native JSON 結果，包括 `2.0`、`2e0` 與既有 NumericCanon probe corpus。十技能完整性、未知 ID、profile schema 與 provenance 由 C1 domain validator 負責；codec 不以欄位缺少來自行推斷 migration。

正式存檔入口為 `WorldState.from_json_checked(raw)`。`from_dict_checked` 仍接受有真正 int ranks 的領域 Dictionary，但拒絕對新版存檔先呼叫 generic `JSON.parse_string` 後得到的浮點 ranks；這是必要的 API 邊界，不做靜默修復。既有存讀檔測試改用 raw 入口，原有比較斷言保留。

驗證包括 0／5 邊界、浮點／指數反例、escaped keys、重複 keys、字串偽裝、native world floats 不變與 canonical SHA-256 重播。執行結果存於 `artifacts/c0-c1-headless/test_c1_p0_rank_codec.log`。
