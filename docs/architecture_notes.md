# Architecture Notes

本文件只记录已经确定、会影响后续架构的约束。Phase 0 不实现 Gameplay 或 Multiplayer。

## Gameplay

- 3D 固定斜俯视视角。
- 支持 1–4 Players。
- 玩家之间存在碰撞。
- 玩家一次默认只持有一个物品。
- 持物时仍允许部分 Station Interaction。

## Multiplayer

未来目标：

- Local Multiplayer。
- Online Multiplayer。
- Steam。
- Host Authoritative。
- Gameplay 不直接依赖 Steam API。
- One Peer 不等于 One Player。

本阶段不实现 Multiplayer、Lobby、Steam 集成或相关依赖。

## Localization

- No hardcoded player-facing text。
- Gameplay 数据使用 Stable IDs。
- 使用 JSON localization resources。
- 支持 Runtime language switching。
- UI 统一通过 `LocalizationManager` 获取显示文本。

