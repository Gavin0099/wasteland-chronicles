# Wasteland Chronicles — Agent Skills 規範與目錄指南

本目錄收錄《Wasteland Chronicles》專案所使用的本地內規技能（Local Skills）與外部參考技能（External Skills）。所有參與本專案開發之 Agent 在進行程式碼、UI、戰鬥或架構變更時，必須嚴格遵守本規範。

---

## 1. 目錄架構

```text
.agents/
  skills/
    README.md                              # 本規範文件
    wasteland-chronicles-ui-v1/            # UI 專案相容指引
    wc-survivor-pda-design-system/         # 廢土倖存者 PDA 視覺與 Token 規範（最高優先）
    godot/                                 # Godot 4.x 開發、語法檢查、測試與自動化工具箱
      SKILL.md
      references/
      scripts/
      templates/
    external/                              # 外部匯入技能（實作參考，不可越權）
      gd-agentic-skills/
        godot-adapt-3d-to-2d/              # 3D 降維策略、2.5D fake-depth 與等角投影模式
        godot-2d-animation/                # 2D 逐幀 / 剪紙 / 補間動畫與視覺反饋
      godot-game-development-expert/       # Godot 4 架構準則、型別規範與組合式模式
        SKILL.md
```

---

## 2. 四大核心準則（Core Principles）

### 準則一：本專案優先遵守本地 Skill
進行任何修改時，專案內部既有技能具備最高優先權：
1. `wc-survivor-pda-design-system`：全域 UI/HUD 單一真理來源（橄欖綠/琥珀色/冷灰調 PDA Token、容器化排版）。
2. `wasteland-chronicles-ui-v1`：向後相容指標。
3. `godot/SKILL.md`：Godot 4.x 語法、無頭驗證、排版檢查與腳本規範。

### 準則二：外部 Skill 只作為實作參考
- `external/` 內的所有技能僅作為演算法、數學公式或實作手法的靈感與參考。
- **嚴禁**外部 skill 覆蓋本專案既有的 UI Design Tokens、暗黑末日美學、Axiom 治理規範或決定論原則。

### 準則三：戰鬥畫面採 2.5D Fake-Depth
- 戰鬥畫面採用「Fake-depth 2.5D 手繪/立繪」形式（類似《俠客遊・前途道標》之俯視等角風格）。
- **嚴禁引入 3D SubViewport、3D Camera 或 3D 網格/骨骼模型**，保持純 2D 節點樹的輕量化與最高相容性。

### 準則四：測試與 Headless 回歸不可破壞
- 任何畫面或邏輯調整，均不得破壞既有的 `godot --headless --script tests/test_*.gd` 測試流程。
- 動畫表現（Tween）純屬呈現層，必須支援 `reduced_motion`，所有模擬狀態變更必須在數據層完成且具備 100% 決定論重播保證。

---

## 3. 戰鬥畫面實作準則（2.5D Fake-Depth Combat）

依據本專案確立之戰鬥視覺規範（Option A），戰鬥場景必須符合以下標準：

1. **背景地表（Elevated Ground Plane）**：
   - 採約 30°~35° 俯視等角透視，表現延伸至地平線的廢棄公路、碎石或棚屋地表，呈現空間縱深感。
2. **角色對峙站位（Isometric Stance）**：
   - 玩家角色（Drifter）位於左下近景，背向鏡頭朝右上 45° 側身。
   - 敵方角色（Bandit / Dog / Raider）位於右上中景，正面朝向左下 45°，形成明確對峙軸線。
3. **橢圓接地陰影（Ground Contact Shadow）**：
   - 所有角色腳底必須擁有帶有透視扁平比（如 `Vector2(1.0, 0.28)`）之多層橢圓接地陰影，確保立繪牢固貼合地面，不浮動。
4. **沿地表軸線之動作補間（Axis-Aligned Tweens）**：
   - 攻擊突進、受擊震退、後撤移動均嚴格沿著地面對角線軸進行補間。
   - 受擊時配合微幅閃爍（modulate）與位移，提供紮實打擊感。
5. **資訊可讀性（Readability）**：
   - 傷害浮字（Floating Combat Text）、Telegraph 敵方行動預告、血條與裝備圖標必須清晰可讀，層級高於背景立繪。
