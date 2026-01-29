import { NextRequest, NextResponse } from 'next/server';
import { createServerSupabaseClient } from '@/infrastructure/supabase/client';
import { GeminiClient } from '@/infrastructure/api/gemini-client';
import { ProfileRepository } from '@/infrastructure/repositories';

export async function POST(request: NextRequest) {
  try {
    // 檢查認證
    const supabase = await createServerSupabaseClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json(
        { error: { code: 'UNAUTHORIZED', message: '請先登入' } },
        { status: 401 }
      );
    }

    // 檢查 AI 使用配額
    const profileRepo = new ProfileRepository(supabase);
    const canUseAI = await profileRepo.canUseAI();

    if (!canUseAI) {
      return NextResponse.json(
        {
          error: {
            code: 'QUOTA_EXCEEDED',
            message: '您已達到本月的 AI 分析次數限制（10次），請升級至 Pro 方案以獲得無限次數',
          },
        },
        { status: 403 }
      );
    }

    // 解析請求體
    const body = await request.json();
    const { content } = body;

    if (!content || typeof content !== 'string' || content.trim().length === 0) {
      return NextResponse.json(
        { error: { code: 'INVALID_INPUT', message: '請提供有效的文字內容' } },
        { status: 400 }
      );
    }

    // 檢查 Gemini API Key
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      console.error('GEMINI_API_KEY 未設定');
      return NextResponse.json(
        {
          error: {
            code: 'CONFIGURATION_ERROR',
            message: '伺服器設定錯誤，請聯繫管理員',
          },
        },
        { status: 500 }
      );
    }

    // 執行 AI 分析
    const geminiClient = new GeminiClient(apiKey);
    const analysisResult = await geminiClient.analyzeText(content);

    // 增加 AI 使用次數
    await profileRepo.incrementAIUsage();

    return NextResponse.json({ data: analysisResult });
  } catch (error: any) {
    console.error('AI 分析錯誤:', error);
    return NextResponse.json(
      {
        error: {
          code: 'ANALYSIS_ERROR',
          message: error.message || 'AI 分析失敗，請稍後再試',
        },
      },
      { status: 500 }
    );
  }
}
