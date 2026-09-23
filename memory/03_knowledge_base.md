# Knowledge Base

## Gotchas

- Record troubleshooting notes, anti-patterns, and fixes here.
- Survivor PDA 補給警示須逐項判定：`水 0、食物 1` 同時需要「水已耗盡」與「食物偏低」。以 `water > 0 and food > 0` 控制整句低補給提示，會在任一項歸零時隱藏另一項的風險。對應回歸見 `tests/test_quest3_multiple_commissions.gd`，實際畫面見 `artifacts/quest-ui-readability/zero_water_low_food_1152x648.png`。
