# 3D 麻辣烫项目

## Project

3D 麻辣烫多人合作餐厅动作游戏。

## Engine

Godot 4.7.2（Forward+ Renderer）

## Language

GDScript

## Current Development Stage

Phase 1 / 3D Player Foundation

## Important Rules

1. 本项目不属于桌面挂机项目。
2. 玩家可见文字禁止在 GDScript 或 Gameplay Scene 中硬编码，必须通过 Localization Key 获取。
3. Gameplay 数据使用稳定 ID，例如 `wide_noodle`、`spicy`、`table_01`。
4. 游戏最终目标为支持 1–4 名玩家。
5. 最终计划支持本地多人和在线多人。
6. 当前仅实现 Player 移动、固定 Camera 与灰盒测试关卡，不包含厨房 Gameplay。
7. 每个开发 Phase 完成人工验收后再继续。

## Run

使用 Godot 4.7.2 打开项目根目录并运行项目，将直接进入 3D Player Movement Test。

Localization Demo 已移动到独立测试场景，并继续由自动 smoke test 验证。
