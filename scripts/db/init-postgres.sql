-- 初始化 PostgreSQL 資料庫
-- 此腳本用於第一次設置資料庫結構

-- 創建擴展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "vector";

-- 創建自訂函數
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 用戶表
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(150) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    first_name VARCHAR(150),
    last_name VARCHAR(150),
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_staff BOOLEAN NOT NULL DEFAULT false,
    is_superuser BOOLEAN NOT NULL DEFAULT false,
    last_login TIMESTAMP WITH TIME ZONE,
    date_joined TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 用戶偏好設定表
CREATE TABLE IF NOT EXISTS user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    default_model VARCHAR(50) NOT NULL DEFAULT 'gemini',
    default_teacher_role_id UUID,
    tts_voice VARCHAR(100) NOT NULL DEFAULT 'zh-TW-Standard-A',
    ui_theme VARCHAR(20) NOT NULL DEFAULT 'light',
    language VARCHAR(10) NOT NULL DEFAULT 'zh-TW',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE (user_id)
);

-- 教師角色表
CREATE TABLE IF NOT EXISTS teacher_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    system_prompt TEXT NOT NULL,
    knowledge_base_id UUID,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    is_public BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 更新用戶偏好設定中的默認教師角色外鍵
ALTER TABLE user_preferences
ADD CONSTRAINT fk_user_preferences_teacher_role
FOREIGN KEY (default_teacher_role_id) REFERENCES teacher_roles(id)
ON DELETE SET NULL;

-- 知識庫表
CREATE TABLE IF NOT EXISTS knowledge_bases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    subject_area VARCHAR(100),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    is_public BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 更新教師角色中的知識庫外鍵
ALTER TABLE teacher_roles
ADD CONSTRAINT fk_teacher_roles_knowledge_base
FOREIGN KEY (knowledge_base_id) REFERENCES knowledge_bases(id)
ON DELETE SET NULL;

-- 知識項目表
CREATE TABLE IF NOT EXISTS knowledge_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    knowledge_base_id UUID NOT NULL REFERENCES knowledge_bases(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    vector_embedding vector(768),
    metadata JSONB,
    source VARCHAR(512),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 音訊檔案表
CREATE TABLE IF NOT EXISTS audio_files (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(512) NOT NULL,
    file_size INTEGER NOT NULL,
    duration INTEGER,
    format VARCHAR(50),
    status VARCHAR(50) NOT NULL DEFAULT 'uploaded',
    processing_error TEXT,
    metadata JSONB,
    uploaded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 逐字稿表
CREATE TABLE IF NOT EXISTS transcripts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    audio_file_id UUID NOT NULL REFERENCES audio_files(id) ON DELETE CASCADE,
    raw_text TEXT,
    corrected_text TEXT,
    srt_path VARCHAR(512),
    language_code VARCHAR(10),
    confidence FLOAT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 講者分段表
CREATE TABLE IF NOT EXISTS speaker_segments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transcript_id UUID NOT NULL REFERENCES transcripts(id) ON DELETE CASCADE,
    speaker_id VARCHAR(50) NOT NULL,
    speaker_name VARCHAR(100),
    start_time FLOAT NOT NULL,
    end_time FLOAT NOT NULL,
    text TEXT NOT NULL,
    confidence FLOAT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 摘要表
CREATE TABLE IF NOT EXISTS summaries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transcript_id UUID NOT NULL REFERENCES transcripts(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    model_used VARCHAR(255),
    is_approved BOOLEAN NOT NULL DEFAULT false,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 生成內容表
CREATE TABLE IF NOT EXISTS generated_contents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    summary_id UUID NOT NULL REFERENCES summaries(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    content_path VARCHAR(512) NOT NULL,
    model_used VARCHAR(255),
    teacher_role_id UUID REFERENCES teacher_roles(id) ON DELETE SET NULL,
    parameters JSONB,
    is_favorite BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 處理作業表
CREATE TABLE IF NOT EXISTS processing_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_type VARCHAR(50) NOT NULL,
    resource_id UUID NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    priority INTEGER NOT NULL DEFAULT 0,
    progress FLOAT NOT NULL DEFAULT 0,
    error_message TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- 處理事件表
CREATE TABLE IF NOT EXISTS processing_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES processing_jobs(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    payload JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- AI模型使用表
CREATE TABLE IF NOT EXISTS ai_model_usages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    model_name VARCHAR(255) NOT NULL,
    task_type VARCHAR(50) NOT NULL,
    tokens_input INTEGER,
    tokens_output INTEGER,
    response_time FLOAT,
    success BOOLEAN NOT NULL DEFAULT true,
    error_message TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 知識庫版本表
CREATE TABLE IF NOT EXISTS knowledge_base_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    knowledge_base_id UUID NOT NULL REFERENCES knowledge_bases(id) ON DELETE CASCADE,
    version INTEGER NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id) ON DELETE SET NULL
);

-- 添加觸發器更新更新時間戳記
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_teacher_roles_updated_at BEFORE UPDATE ON teacher_roles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_knowledge_bases_updated_at BEFORE UPDATE ON knowledge_bases
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_knowledge_items_updated_at BEFORE UPDATE ON knowledge_items
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_audio_files_updated_at BEFORE UPDATE ON audio_files
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transcripts_updated_at BEFORE UPDATE ON transcripts
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_speaker_segments_updated_at BEFORE UPDATE ON speaker_segments
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_summaries_updated_at BEFORE UPDATE ON summaries
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_generated_contents_updated_at BEFORE UPDATE ON generated_contents
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_processing_jobs_updated_at BEFORE UPDATE ON processing_jobs
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 創建索引
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_teacher_roles_user_id ON teacher_roles(user_id);
CREATE INDEX idx_teacher_roles_is_public ON teacher_roles(is_public);
CREATE INDEX idx_knowledge_bases_user_id ON knowledge_bases(user_id);
CREATE INDEX idx_knowledge_bases_is_public ON knowledge_bases(is_public);
CREATE INDEX idx_knowledge_items_knowledge_base_id ON knowledge_items(knowledge_base_id);
CREATE INDEX idx_audio_files_user_id ON audio_files(user_id);
CREATE INDEX idx_audio_files_status ON audio_files(status);
CREATE INDEX idx_transcripts_audio_file_id ON transcripts(audio_file_id);
CREATE INDEX idx_speaker_segments_transcript_id ON speaker_segments(transcript_id);
CREATE INDEX idx_summaries_transcript_id ON summaries(transcript_id);
CREATE INDEX idx_generated_contents_summary_id ON generated_contents(summary_id);
CREATE INDEX idx_generated_contents_user_id ON generated_contents(user_id);
CREATE INDEX idx_generated_contents_content_type ON generated_contents(content_type);
CREATE INDEX idx_processing_jobs_user_id ON processing_jobs(user_id);
CREATE INDEX idx_processing_jobs_status ON processing_jobs(status);
CREATE INDEX idx_processing_jobs_resource_id ON processing_jobs(resource_id);
CREATE INDEX idx_processing_events_job_id ON processing_events(job_id);
CREATE INDEX idx_ai_model_usages_user_id ON ai_model_usages(user_id);
CREATE INDEX idx_ai_model_usages_model_name ON ai_model_usages(model_name);
CREATE INDEX idx_knowledge_base_versions_knowledge_base_id ON knowledge_base_versions(knowledge_base_id);

-- 創建向量索引
CREATE INDEX idx_knowledge_items_vector_embedding ON knowledge_items USING ivfflat (vector_embedding vector_l2_ops)
WITH (lists = 100);

-- 添加註釋
COMMENT ON TABLE users IS '系統用戶資料表';
COMMENT ON TABLE user_preferences IS '用戶偏好設定資料表';
COMMENT ON TABLE teacher_roles IS '教師角色資料表，定義不同教學風格';
COMMENT ON TABLE knowledge_bases IS '知識庫資料表，存儲不同學科或領域的知識集合';
COMMENT ON TABLE knowledge_items IS '知識項目資料表，存儲知識庫中的具體內容項目';
COMMENT ON TABLE audio_files IS '音訊檔案資料表，存儲上傳的課堂錄音檔案信息';
COMMENT ON TABLE transcripts IS '逐字稿資料表，存儲由音訊生成的文字轉錄';
COMMENT ON TABLE speaker_segments IS '講者分段資料表，存儲逐字稿中不同講者的發言段落';
COMMENT ON TABLE summaries IS '摘要資料表，存儲由AI生成的課程摘要';
COMMENT ON TABLE generated_contents IS '生成內容資料表，存儲自動生成的教學資源';
COMMENT ON TABLE processing_jobs IS '處理作業資料表，追蹤各類處理任務的狀態';
COMMENT ON TABLE processing_events IS '處理事件資料表，記錄處理過程中的各類事件';
COMMENT ON TABLE ai_model_usages IS 'AI模型使用資料表，記錄模型使用情況和統計';
COMMENT ON TABLE knowledge_base_versions IS '知識庫版本資料表，記錄知識庫的不同版本';