-- 初始化默認資料
-- 這個腳本用於添加初始的默認數據

-- 插入預設的管理員用戶
INSERT INTO users (
    username, 
    email, 
    password, 
    first_name, 
    last_name, 
    is_active, 
    is_staff, 
    is_superuser
) VALUES (
    'admin',
    'admin@example.com',
    crypt('admin_password', gen_salt('bf')),
    '管理員',
    '使用者',
    true,
    true,
    true
) ON CONFLICT (username) DO NOTHING;

-- 獲取剛插入的管理員 ID
DO $$
DECLARE
    admin_id UUID;
BEGIN
    SELECT id INTO admin_id FROM users WHERE username = 'admin';

    -- 插入預設的用戶偏好設定
    INSERT INTO user_preferences (
        user_id,
        default_model,
        tts_voice,
        ui_theme,
        language
    ) VALUES (
        admin_id,
        'gemini',
        'zh-TW-Standard-A',
        'light',
        'zh-TW'
    ) ON CONFLICT (user_id) DO NOTHING;

    -- 插入預設的知識庫
    INSERT INTO knowledge_bases (
        name,
        description,
        subject_area,
        user_id,
        is_public
    ) VALUES (
        '通用教學知識庫',
        '包含一般教學方法、課程設計和學習理論的通用知識',
        '教育學',
        admin_id,
        true
    ) ON CONFLICT DO NOTHING;

    -- 獲取剛插入的知識庫 ID
    DECLARE
        kb_id UUID;
    BEGIN
        SELECT id INTO kb_id FROM knowledge_bases WHERE name = '通用教學知識庫';

        -- 插入預設的教師角色
        INSERT INTO teacher_roles (
            name,
            description,
            system_prompt,
            knowledge_base_id,
            user_id,
            is_public
        ) VALUES (
            '標準教師',
            '傳統教學風格，注重知識傳授和核心概念的講解',
            '你是一位具有豐富經驗的教師，專注於清晰、準確地傳授知識。你的目標是幫助學生理解核心概念，建立堅實的知識基礎。在生成教學資料時，優先考慮內容的準確性、結構性和完整性。使用專業但易懂的語言，避免過度簡化或過於技術性的解釋。提供實用的例子來說明抽象概念，並強調關鍵點的理解。',
            kb_id,
            admin_id,
            true
        ) ON CONFLICT DO NOTHING;
    END;
END $$;