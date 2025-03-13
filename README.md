# 教學語音處理與摘要管理平台

這是一個為教師設計的教學輔助系統，旨在通過 AI 技術處理課堂錄音，自動生成文字稿、摘要、教學材料等內容。系統支援通過 API（如 Gemini）或本地模型（如 OLLAMA）進行 AI 處理，提供高品質的 TTS（文字轉語音）、STT（語音轉文字）、多講者辨識、SRT 生成以及 RAG（檢索增強生成）知識搜尋功能。

## 系統架構

本系統採用事件驅動的微服務架構，包含以下主要組件：

- **前端應用**：React 實現的 PWA 應用，支援離線功能
- **API 閘道**：處理路由、認證和請求轉發
- **Django 核心服務**：處理業務邏輯和資料管理
- **音訊處理服務**：處理 STT、講者辨識和 SRT 生成
- **AI 處理服務**：處理摘要生成、轉錄修正和 RAG 知識搜尋
- **內容生成服務**：產生 PPT、習題和教材
- **認證服務**：處理用戶管理和身份認證

## 快速入門

### 環境要求

- Docker 與 Docker Compose
- Git
- 操作系統：Linux、macOS 或 Windows 搭配 WSL2

### 開發環境設置

1. 克隆專案
   ```bash
   git clone https://github.com/yourusername/edu-voice-platform.git
   cd edu-voice-platform

設置開發環境
bashCopychmod +x scripts/setup-dev.sh
./scripts/setup-dev.sh

啟動開發環境
bashCopy./scripts/start-dev.sh

訪問服務

前端：http://localhost:3000
API 閘道：http://localhost:8000
Django 管理介面：http://localhost:8002/admin



使用指南
查看 docs/user-guide 目錄下的使用指南：

管理員指南
教師使用指南

開發指南
查看 docs/development 目錄下的開發指南：

開發環境設定
程式碼標準
測試指南

架構設計
查看 docs/architecture 目錄下的架構設計文檔：

系統架構概述
資料模型設計
API 設計文檔
部署指南

功能特色

高品質語音轉文字與講者辨識
自動生成課程摘要與筆記
多種教學資源自動生成（PPT、習題、講義）
教師角色定制，適應不同教學風格
RAG 知識搜尋，提供相關資料補充
事件驅動架構，高度可擴展性
支持雲端 API 和本地模型的靈活選擇

貢獻指南

Fork 專案
創建特性分支 (git checkout -b feature/amazing-feature)
提交更改 (git commit -m 'Add some amazing feature')
推送到分支 (git push origin feature/amazing-feature)
開啟 Pull Request

授權
本專案採用 MIT 授權，詳見 LICENSE 檔案。