# Architecture Notes

本文件只记录已经确定、会影响后续架构的约束。

## Gameplay

- 3D 固定斜俯视视角。
- 支持 1–4 Players。
- 玩家之间存在碰撞。
- 玩家一次默认只持有一个物品。
- 持物时仍允许部分 Station Interaction。
- PlayerController 只接收世界空间 movement intent，不直接读取 Input。
- 本地输入、未来网络输入与 AI 控制均通过可替换的输入层驱动 PlayerController。
- Player 根坐标代表脚底接地点，身体碰撞与视觉相对根节点向上偏移。
- Fixed Camera 的 target、yaw、pitch、distance、orthographic size 是 Camera transform 的唯一配置源。

## Multiplayer

未来目标：

- Local Multiplayer。
- Online Multiplayer。
- Steam。
- Host Authoritative。
- Gameplay 不直接依赖 Steam API。
- One Peer 不等于 One Player。
- player_id、local_slot、input_device_id 与 network_peer_id 保持独立。

本阶段不实现 Multiplayer、Lobby、Steam 集成或相关依赖。

## Localization

- No hardcoded player-facing text。
- Gameplay 数据使用 Stable IDs。
- 使用 JSON localization resources。
- 支持 Runtime language switching。
- UI 统一通过 `LocalizationManager` 获取显示文本。
