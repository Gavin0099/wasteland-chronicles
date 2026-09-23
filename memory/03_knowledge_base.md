# Knowledge Base

## Gotchas

- Record troubleshooting notes, anti-patterns, and fixes here.
- Survivor PDA 補給警示須逐項判定：`水 0、食物 1` 同時需要「水已耗盡」與「食物偏低」。以 `water > 0 and food > 0` 控制整句低補給提示，會在任一項歸零時隱藏另一項的風險。對應回歸見 `tests/test_quest3_multiple_commissions.gd`，實際畫面見 `artifacts/quest-ui-readability/zero_water_low_food_1152x648.png`。
- 聚落市場是 `market_panel` 的子節點；遠端情報只隱藏子節點，外層 `PanelContainer` 仍會留下一大片空框。切換遠端／遭遇時，應讓外層容器隨市場內容一同隱藏。灰谷插畫也只屬於灰谷，不應調暗後重用為其他城鎮的畫面。回歸畫面見 `artifacts/local-actions-ui/`。
